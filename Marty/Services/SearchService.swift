//
//  SearchService.swift
//  Marty
//
//  Service layer for location search functionality
//  Optimized for performance with caching and async/await
//

import Foundation
@preconcurrency import MapKit
import Combine

protocol SearchServiceProtocol {
    func searchLocations(query: String, in region: MKCoordinateRegion?) async throws -> [MKMapItem]
    func searchLocations(query: String, in region: MKCoordinateRegion?) -> AnyPublisher<[MKMapItem], Error>
}

final class SearchService: SearchServiceProtocol {
    static let shared = SearchService()
    
    // Cache recent searches to improve performance
    private var searchCache: [String: [MKMapItem]] = [:]
    private let cacheQueue = DispatchQueue(label: "search.cache", qos: .utility)
    
    // Default Atlanta region for MARTA
    private let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 33.7490, longitude: -84.3880),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    
    private init() {}
    
    // MARK: - Async/Await Implementation (Preferred)
    func searchLocations(query: String, in region: MKCoordinateRegion? = nil) async throws -> [MKMapItem] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        let cacheKey = "\(query)_\(region?.center.latitude ?? defaultRegion.center.latitude)"
        
        // Check cache first
        if let cachedResults = await getCachedResults(for: cacheKey) {
            return cachedResults
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.region = region ?? defaultRegion
            
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    let results = response?.mapItems ?? []
                    // Cache results for future use
                    Task {
                        await self.cacheResults(results, for: cacheKey)
                    }
                    continuation.resume(returning: results)
                }
            }
        }
    }
    
    // MARK: - Combine Implementation (For backward compatibility)
    func searchLocations(query: String, in region: MKCoordinateRegion? = nil) -> AnyPublisher<[MKMapItem], Error> {
        Future<[MKMapItem], Error> { promise in
            Task {
                do {
                    let results = try await self.searchLocations(query: query, in: region)
                    promise(.success(results))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Cache Management
    @MainActor
    private func getCachedResults(for key: String) async -> [MKMapItem]? {
        return await withCheckedContinuation { continuation in
            cacheQueue.async {
                continuation.resume(returning: self.searchCache[key])
            }
        }
    }
    
    @MainActor
    private func cacheResults(_ results: [MKMapItem], for key: String) async {
        await withCheckedContinuation { continuation in
            cacheQueue.async {
                self.searchCache[key] = results
                // Limit cache size to prevent memory issues
                if self.searchCache.count > 50 {
                    let keysToRemove = Array(self.searchCache.keys.prefix(10))
                    keysToRemove.forEach { self.searchCache.removeValue(forKey: $0) }
                }
                continuation.resume()
            }
        }
    }
    
    func clearCache() {
        cacheQueue.async {
            self.searchCache.removeAll()
        }
    }
}