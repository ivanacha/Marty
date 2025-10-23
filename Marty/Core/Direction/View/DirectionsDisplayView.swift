//
//  DirectionsDisplayView.swift
//  Marty
//
//  Created by iVan on 10/15/25.
//

import SwiftUI
import MapKit

struct DirectionsDisplayView: View {
    @ObservedObject var viewModel: DirectionViewModel
    let routeInfo: RouteInfo

    var body: some View {
        VStack(spacing: 0) {
            // Header with route summary
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if let destinationName = routeInfo.destinationName {
                            Text(destinationName)
                                .font(.headline)
                                .lineLimit(1)
                        }
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                Text(routeInfo.expectedTravelTime)
                                    .font(.subheadline)
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.left.and.right")
                                    .font(.caption)
                                Text(routeInfo.distance)
                                    .font(.subheadline)
                            }
                        }
                        .foregroundColor(.gray)
                    }

                    Spacer()

                    Button(action: {
                        viewModel.clearRoute()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding()

                Divider()
            }
            .background(Color(UIColor.systemBackground))

            // Transit steps list
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(routeInfo.transitSteps) { step in
                        HStack(alignment: .top, spacing: 12) {
                            // Icon
                            Image(systemName: step.type.icon)
                                .font(.title3)
                                .foregroundColor(.blue)
                                .frame(width: 30)

                            // Instructions
                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.instructions)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)

                                if step.distance > 0 {
                                    Text(step.formattedDistance)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()

                        if step.id != routeInfo.transitSteps.last?.id {
                            Divider()
                                .padding(.leading, 54)
                        }
                    }
                }
            }
            .background(Color(UIColor.systemBackground))
        }
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}
