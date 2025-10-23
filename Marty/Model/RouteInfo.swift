//
//  RouteInfo.swift
//  Marty
//
//  Created by iVan on 10/15/25.
//

import Foundation
import MapKit

struct RouteInfo: Identifiable {
    let id = UUID()
    let route: MKRoute
    let destination: CLLocationCoordinate2D
    let destinationName: String?

    var distance: String {
        let distanceInMiles = route.distance / 1609.34
        return String(format: "%.1f mi", distanceInMiles)
    }

    var expectedTravelTime: String {
        let minutes = Int(route.expectedTravelTime / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }

    var transitSteps: [TransitStep] {
        var steps: [TransitStep] = []

        for step in route.steps {
            if !step.instructions.isEmpty {
                let stepType: TransitStepType

                if step.instructions.contains("MARTA") || step.instructions.lowercased().contains("train") {
                    stepType = .transit
                } else if step.instructions.lowercased().contains("walk") {
                    stepType = .walking
                } else {
                    stepType = .instruction
                }

                steps.append(TransitStep(
                    instructions: step.instructions,
                    distance: step.distance,
                    type: stepType
                ))
            }
        }

        return steps
    }
}

struct TransitStep: Identifiable {
    let id = UUID()
    let instructions: String
    let distance: CLLocationDistance
    let type: TransitStepType

    var formattedDistance: String {
        let distanceInFeet = distance * 3.28084
        if distanceInFeet < 528 { // Less than 0.1 miles
            return "\(Int(distanceInFeet)) ft"
        } else {
            let distanceInMiles = distance / 1609.34
            return String(format: "%.1f mi", distanceInMiles)
        }
    }
}

enum TransitStepType {
    case walking
    case transit
    case instruction

    var icon: String {
        switch self {
        case .walking:
            return "figure.walk"
        case .transit:
            return "tram.fill"
        case .instruction:
            return "arrow.turn.up.right"
        }
    }
}
