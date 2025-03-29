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
import CoreMediaIO
import SystemExtensions

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
    private let applyEffectButton: NSButton
    private var selectedEffect: String?
    
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
        
        // Create the apply effect button
        self.applyEffectButton = NSButton(frame: NSRect(x: frame.width - 180, y: 60, width: 160, height: 30))
        self.applyEffectButton.title = "Apply Effect"
        self.applyEffectButton.bezelStyle = .rounded
        self.applyEffectButton.isEnabled = false
        
        super.init(frame: frame)
        
        // Add subviews
        addSubview(previewView)
        addSubview(scrollView)
        addSubview(startStopButton)
        addSubview(applyEffectButton)
        
        // Setup effects list table view
        effectsListView.delegate = self
        effectsListView.dataSource = self
        
        // Setup preview view
        effectsController.setPreviewLayer(in: previewView.layer!)
        
        // Setup buttons
        startStopButton.target = self
        startStopButton.action = #selector(toggleCamera)
        
        applyEffectButton.target = self
        applyEffectButton.action = #selector(applyEffect)
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
    
    @objc func applyEffect() {
        if let effect = selectedEffect {
            effectsController.setEffect(effect)
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
            selectedEffect = effectsController.availableEffects[selectedRow]
            applyEffectButton.isEnabled = true
        } else {
            selectedEffect = nil
            applyEffectButton.isEnabled = false
        }
    }
}

// MARK: - Effects Controller

@available(macOS 12.3, *)
class VirtualCameraExtension: NSObject, CMIOExtensionProviderSource, CMIOExtensionStreamSource {
    private(set) var provider: CMIOExtensionProvider?
    private var device: CMIOExtensionDevice?
    private var stream: CMIOExtensionStream?
    private var bufferPool: CMIOExtensionDeviceBufferPool?
    private var timer: Timer?
    private var sequenceNumber: UInt64 = 0
    private var currentImage: CGImage?
    
    let deviceUID = "com.abagnale.virtual-camera.device"
    let streamUID = "com.abagnale.virtual-camera.stream"
    
    override init() {
        super.init()
        setupProvider()
    }
    
    func updateFrame(_ image: CGImage) {
        self.currentImage = image
    }
    
    private func setupProvider() {
        do {
            provider = try CMIOExtensionProvider(source: self)
            try provider?.setAuthorizedProperties([CMIOExtensionProperty.deviceTransportType])
            
            let deviceProperties = CMIOExtensionDeviceProperties(transportType: kIOAudioDeviceTransportTypeBuiltIn)
            let device = CMIOExtensionDevice(properties: deviceProperties,
                                           deviceID: deviceUID,
                                           name: "Abagnale Camera Effects",
                                           manufacturer: "Abagnale",
                                           source: self)
            try provider?.addDevice(device)
            self.device = device
            
            let dimensions = CMVideoDimensions(width: 1280, height: 720)
            let streamFormat = try CMIOExtensionStreamFormat.init(formatDescription: CMFormatDescription.make(videoCodecType: .jpeg,
                                                                                                             width: dimensions.width,
                                                                                                             height: dimensions.height))
            let streamProperties = CMIOExtensionStreamProperties()
            let stream = CMIOExtensionStream(properties: streamProperties,
                                           streamID: streamUID,
                                           streamFormat: streamFormat,
                                           device: device,
                                           source: self)
            try device.addStream(stream)
            self.stream = stream
            
            self.bufferPool = try .init(pixelBufferAttributes: [
                kCVPixelBufferWidthKey: dimensions.width,
                kCVPixelBufferHeightKey: dimensions.height,
                kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
                kCVPixelBufferMetalCompatibilityKey: true
            ] as [String: Any])
            
            startStreaming()
        } catch {
            print("Failed to create virtual camera: \(error)")
        }
    }
    
    func startStreaming() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { [weak self] _ in
            self?.sendFrame()
        }
    }
    
    func stopStreaming() {
        timer?.invalidate()
        timer = nil
    }
    
    private func sendFrame() {
        guard let pool = bufferPool,
              let stream = stream,
              let currentImage = currentImage else { return }
        
        do {
            let timing = CMIOExtensionTimingInfo(timestamp: CMTime(value: CMClockGetTime(CMClockGetHostTimeClock()),
                                                                  timescale: 1000000000),
                                               duration: CMTime(value: 1, timescale: 30))
            
            var pixelBuffer: CVPixelBuffer?
            CVPixelBufferCreate(kCFAllocatorDefault,
                              Int(currentImage.width),
                              Int(currentImage.height),
                              kCVPixelFormatType_32BGRA,
                              nil,
                              &pixelBuffer)
            
            if let pixelBuffer = pixelBuffer {
                CVPixelBufferLockBaseAddress(pixelBuffer, [])
                let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                                      width: Int(currentImage.width),
                                      height: Int(currentImage.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
                context?.draw(currentImage, in: CGRect(x: 0, y: 0, width: currentImage.width, height: currentImage.height))
                CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
                
                try stream.sendBuffer(pixelBuffer,
                                    with: timing,
                                    sequenceNumber: sequenceNumber)
                sequenceNumber += 1
            }
        } catch {
            print("Failed to send frame: \(error)")
        }
    }
    
    // MARK: - CMIOExtensionProviderSource
    
    func connect(to provider: CMIOExtensionProvider) throws { }
    
    func disconnect(from provider: CMIOExtensionProvider) { }
    
    // MARK: - CMIOExtensionStreamSource
    
    func streamProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionStreamProperties {
        return CMIOExtensionStreamProperties()
    }
    
    func deviceProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionDeviceProperties {
        return CMIOExtensionDeviceProperties()
    }
    
    func authorizedToStartStream(for client: CMIOExtensionClient) -> Bool { true }
    
    func startStream() throws { }
    
    func stopStream() throws { }
}

class EffectsController: NSObject {
    // Camera session
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var previewLayer: CALayer?
    
    // Virtual camera
    private var virtualCamera: VirtualCameraExtension?
    
    // Image processing
    private let context = CIContext()
    private var currentFilter: CIFilter?
    
    // State
    var isRunning: Bool = false
    private var isPaused: Bool = false
    private var lastFrame: CIImage?
    private var transitionTimer: Timer?
    private var transitionProgress: CGFloat = 0.0
    
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
        
        // Setup virtual camera if supported
        if #available(macOS 12.3, *) {
            setupVirtualCamera()
        } else {
            print("Virtual camera requires macOS 12.3 or later")
        }
    }
    
    func setPreviewLayer(in layer: CALayer) {
        // Create and add preview layer
        let previewLayer = CALayer()
        previewLayer.frame = layer.bounds
        previewLayer.contentsGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer
    }
    
    private func setupVirtualCamera() {
        if #available(macOS 12.3, *) {
            virtualCamera = VirtualCameraExtension()
        }
    }
    
    func start() {
        if !isRunning {
            captureSession.startRunning()
            if #available(macOS 12.3, *) {
                virtualCamera?.startStreaming()
            }
            isRunning = true
            isPaused = false
            transitionProgress = 0.0
            transitionTimer?.invalidate()
            transitionTimer = nil
        }
    }
    
    func stop() {
        if isRunning {
            isPaused = true
            transitionProgress = 0.0
            transitionTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.transitionProgress += 0.1
                if self.transitionProgress >= 1.0 {
                    self.transitionTimer?.invalidate()
                    self.transitionTimer = nil
                    self.captureSession.stopRunning()
                    if #available(macOS 12.3, *) {
                        self.virtualCamera?.stopStreaming()
                    }
                    self.isRunning = false
                }
            }
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
        
        // Store the last frame if we're paused
        if isPaused {
            lastFrame = ciImage
        }
        
        // Apply transition effect if we're in the process of stopping
        if transitionProgress > 0 && transitionProgress < 1.0 {
            if let lastFrame = lastFrame {
                // Create a blend between the last frame and current frame
                let blendFilter = CIFilter(name: "CIBlendWithMask")
                blendFilter?.setValue(lastFrame, forKey: kCIInputBackgroundImageKey)
                blendFilter?.setValue(ciImage, forKey: kCIInputImageKey)
                let maskImage = CIImage(color: CIColor(red: transitionProgress, green: transitionProgress, blue: transitionProgress))
                blendFilter?.setValue(maskImage, forKey: kCIInputMaskImageKey)
                if let blendedImage = blendFilter?.outputImage {
                    ciImage = blendedImage
                }
            }
        }
        
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
                if #available(macOS 12.3, *) {
                    self.virtualCamera?.updateFrame(cgImage)
                }
            } else {
                print("Failed to create CGImage from CIImage")
            }
        }
    }
}