//
//  SavedLocation.swift
//  Marty
//
//  Created by iVan on 10/14/25.
//

import Foundation
import CoreLocation

struct SavedLocation: Identifiable {
    let id = UUID()
    let type: LocationType
    let coordinate: CLLocationCoordinate2D
    let address: String
}
