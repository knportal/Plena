//
//  DeviceStateService.swift
//  PlenaShared
//
//  Created on [Date]
//

import Foundation
import Combine

#if os(watchOS)
import CoreMotion
#endif

/// Service to detect device state, particularly whether Apple Watch is on wrist
protocol DeviceStateServiceProtocol {
    var isDeviceOnWrist: Bool { get }
    var isDeviceOnWristPublisher: AnyPublisher<Bool, Never> { get }
    func startMonitoring()
    func stopMonitoring()
}

class DeviceStateService: DeviceStateServiceProtocol, ObservableObject {
    @Published private(set) var isDeviceOnWrist: Bool = true // Default to true to avoid false negatives

    #if os(watchOS)
    private let motionManager = CMMotionManager()
    private var deviceMotionQueue: OperationQueue?
    private var isMonitoring = false

    // Thresholds for motion detection
    // When watch is on wrist, there should be some motion (even minimal from breathing/movement)
    // When on charger, motion should be near zero
    private let motionThreshold: Double = 0.05 // m/s^2 - very low threshold for minimal movement
    private let samplesForDetection = 5 // Need multiple samples to confirm
    private var recentMotionSamples: [Double] = []
    private let maxSamples = 10
    #endif

    var isDeviceOnWristPublisher: AnyPublisher<Bool, Never> {
        $isDeviceOnWrist.eraseToAnyPublisher()
    }

    init() {
        #if os(watchOS)
        // Set up motion manager
        motionManager.deviceMotionUpdateInterval = 1.0 // Check once per second
        deviceMotionQueue = OperationQueue()
        deviceMotionQueue?.maxConcurrentOperationCount = 1
        deviceMotionQueue?.name = "com.plena.devicestate.motion"
        #endif
    }

    func startMonitoring() {
        #if os(watchOS)
        guard !isMonitoring else { return }
        isMonitoring = true
        recentMotionSamples.removeAll()

        // Start device motion updates to detect if watch is on wrist
        // When watch is on wrist, there's typically some motion (even from breathing)
        // When on charger, motion should be essentially zero
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: deviceMotionQueue!) { [weak self] motion, error in
                guard let self = self, let motion = motion, error == nil else { return }

                // Calculate total acceleration magnitude (excluding gravity)
                let userAcceleration = motion.userAcceleration
                let magnitude = sqrt(
                    userAcceleration.x * userAcceleration.x +
                    userAcceleration.y * userAcceleration.y +
                    userAcceleration.z * userAcceleration.z
                )

                // Add to recent samples
                DispatchQueue.main.async {
                    self.recentMotionSamples.append(magnitude)
                    if self.recentMotionSamples.count > self.maxSamples {
                        self.recentMotionSamples.removeFirst()
                    }

                    // Determine if watch is on wrist based on motion
                    self.updateOnWristStatus()
                }
            }
        } else {
            // Device motion not available, default to assuming on wrist
            DispatchQueue.main.async {
                self.isDeviceOnWrist = true
            }
        }
        #else
        // On iOS, we can't directly detect watch on wrist
        // Default to true (assuming watch is on wrist if paired)
        DispatchQueue.main.async {
            self.isDeviceOnWrist = true
        }
        #endif
    }

    func stopMonitoring() {
        #if os(watchOS)
        guard isMonitoring else { return }
        isMonitoring = false

        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }

        recentMotionSamples.removeAll()
        #endif
    }

    #if os(watchOS)
    private func updateOnWristStatus() {
        guard recentMotionSamples.count >= samplesForDetection else {
            // Not enough samples yet, assume on wrist to avoid false negatives
            isDeviceOnWrist = true
            return
        }

        // Calculate average motion over recent samples
        let averageMotion = recentMotionSamples.reduce(0.0, +) / Double(recentMotionSamples.count)

        // Count how many recent samples show very low motion
        let lowMotionCount = recentMotionSamples.filter { $0 < motionThreshold * 0.5 }.count
        let lowMotionRatio = Double(lowMotionCount) / Double(recentMotionSamples.count)

        // If most samples show very low motion, watch is likely off wrist
        if lowMotionRatio > 0.7 && recentMotionSamples.count >= samplesForDetection {
            isDeviceOnWrist = false
        } else if averageMotion >= motionThreshold {
            // If we see meaningful motion, watch is definitely on wrist
            isDeviceOnWrist = true
        }
        // Otherwise, maintain current state to avoid flickering
    }
    #endif
}

