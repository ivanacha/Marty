//
//  MARTAConfiguration.swift
//  Marty
//
//  MARTA system configuration with line colors and route styles
//  Created by iVan on 10/15/25.
//

import Foundation
import SwiftUI
import MapKit

// MARK: - MARTA Line Colors
struct MARTALine {
    let name: String
    let color: Color
    let uiColor: UIColor
    
    static let red = MARTALine(
        name: "Red Line",
        color: .red,
        uiColor: UIColor.systemRed
    )
    
    static let blue = MARTALine(
        name: "Blue Line", 
        color: .blue,
        uiColor: UIColor.systemBlue
    )
    
    static let green = MARTALine(
        name: "Green Line",
        color: .green,
        uiColor: UIColor.systemGreen
    )
    
    static let gold = MARTALine(
        name: "Gold Line",
        color: .yellow,
        uiColor: UIColor.systemYellow
    )
    
    static let allLines = [red, blue, green, gold]
    
    static func lineForStationName(_ stationName: String) -> MARTALine {
        let lowercaseName = stationName.lowercased()
        
        // Red Line stations (example - you can expand this)
        if lowercaseName.contains("north springs") || lowercaseName.contains("sandy springs") || 
           lowercaseName.contains("medical center") || lowercaseName.contains("dunwoody") ||
           lowercaseName.contains("perimeter center") || lowercaseName.contains("north avenue") {
            return .red
        }
        
        // Blue Line stations
        if lowercaseName.contains("indian creek") || lowercaseName.contains("kensington") ||
           lowercaseName.contains("candler park") || lowercaseName.contains("edgewood") {
            return .blue
        }
        
        // Green Line stations  
        if lowercaseName.contains("bankhead") || lowercaseName.contains("ashby") ||
           lowercaseName.contains("vine city") || lowercaseName.contains("omni") {
            return .green
        }
        
        // Gold Line stations
        if lowercaseName.contains("doraville") || lowercaseName.contains("chamblee") ||
           lowercaseName.contains("brookhaven") || lowercaseName.contains("lenox") {
            return .gold
        }
        
        // Default to red if line can't be determined
        return .red
    }
    
    static func lineForInstructions(_ instructions: String) -> MARTALine {
        let lowercaseInstructions = instructions.lowercased()
        
        if lowercaseInstructions.contains("red line") || lowercaseInstructions.contains("red") {
            return .red
        } else if lowercaseInstructions.contains("blue line") || lowercaseInstructions.contains("blue") {
            return .blue
        } else if lowercaseInstructions.contains("green line") || lowercaseInstructions.contains("green") {
            return .green
        } else if lowercaseInstructions.contains("gold line") || lowercaseInstructions.contains("gold") {
            return .gold
        }
        
        return .red // Default
    }
}

// MARK: - Route Segment Types
enum RouteSegmentType {
    case walking
    case transit(line: MARTALine)
    case transitGeneric // For when we can't determine the specific line
    
    var color: Color {
        switch self {
        case .walking:
            return .gray
        case .transit(let line):
            return line.color
        case .transitGeneric:
            return .purple
        }
    }
    
    var uiColor: UIColor {
        switch self {
        case .walking:
            return UIColor.systemGray
        case .transit(let line):
            return line.uiColor
        case .transitGeneric:
            return UIColor.systemPurple
        }
    }
    
    var strokeStyle: StrokeStyle {
        switch self {
        case .walking:
            return StrokeStyle(lineWidth: 4, dash: [10, 5])
        case .transit(_), .transitGeneric:
            return StrokeStyle(lineWidth: 6)
        }
    }
}

// MARK: - Enhanced Route Segment
struct RouteSegment: Identifiable {
    let id = UUID()
    let polyline: MKPolyline
    let type: RouteSegmentType
    let instructions: String
    let distance: CLLocationDistance
    
    init(polyline: MKPolyline, type: RouteSegmentType, instructions: String, distance: CLLocationDistance) {
        self.polyline = polyline
        self.type = type
        self.instructions = instructions
        self.distance = distance
    }
}