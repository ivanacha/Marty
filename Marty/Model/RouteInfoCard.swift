//
//  RouteInfoCard.swift
//  Marty
//
//  SwiftUI view for displaying detailed route information with MARTA transit steps
//  Created by iVan on 10/15/25.
//

import SwiftUI
import MapKit

struct RouteInfoCard: View {
    let routeInfo: RouteInfo
    let onClearRoute: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with route summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(routeInfo.destinationName ?? "Unknown Destination")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 16) {
                        Label(routeInfo.expectedTravelTime, systemImage: "clock")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Label(routeInfo.distance, systemImage: "location")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: onClearRoute) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
            
            // Route steps
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(routeInfo.transitSteps.enumerated()), id: \.offset) { index, step in
                        RouteStepView(step: step, isLast: index == routeInfo.transitSteps.count - 1)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 200)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct RouteStepView: View {
    let step: TransitStep
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                // Step icon
                ZStack {
                    Circle()
                        .fill(stepIconBackgroundColor)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: step.type.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(stepIconForegroundColor)
                }
                
                // Connecting line
                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2, height: 20)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(step.instructions)
                    .font(.body)
                    .fontWeight(.medium)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(step.formattedDistance)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var stepIconBackgroundColor: Color {
        switch step.type {
        case .walking:
            return .gray.opacity(0.2)
        case .transit:
            return .blue.opacity(0.2)
        case .instruction:
            return .orange.opacity(0.2)
        }
    }
    
    private var stepIconForegroundColor: Color {
        switch step.type {
        case .walking:
            return .gray
        case .transit:
            return .blue
        case .instruction:
            return .orange
        }
    }
}

#Preview {
    RouteInfoCard(
        routeInfo: RouteInfo(
            route: MKRoute(), // This won't work in preview, but shows structure
            destination: CLLocationCoordinate2D(latitude: 33.7490, longitude: -84.3880),
            destinationName: "Five Points Station"
        ),
        onClearRoute: {}
    )
}