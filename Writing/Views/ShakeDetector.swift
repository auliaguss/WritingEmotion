import SwiftUI
import CoreMotion

class ShakeDetector: ObservableObject {
    private let motionManager = CMMotionManager()
    
    // Published variable to trigger UI updates
    @Published var shakeCount: Int = 0
    @Published var isCurrentlyShaking: Bool = false
    
    // Cooldown prevents one long shake from registering as dozens of distinct shakes
    private var lastShakeTime = Date.distantPast
    private let debounceWindow: TimeInterval = 0.5 
    
    // The force required to register a shake (adjust based on needs)
    private let shakeThreshold: Double = 2.5 
    
    func startMonitoring() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        // 50Hz is fast enough to catch sudden spikes
        motionManager.deviceMotionUpdateInterval = 1.0 / 50.0 
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let data = data, error == nil else { return }
            
            // 1. Isolate user movement from gravity
            let accel = data.userAcceleration
            
            // 2. Calculate the magnitude of the force vector
            let magnitude = sqrt(pow(accel.x, 2) + pow(accel.y, 2) + pow(accel.z, 2))
            
            // 3. Check if the force exceeds our threshold
            if magnitude > self.shakeThreshold {
                let now = Date()
                
                // 4. Debounce the event
                if now.timeIntervalSince(self.lastShakeTime) > self.debounceWindow {
                    self.lastShakeTime = now
                    self.registerShake()
                }
            }
        }
    }
    
    private func registerShake() {
        // Trigger UI changes
        withAnimation {
            shakeCount += 1
            isCurrentlyShaking = true
        }
        
        // Reset the visual "shaking" state after a brief moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                self.isCurrentlyShaking = false
            }
        }
    }
    
    func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
    }
}

// MARK: - UI Layer
struct ShakeView: View {
    @StateObject private var detector = ShakeDetector()
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Shakes Detected: \(detector.shakeCount)")
                .font(.largeTitle)
                .bold()
            
            Circle()
                .fill(detector.isCurrentlyShaking ? Color.red.gradient : Color.blue.gradient)
                .frame(width: 150, height: 150)
                // Add a visual spring effect when shaken
                .scaleEffect(detector.isCurrentlyShaking ? 1.2 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: detector.isCurrentlyShaking)
        }
        .onAppear {
            detector.startMonitoring()
        }
        .onDisappear {
            detector.stopMonitoring()
        }
    }
}