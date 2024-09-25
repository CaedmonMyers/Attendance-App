import SwiftUI
import AVFoundation
import CoreImage

class QRScannerViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var scannedCode: String = ""
    let captureSession = AVCaptureSession()
    let qrDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])!
    
    override init() {
        super.init()
        setupCaptureSession()
    }
    
    func setupCaptureSession() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
            
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.captureSession.startRunning()
            }
        } catch {
            print("Failed to set up capture session: \(error)")
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let features = qrDetector.features(in: ciImage)
        
        for case let feature as CIQRCodeFeature in features {
            DispatchQueue.main.async { [weak self] in
                self?.scannedCode = feature.messageString ?? ""
            }
        }
    }
}

struct PlayerContainerView: NSViewRepresentable {
    let captureSession: AVCaptureSession
    
    func makeNSView(context: Context) -> PlayerView {
        return PlayerView(captureSession: captureSession)
    }
    
    func updateNSView(_ nsView: PlayerView, context: Context) {}
}

class PlayerView: NSView {
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    init(captureSession: AVCaptureSession) {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        super.init(frame: .zero)
        setupLayer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupLayer() {
        previewLayer?.frame = self.frame
        previewLayer?.contentsGravity = .resizeAspectFill
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.connection?.automaticallyAdjustsVideoMirroring = false
        
        if let mirroringSupported = previewLayer?.connection?.isVideoMirroringSupported, mirroringSupported {
            previewLayer?.connection?.automaticallyAdjustsVideoMirroring = false
            previewLayer?.connection?.isVideoMirrored = true
        }
        
        layer = previewLayer
    }
    
    override func layout() {
        super.layout()
        previewLayer?.frame = bounds
    }
}

struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}
