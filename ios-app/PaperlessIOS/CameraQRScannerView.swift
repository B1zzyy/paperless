import SwiftUI
import AVFoundation

struct CameraQRScannerView: UIViewRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIView(context: Context) -> ScannerPreviewView {
        let view = ScannerPreviewView()
        context.coordinator.configureSessionIfNeeded(in: view, onCodeScanned: onCodeScanned)
        return view
    }

    func updateUIView(_ uiView: ScannerPreviewView, context: Context) {
        context.coordinator.configureSessionIfNeeded(in: uiView, onCodeScanned: onCodeScanned)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    static func dismantleUIView(_ uiView: ScannerPreviewView, coordinator: Coordinator) {
        coordinator.stopSession()
    }

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        private let session = AVCaptureSession()
        private var didConfigureSession = false
        private var didScan = false
        private var onCodeScanned: ((String) -> Void)?

        func configureSessionIfNeeded(in view: ScannerPreviewView, onCodeScanned: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned

#if targetEnvironment(simulator)
            // Avoid simulator camera pipeline errors/noise; run real capture only on device.
            return
#else
            view.attachSession(session)

            guard !didConfigureSession else {
                startSessionIfNeeded()
                return
            }
            didConfigureSession = true
            session.beginConfiguration()
            if session.canSetSessionPreset(.hd1280x720) {
                session.sessionPreset = .hd1280x720
            }

            guard
                let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let cameraInput = try? AVCaptureDeviceInput(device: camera),
                session.canAddInput(cameraInput)
            else {
                session.commitConfiguration()
                return
            }

            session.addInput(cameraInput)

            let metadataOutput = AVCaptureMetadataOutput()
            guard session.canAddOutput(metadataOutput) else {
                session.commitConfiguration()
                return
            }
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = [.qr]
            session.commitConfiguration()

            startSessionIfNeeded()
#endif
        }

        private func startSessionIfNeeded() {
            guard !session.isRunning else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }

        func stopSession() {
            guard session.isRunning else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.stopRunning()
            }
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard !didScan else { return }
            guard
                let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                object.type == .qr,
                let stringValue = object.stringValue
            else {
                return
            }

            didScan = true
            // Stop capture immediately to reduce transition hitch after first successful scan.
            stopSession()
            onCodeScanned?(stringValue)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.didScan = false
            }
        }
    }
}

final class ScannerPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    private var previewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected AVCaptureVideoPreviewLayer")
        }
        return layer
    }

    func attachSession(_ session: AVCaptureSession) {
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
    }
}
