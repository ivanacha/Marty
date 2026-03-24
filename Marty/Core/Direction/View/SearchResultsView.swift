//
//  SearchResultsView.swift
//  Marty
//
//  Created by iVan on 10/14/25.
//

import SwiftUI
import MapKit

struct SearchResultsView: View {
    @ObservedObject var viewModel: DirectionViewModel
    @Binding var searchText: String
    @Binding var showingSearchResults: Bool
    @Binding var isSearchFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(viewModel.searchResults, id: \.self) { item in
                    Button(action: {
                        if let coordinate = item.placemark.coordinate as CLLocationCoordinate2D? {
                            let destinationName = item.name ?? viewModel.formatAddress(from: item.placemark)
                            viewModel.getDirections(to: coordinate, destinationName: destinationName)
                            searchText = ""
                            showingSearchResults = false
                            isSearchFieldFocused = false
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name ?? "Unknown")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            if let formattedAddress = viewModel.formatAddress(from: item.placemark) {
                                Text(formattedAddress)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                    Divider()
                }
            }
        }
    }
}
