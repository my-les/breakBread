import SwiftUI
import PhotosUI
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

struct ReceiptCaptureView: View {
    @Environment(SplitFlowViewModel.self) private var vm
    @Environment(\.splitFlowNav) private var nav

    @State private var showingCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var cameraPermission: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var showingFileImporter = false

    var body: some View {
        VStack(spacing: 0) {
            flowHeader(title: "scan your receipt", step: "step 3 of 6") {
                nav.back()
            }
            .padding(.horizontal, BBSpacing.lg)

            Spacer()

            if let data = vm.receiptImageData, !data.isEmpty {
                receiptPreview(data)
            } else {
                uploadArea
            }

            Spacer()

            if vm.receiptImageData != nil {
                VStack(spacing: BBSpacing.sm) {
                    BBButton(title: "scan receipt", isLoading: isProcessing) {
                        Task { await processReceipt() }
                    }

                    Button("retake") {
                        vm.receiptImageData = nil
                    }
                    .font(BBFont.body)
                    .foregroundStyle(BBColor.secondaryText)
                }
                .padding(.horizontal, BBSpacing.lg)
                .padding(.bottom, BBSpacing.lg)
            } else {
                Button("skip — enter items manually") {
                    nav.advance(.review)
                }
                .font(BBFont.body)
                .foregroundStyle(BBColor.secondaryText)
                .padding(.bottom, BBSpacing.lg)
            }
        }
        .background(BBColor.background)
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showingCamera) {
            #if canImport(UIKit)
            CameraPicker(image: Binding(
                get: { vm.receiptImageData.flatMap { UIImage(data: $0) } },
                set: { vm.receiptImageData = $0?.jpegData(compressionQuality: 0.92) }
            ))
            #else
            EmptyView()
            #endif
        }
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.image, .pdf]) { result in
            handleFileImport(result)
        }
        .alert("error", isPresented: $showError) {
            Button("ok") {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Upload Area

    private var uploadArea: some View {
        VStack(spacing: BBSpacing.lg) {
            BBCard(padding: BBSpacing.xxl) {
                VStack(spacing: BBSpacing.lg) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(BBColor.secondaryText)

                    Text("upload receipt")
                        .font(BBFont.body)
                        .foregroundStyle(BBColor.secondaryText)

                    Text("take a photo, choose from library, or import a file")
                        .font(BBFont.caption)
                        .foregroundStyle(BBColor.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }

            HStack(spacing: BBSpacing.sm) {
                uploadOption(icon: "camera.fill", label: "camera") {
                    requestCameraAndOpen()
                }

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    VStack(spacing: BBSpacing.sm) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 22))
                        Text("photos")
                            .font(BBFont.caption)
                            .tracking(0.5)
                    }
                    .foregroundStyle(BBColor.primaryText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 76)
                    .background(BBColor.cardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: BBRadius.md))
                }

                uploadOption(icon: "doc.fill", label: "file") {
                    showingFileImporter = true
                }
            }
            .padding(.horizontal, BBSpacing.lg)
        }
        .padding(.horizontal, BBSpacing.lg)
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                guard let newItem else { return }
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        vm.receiptImageData = data
                    }
                }
            }
        }
    }

    private func uploadOption(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: BBSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(label)
                    .font(BBFont.caption)
                    .tracking(0.5)
            }
            .foregroundStyle(BBColor.primaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .background(BBColor.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: BBRadius.md))
        }
    }

    // MARK: - Receipt Preview

    private func receiptPreview(_ data: Data) -> some View {
        Group {
            #if canImport(UIKit)
            if let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
                    .clipShape(RoundedRectangle(cornerRadius: BBRadius.lg))
                    .padding(.horizontal, BBSpacing.lg)
                    .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
            }
            #endif
        }
    }

    // MARK: - Camera Permission

    private func requestCameraAndOpen() {
        switch cameraPermission {
        case .authorized:
            showingCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraPermission = AVCaptureDevice.authorizationStatus(for: .video)
                    if granted {
                        showingCamera = true
                    }
                }
            }
        case .denied, .restricted:
            errorMessage = "Camera access is denied. Go to Settings > breakbread to enable it."
            showError = true
        @unknown default:
            break
        }
    }

    // MARK: - File Import

    private func handleFileImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            if let data = try? Data(contentsOf: url),
               ReceiptImageData.cgImage(from: data) != nil {
                vm.receiptImageData = data
            } else {
                errorMessage = "Could not read this file as an image."
                showError = true
            }
        case .failure:
            break
        }
    }

    // MARK: - Process OCR

    private func processReceipt() async {
        guard let data = vm.receiptImageData else { return }
        isProcessing = true

        do {
            guard let cgImage = ReceiptImageData.cgImage(from: data) else {
                await MainActor.run {
                    isProcessing = false
                    nav.advance(.review)
                }
                return
            }
            let result = try await OCRService.shared.processReceipt(cgImage: cgImage)
            await MainActor.run {
                vm.lineItems = result.lineItems
                vm.subtotal = result.subtotal
                vm.tax = result.tax
                if let name = result.vendorName, vm.restaurant == nil {
                    vm.restaurant = Restaurant(id: UUID().uuidString, name: name, address: "")
                }
                isProcessing = false
                nav.advance(.review)
            }
        } catch {
            await MainActor.run {
                isProcessing = false
                nav.advance(.review)
            }
        }
    }
}

#Preview {
    ReceiptCaptureView()
        .environment(SplitFlowViewModel())
}
