//
//  PerformanceMonitor.swift
//  Marty
//
//  Utility for monitoring app performance and startup times
//  Helps identify bottlenecks during development
//

import Foundation
import os

@MainActor
final class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Marty", category: "Performance")
    private var startTimes: [String: CFTimeInterval] = [:]
    
    private init() {}
    
    func startTimer(for operation: String) {
        startTimes[operation] = CFAbsoluteTimeGetCurrent()
        logger.info("⏱️ Started: \(operation)")
    }
    
    func endTimer(for operation: String) {
        guard let startTime = startTimes[operation] else {
            logger.warning("⚠️ No start time found for operation: \(operation)")
            return
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        startTimes.removeValue(forKey: operation)
        
        let durationMs = duration * 1000
        if durationMs > 100 {
            logger.warning("🐌 Slow operation: \(operation) took \(String(format: "%.2f", durationMs))ms")
        } else {
            logger.info("✅ Completed: \(operation) in \(String(format: "%.2f", durationMs))ms")
        }
    }
    
    func logMemoryUsage() {
        let memoryUsage = getMemoryUsage()
        logger.info("📱 Memory usage: \(String(format: "%.2f", memoryUsage))MB")
    }
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0
        }
        
        return 0
    }
}

// MARK: - Convenience Methods
extension PerformanceMonitor {
    func measure<T>(_ operation: String, block: () throws -> T) rethrows -> T {
        startTimer(for: operation)
        defer { endTimer(for: operation) }
        return try block()
    }
    
    func measureAsync<T>(_ operation: String, block: () async throws -> T) async rethrows -> T {
        startTimer(for: operation)
        defer { endTimer(for: operation) }
        return try await block()
    }
}