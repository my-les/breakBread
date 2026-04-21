import Vision
import CoreGraphics

struct OCRResult {
    var lineItems: [LineItem]
    var subtotal: Double
    var tax: Double
    var total: Double
    var vendorName: String?
    var rawLines: [String]
}

actor OCRService {
    static let shared = OCRService()

    func processReceipt(cgImage: CGImage) async throws -> OCRResult {
        // Try AI vision first (GPT-4o -> Claude fallback)
        if await AIReceiptService.shared.isConfigured {
            do {
                let result = try await AIReceiptService.shared.processReceipt(cgImage: cgImage)
                if !result.lineItems.isEmpty {
                    return result
                }
            } catch {
                // Fall through to Apple Vision
            }
        }

        // Offline fallback: Apple Vision + regex parser

        let recognizedText = try await recognizeText(in: cgImage)

        if recognizedText.isEmpty {
            throw OCRError.recognitionFailed
        }

        return parseReceipt(from: recognizedText)
    }

    private func recognizeText(in image: CGImage) async throws -> [String] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                continuation.resume(returning: lines)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Parsing

    private let subtotalKeywords = ["subtotal", "sub total", "sub-total", "sub ttl"]
    private let taxKeywords = ["tax"]
    private let totalKeywords = ["total", "amount due", "balance due", "payment"]
    private let skipKeywords = ["change due", "cash", "credit", "debit", "visa", "mastercard", "amex",
                       "card", "thank", "receipt", "order #", "tbl", "server",
                       "gst", "check closed", "chk", "xxxx",
                       "void", "discount", "promo", "closed"]
    private let headerKeywords = ["blvd", "ave", "street", "st.", "www.", "http",
                         ".com", "phone", "tel", "fax"]
    private let summaryKeywords = ["food", "beer", "beverage", "alcohol", "fee", "gratuity",
                          "16%", "18%", "20%", "tip"]
    private let datePattern = /\d{1,2}\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)/

    private func parseReceipt(from lines: [String]) -> OCRResult {
        var items: [LineItem] = []
        var subtotal: Double = 0
        var tax: Double = 0
        var total: Double = 0
        var vendorName: String?

        if let first = lines.first, !first.isEmpty, !first.contains(where: { $0.isNumber }) {
            vendorName = first
        }

        let merged = mergeLines(lines)

        for line in merged {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let lower = trimmed.lowercased()

            if lower.count < 3 { continue }
            if shouldSkip(lower) { continue }

            guard let price = extractPrice(from: trimmed) else { continue }

            if subtotalKeywords.contains(where: { lower.hasPrefix($0) }) {
                subtotal = price
            } else if lower.hasPrefix("tax") {
                tax = price
            } else if totalKeywords.contains(where: { lower.hasPrefix($0) }) {
                total = max(total, price)
            } else if summaryKeywords.contains(where: { lower.hasPrefix($0) }) {
                // summary line like "Food $36.75" -- skip
            } else if price > 0 && price < 200 {
                let name = cleanItemName(from: trimmed)
                if name.count >= 2 && !looksLikeMetadata(name) {
                    items.append(LineItem(name: name, price: price))
                }
            }
        }

        if subtotal == 0 {
            subtotal = items.reduce(0) { $0 + $1.price }
        }

        return OCRResult(
            lineItems: items,
            subtotal: subtotal,
            tax: tax,
            total: total,
            vendorName: vendorName,
            rawLines: lines
        )
    }

    private func mergeLines(_ lines: [String]) -> [String] {
        var merged: [String] = []
        var pendingTextLine: String?

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if isPriceOnly(trimmed) {
                if let pending = pendingTextLine {
                    merged.append("\(pending) \(trimmed)")
                    pendingTextLine = nil
                } else {
                    merged.append(trimmed)
                }
            } else if hasPrice(trimmed) {
                if let pending = pendingTextLine {
                    merged.append(pending)
                }
                pendingTextLine = nil
                merged.append(trimmed)
            } else if looksLikeItemName(trimmed) {
                if let pending = pendingTextLine {
                    merged.append(pending)
                }
                pendingTextLine = trimmed
            } else {
                if let pending = pendingTextLine {
                    merged.append(pending)
                    pendingTextLine = nil
                }
                merged.append(trimmed)
            }
        }

        if let pending = pendingTextLine {
            merged.append(pending)
        }

        return merged
    }

    private func isPriceOnly(_ line: String) -> Bool {
        let cleaned = line.replacingOccurrences(of: "$", with: "").trimmingCharacters(in: .whitespaces)
        return Double(cleaned) != nil && cleaned.contains(".")
    }

    private func hasPrice(_ line: String) -> Bool {
        extractPrice(from: line) != nil
    }

    private func looksLikeItemName(_ line: String) -> Bool {
        let lower = line.lowercased()
        let hasLetters = lower.contains(where: { $0.isLetter })
        let startsWithQty = line.first?.isNumber == true
        return hasLetters && (startsWithQty || lower.first?.isLetter == true)
    }

    private func shouldSkip(_ lower: String) -> Bool {
        if skipKeywords.contains(where: { lower.contains($0) }) { return true }
        if headerKeywords.contains(where: { lower.contains($0) }) { return true }
        if lower.firstMatch(of: datePattern) != nil { return true }
        if lower == "restaurant" { return true }
        return false
    }

    // MARK: - Price Extraction

    private func extractPrice(from line: String) -> Double? {
        if let match = line.firstMatch(of: /\$\s*(\d{1,4}\.\d{2})/) {
            if let value = Double(String(match.1)), value > 0 { return value }
        }

        if let match = line.firstMatch(of: /(\d{1,4}\.\d{2})\s*$/) {
            if let value = Double(String(match.1)), value > 0 { return value }
        }

        let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if let last = components.last?.replacingOccurrences(of: "$", with: ""),
           let value = Double(last), value > 0, last.contains(".") {
            return value
        }

        return nil
    }

    // MARK: - Name Cleaning

    private func cleanItemName(from line: String) -> String {
        var name = line

        if let range = name.range(of: #"\$?\s*\d{1,4}\.\d{2}\s*$"#, options: .regularExpression) {
            name = String(name[name.startIndex..<range.lowerBound])
        }

        if let range = name.range(of: #"^\d+\s+"#, options: .regularExpression) {
            name = String(name[range.upperBound...])
        }

        name = name
            .trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: ".-_*#|"))
            .trimmingCharacters(in: .whitespaces)

        return name
    }

    private func looksLikeMetadata(_ name: String) -> Bool {
        let lower = name.lowercased()
        if lower.allSatisfy({ $0.isNumber || $0 == "/" || $0 == "-" || $0 == ":" || $0 == " " }) {
            return true
        }
        if lower.contains("xxxx") { return true }
        if name.count <= 2 { return true }
        return false
    }
}

enum OCRError: LocalizedError {
    case invalidImage
    case recognitionFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Could not process the image."
        case .recognitionFailed: return "No text found on the receipt. Try a clearer photo."
        }
    }
}
