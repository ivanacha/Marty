//
//  SavedLocation.swift
//  Marty
//
//  Model for saved user locations (home, work, custom)
//  Uses LocationType enum and conforms to Codable for better persistence support
//

import Foundation
import CoreLocation

struct SavedLocation: Identifiable, Codable {
    let id = UUID()
    let type: LocationType
    let coordinate: CLLocationCoordinate2D
    let address: String
    
    // Custom coding keys to handle CLLocationCoordinate2D
    enum CodingKeys: CodingKey {
        case id, type, latitude, longitude, address
    }
    
    init(id: UUID = UUID(), type: LocationType, coordinate: CLLocationCoordinate2D, address: String) {
        self.type = type
        self.coordinate = coordinate
        self.address = address
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(LocationType.self, forKey: .type)
        address = try container.decode(String.self, forKey: .address)
        
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(address, forKey: .address)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
}
