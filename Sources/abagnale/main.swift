// MacBook Pro Camera Effects
// A Swift application that adds visual effects to your MacBook camera
// 
// This application:
// 1. Captures video from your MacBook's camera
// 2. Applies visual effects using Core Image filters
// 3. Shows the preview in the app window

import Cocoa
import AVFoundation
import CoreImage

// MARK: - Main Application

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var effectsController: EffectsController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the main window
        let windowRect = NSRect(x: 0, y: 0, width: 800, height: 600)
        window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "abagnale"
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        // Create the effects controller
        effectsController = EffectsController()
        
        // Set the window's content view
        let contentView = MainView(frame: windowRect, effectsController: effectsController)
        window.contentView = contentView
        
        // Start the camera
        effectsController.start()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Stop the camera when the app is closing
        effectsController.stop()
    }
}

// MARK: - Main View

class MainView: NSView {
    private let effectsController: EffectsController
    private let previewView: NSView
    private let effectsListView: NSTableView
    private let startStopButton: NSButton
    
    init(frame: NSRect, effectsController: EffectsController) {
        self.effectsController = effectsController
        
        // Create the camera preview view
        self.previewView = NSView(frame: NSRect(x: 20, y: 60, width: frame.width - 220, height: frame.height - 80))
        self.previewView.wantsLayer = true
        self.previewView.layer?.backgroundColor = NSColor.black.cgColor
        
        // Create the effects list table view
        let scrollView = NSScrollView(frame: NSRect(x: frame.width - 180, y: 60, width: 160, height: frame.height - 140))
        self.effectsListView = NSTableView()
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("EffectColumn"))
        column.title = "Effects"
        column.width = 140
        self.effectsListView.addTableColumn(column)
        self.effectsListView.headerView = nil
        self.effectsListView.usesAlternatingRowBackgroundColors = true
        scrollView.documentView = self.effectsListView
        scrollView.hasVerticalScroller = true
        
        // Create the start/stop button
        self.startStopButton = NSButton(frame: NSRect(x: frame.width - 180, y: 20, width: 160, height: 30))
        self.startStopButton.title = "Stop Camera"
        self.startStopButton.bezelStyle = .rounded
        
        super.init(frame: frame)
        
        // Add subviews
        addSubview(previewView)
        addSubview(scrollView)
        addSubview(startStopButton)
        
        // Setup effects list table view
        effectsListView.delegate = self
        effectsListView.dataSource = self
        
        // Setup preview view
        effectsController.setPreviewLayer(in: previewView.layer!)
        
        // Setup start/stop button
        startStopButton.target = self
        startStopButton.action = #selector(toggleCamera)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func toggleCamera() {
        if effectsController.isRunning {
            effectsController.stop()
            startStopButton.title = "Start Camera"
        } else {
            effectsController.start()
            startStopButton.title = "Stop Camera"
        }
    }
}

// MARK: - Table View Delegate/DataSource

extension MainView: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return effectsController.availableEffects.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = NSTableCellView()
        let textField = NSTextField(labelWithString: effectsController.availableEffects[row])
        cell.addSubview(textField)
        cell.textField = textField
        return cell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = effectsListView.selectedRow
        if selectedRow >= 0 {
            let effect = effectsController.availableEffects[selectedRow]
            effectsController.setEffect(effect)
        }
    }
}

// MARK: - Effects Controller

class EffectsController: NSObject {
    // Camera session
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    // Image processing
    private let context = CIContext()
    private var currentFilter: CIFilter?
    
    // State
    var isRunning: Bool = false
    
    // Available effects
    let availableEffects = [
        "Normal",
        "Sepia",
        "Comic Effect",
        "Color Invert",
        "Thermal",
        "X-Ray",
        "Bloom",
        "Pixellate",
        "Kaleidoscope",
        "Zoom Blur",
        "Vignette"
    ]
    
    override init() {
        super.init()
        
        // Check camera permissions first
        checkCameraPermissions()
    }
    
    func setPreviewLayer(in layer: CALayer) {
        // Create and add preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer
    }
    
    func start() {
        if !isRunning {
            captureSession.startRunning()
            isRunning = true
        }
    }
    
    func stop() {
        if isRunning {
            captureSession.stopRunning()
            isRunning = false
        }
    }
    
    func setEffect(_ effectName: String) {
        // Clean up existing filter
        currentFilter = nil
        
        // Create and configure new filter
        do {
            switch effectName {
            case "Normal":
                break  // No filter needed
            case "Sepia":
                if let filter = CIFilter(name: "CISepiaTone") {
                    filter.setValue(0.8, forKey: kCIInputIntensityKey)
                    currentFilter = filter
                }
            case "Comic Effect":
                currentFilter = CIFilter(name: "CIComicEffect")
            case "Color Invert":
                currentFilter = CIFilter(name: "CIColorInvert")
            case "Thermal":
                currentFilter = CIFilter(name: "CIFalseColor")
                if let filter = currentFilter {
                    filter.setValue(CIColor(red: 0.0, green: 0.0, blue: 1.0), forKey: "inputColor0")
                    filter.setValue(CIColor(red: 1.0, green: 0.0, blue: 0.0), forKey: "inputColor1")
                }
            case "X-Ray":
                if let filter = CIFilter(name: "CIColorInvert") {
                    currentFilter = filter
                    // Chain with a blue tint
                    let colorFilter = CIFilter(name: "CIColorControls")
                    colorFilter?.setValue(0.5, forKey: kCIInputSaturationKey)
                    colorFilter?.setValue(0.2, forKey: kCIInputBrightnessKey)
                    if let output = filter.outputImage {
                        colorFilter?.setValue(output, forKey: kCIInputImageKey)
                        currentFilter = colorFilter
                    }
                }
            case "Bloom":
                if let filter = CIFilter(name: "CIBloom") {
                    filter.setValue(2.5, forKey: kCIInputRadiusKey)
                    filter.setValue(1.0, forKey: kCIInputIntensityKey)
                    currentFilter = filter
                }
            case "Pixellate":
                if let filter = CIFilter(name: "CIPixellate") {
                    filter.setValue(20.0, forKey: kCIInputScaleKey)
                    currentFilter = filter
                }
            case "Kaleidoscope":
                if let filter = CIFilter(name: "CIKaleidoscope") {
                    filter.setValue(8.0, forKey: "inputCount")
                    filter.setValue(CIVector(x: 150.0, y: 150.0), forKey: kCIInputCenterKey)
                    currentFilter = filter
                }
            case "Zoom Blur":
                if let filter = CIFilter(name: "CIZoomBlur") {
                    filter.setValue(CIVector(x: 150.0, y: 150.0), forKey: kCIInputCenterKey)
                    filter.setValue(30.0, forKey: kCIInputAmountKey)
                    currentFilter = filter
                }
            case "Vignette":
                if let filter = CIFilter(name: "CIVignette") {
                    filter.setValue(1.0, forKey: kCIInputIntensityKey)
                    filter.setValue(5.0, forKey: kCIInputRadiusKey)
                    currentFilter = filter
                }
            default:
                print("Unknown effect: \(effectName)")
                return
            }
            
            print("Effect successfully changed to: \(effectName)")
            
            // Force an immediate frame update
            DispatchQueue.main.async { [weak self] in
                if let previewLayer = self?.previewLayer {
                    previewLayer.setNeedsDisplay()
                }
            }
        }
    }
    
    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCamera()
                    }
                } else {
                    self?.showCameraPermissionAlert()
                }
            }
        case .denied, .restricted:
            showCameraPermissionAlert()
        @unknown default:
            showCameraPermissionAlert()
        }
    }
    
    private func setupCamera() {
        // Setup capture session
        captureSession.sessionPreset = .high
        
        // Setup camera input
        guard let camera = AVCaptureDevice.default(for: .video) else {
            print("Camera not available")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            captureSession.addInput(input)
        } catch {
            print("Error setting up camera input: \(error)")
            return
        }
        
        // Setup video output
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(videoOutput)
        
        // Setup default filter
        currentFilter = CIFilter(name: "CISepiaTone")
        currentFilter?.setValue(0.8, forKey: kCIInputIntensityKey)
    }
    
    private func showCameraPermissionAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Camera Access Required"
            alert.informativeText = "Please enable camera access in System Preferences > Security & Privacy > Camera to use this application."
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}

// MARK: - Camera Frame Processing

extension EffectsController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to get pixel buffer from sample buffer")
            return
        }
        
        // Create CIImage from the pixel buffer
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Apply filter if one is selected
        if let filter = currentFilter {
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            if let filteredImage = filter.outputImage {
                ciImage = filteredImage
            } else {
                print("Failed to get output image from filter")
            }
        }
        
        // Update the preview layer with the processed image
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let cgImage = self.context.createCGImage(ciImage, from: ciImage.extent) {
                self.previewLayer?.contents = cgImage
            } else {
                print("Failed to create CGImage from CIImage")
            }
        }
    }
}