//
//  LocationType.swift
//  Marty
//
//  Enum for different types of saved locations
//  Enhanced with display properties and Codable conformance
//

import Foundation

enum LocationType: String, CaseIterable, Codable {
    case home = "home"
    case work = "work" 
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .home:
            return "Home"
        case .work:
            return "Work"
        case .custom:
            return "Custom"
        }
    }
    
    var systemImage: String {
        switch self {
        case .home:
            return "house.fill"
        case .work:
            return "briefcase.fill"
        case .custom:
            return "location.fill"
        }
    }
}
