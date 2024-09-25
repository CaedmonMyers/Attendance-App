import SwiftUI
import AVFoundation
import Vision

struct ContentView: View {
    @EnvironmentObject private var attendanceStore: AttendanceStore
    @State private var newEntryId = ""
    @State private var isScanning = false
    @State private var successViewShown = false
    @StateObject private var viewModel = QRScannerViewModel()
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [Color.blue.opacity(successViewShown ? 0.7 : 0.4), Color.purple.opacity(successViewShown ? 0.7 : 0.4)], startPoint: .leading, endPoint: .trailing)
                    .edgesIgnoringSafeArea(.all)
                    .animation(.default, value: successViewShown)
                
                VStack {
                    Spacer()
                    
                    HStack {
                        VStack {
                            Text("Check In")
                                .foregroundStyle(Color.white)
                                .font(.system(size: 50, weight: .bold, design: .rounded))
                                .animation(.default, value: newEntryId)
                            
                            CustomTextField(text: $newEntryId, placeholder: "Enter 6-digit ID", onCommit: checkIn)
                                .frame(width: 300, height: 50)
                                .padding()
                                .animation(.default, value: newEntryId)
                                .onKeyPress(.escape) {
                                    newEntryId = ""
                                    return .handled
                                }
                            
                            if !newEntryId.isEmpty {
                                Button(action: checkIn) {
                                    Text("Check In")
                                }
                                .buttonStyle(CustomButtonStyle())
                                .animation(.default, value: newEntryId)
                            }
                            
                            Button("Scan Barcode") {
                                isScanning = true
                                            }
                                            .buttonStyle(CustomButtonStyle())
                                            .padding()
                            
                        }.animation(.default, value: successViewShown)
                        .frame(width: successViewShown ? geo.size.width/3 : geo.size.width)
                        
                        VStack {
                            if let user = attendanceStore.checkedInUser {
                                Text("Success!")
                                    .foregroundStyle(Color.white)
                                    .font(.system(size: 50, weight: .bold, design: .rounded))
                                    .padding(20)
                                
                                Text("You have been checked in as:")
                                    .foregroundStyle(Color.white)
                                    .font(.system(size: 20, weight: .medium, design: .rounded))
                                    .padding(10)
                                
                                TypewriterView(text: .constant(user.name))
                                    .foregroundStyle(Color.white)
                                    .font(.system(size: 30, weight: .black, design: .rounded))
                                
                                Text(user.subteam)
                                    .foregroundStyle(Color.white)
                                    .font(.system(size: 20, weight: .medium, design: .rounded))
                                    .padding(10)
                            }
                        }.animation(.default, value: successViewShown)
                        .offset(x: successViewShown ? 0 : geo.size.width)
                        .frame(width: geo.size.width/3)
                        
                        Spacer()
                            .animation(.default, value: successViewShown)
                            .offset(x: successViewShown ? 0 : geo.size.width)
                            .frame(width: geo.size.width/3)
                    }
                    
                    Spacer()
                }
            }
            .sheet(isPresented: $isScanning) {
                PlayerContainerView(captureSession: viewModel.captureSession)
                                .frame(height: 300)
                        }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    private func checkIn() {
        attendanceStore.checkInUser(id: newEntryId)
        newEntryId = ""
        withAnimation {
            successViewShown = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                successViewShown = false
                attendanceStore.checkedInUser = nil
            }
        }
    }
}


struct CameraPreview: NSViewRepresentable {
    let session: AVCaptureSession
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        previewLayer.videoGravity = .resizeAspectFill
        view.layer = previewLayer
        view.wantsLayer = true
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}


extension String {
    func capitalizedFirstLetterOfEachWord() -> String {
        return self.components(separatedBy: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
}



