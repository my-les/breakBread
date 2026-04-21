import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

actor AIReceiptService {
    static let shared = AIReceiptService()

    private let openAIKey: String
    private let anthropicKey: String

    init() {
        let env = ProcessInfo.processInfo.environment
        let plist = { (key: String) -> String? in
            Bundle.main.object(forInfoDictionaryKey: key) as? String
        }

        openAIKey = env["OPENAI_API_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? plist("OPENAI_API_KEY")
            ?? ""

        anthropicKey = env["ANTHROPIC_API_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? plist("ANTHROPIC_API_KEY")
            ?? ""
    }

    var isConfigured: Bool {
        !openAIKey.isEmpty || !anthropicKey.isEmpty
    }

    private let receiptPrompt = """
    Extract all line items from this receipt photo. Return ONLY valid JSON, no markdown, no explanation.
    Use this exact format:
    {"items":[{"name":"Item Name","price":12.50,"qty":1}],"subtotal":0,"tax":0,"total":0,"vendor":"Restaurant Name"}
    Rules:
    - Include every food/drink item with its price
    - qty should reflect the quantity shown (default 1)
    - subtotal is the pre-tax total
    - tax is the tax amount
    - total is the final amount
    - vendor is the restaurant name
    - Prices must be numbers, not strings
    - If you can't determine a value, use 0
    """

    // MARK: - Public API

    func processReceipt(cgImage: CGImage) async throws -> OCRResult {
        guard let jpegData = Self.jpegData(from: cgImage, maxDimension: 1024, quality: 0.8) else {
            throw AIReceiptError.imageProcessingFailed
        }

        let base64 = jpegData.base64EncodedString()

        if !openAIKey.isEmpty {
            do {
                return try await callOpenAI(base64: base64)
            } catch {
                if !anthropicKey.isEmpty {
                    return try await callAnthropic(base64: base64)
                }
                throw error
            }
        }

        if !anthropicKey.isEmpty {
            return try await callAnthropic(base64: base64)
        }

        throw AIReceiptError.noAPIKeyConfigured
    }

    // MARK: - OpenAI GPT-4o Vision

    private func callOpenAI(base64: String) async throws -> OCRResult {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!

        let body: [String: Any] = [
            "model": "gpt-4o",
            "max_tokens": 1000,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": receiptPrompt],
                        ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64)", "detail": "low"]]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw AIReceiptError.apiRequestFailed("OpenAI returned status \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIReceiptError.invalidResponse
        }

        return try parseAIResponse(content)
    }

    // MARK: - Anthropic Claude Vision

    private func callAnthropic(base64: String) async throws -> OCRResult {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1000,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64
                            ]
                        ],
                        ["type": "text", "text": receiptPrompt]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(anthropicKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw AIReceiptError.apiRequestFailed("Claude returned status \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArray = json["content"] as? [[String: Any]],
              let textBlock = contentArray.first(where: { $0["type"] as? String == "text" }),
              let content = textBlock["text"] as? String else {
            throw AIReceiptError.invalidResponse
        }

        return try parseAIResponse(content)
    }

    // MARK: - Parse AI JSON Response

    private func parseAIResponse(_ content: String) throws -> OCRResult {
        var jsonString = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if let start = jsonString.firstIndex(of: "{"),
           let end = jsonString.lastIndex(of: "}") {
            jsonString = String(jsonString[start...end])
        }

        guard let jsonData = jsonString.data(using: .utf8),
              let parsed = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw AIReceiptError.invalidResponse
        }

        var lineItems: [LineItem] = []

        if let items = parsed["items"] as? [[String: Any]] {
            for item in items {
                let name = item["name"] as? String ?? ""
                let price = (item["price"] as? Double) ?? (item["price"] as? Int).map(Double.init) ?? 0
                let qty = (item["qty"] as? Int) ?? 1

                if !name.isEmpty && price > 0 {
                    for _ in 0..<max(qty, 1) {
                        lineItems.append(LineItem(name: name, price: price))
                    }
                }
            }
        }

        let subtotal = (parsed["subtotal"] as? Double) ?? (parsed["subtotal"] as? Int).map(Double.init) ?? 0
        let tax = (parsed["tax"] as? Double) ?? (parsed["tax"] as? Int).map(Double.init) ?? 0
        let total = (parsed["total"] as? Double) ?? (parsed["total"] as? Int).map(Double.init) ?? 0
        let vendor = parsed["vendor"] as? String

        let computedSubtotal = subtotal > 0 ? subtotal : lineItems.reduce(0) { $0 + $1.price }

        return OCRResult(
            lineItems: lineItems,
            subtotal: computedSubtotal,
            tax: tax,
            total: total,
            vendorName: vendor,
            rawLines: [content]
        )
    }

    // MARK: - JPEG (Core Graphics — no UIKit; works on macOS + iOS)

    private static func jpegData(from cgImage: CGImage, maxDimension: CGFloat, quality: CGFloat) -> Data? {
        let w = CGFloat(cgImage.width)
        let h = CGFloat(cgImage.height)
        let ratio = min(maxDimension / w, maxDimension / h, 1.0)

        let imageToEncode: CGImage
        if ratio >= 1 {
            imageToEncode = cgImage
        } else {
            let newW = max(1, Int((w * ratio).rounded(.down)))
            let newH = max(1, Int((h * ratio).rounded(.down)))
            guard let scaled = scale(cgImage, width: newW, height: newH) else { return nil }
            imageToEncode = scaled
        }

        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }
        let props: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: quality]
        CGImageDestinationAddImage(dest, imageToEncode, props as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return data as Data
    }

    private static func scale(_ image: CGImage, width: Int, height: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        ctx.interpolationQuality = .high
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return ctx.makeImage()
    }
}

enum AIReceiptError: LocalizedError {
    case imageProcessingFailed
    case noAPIKeyConfigured
    case apiRequestFailed(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed: return "Could not process the receipt image."
        case .noAPIKeyConfigured: return "No AI API key configured. Using basic scanner."
        case .apiRequestFailed(let detail): return "AI scan failed: \(detail)"
        case .invalidResponse: return "Could not read the AI response."
        }
    }
}
