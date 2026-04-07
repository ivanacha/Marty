<h1>MARTY</h1>
</br>A modern SwiftUI app for iOS/iPadOS that helps users find places, view them on a map, and get public transit directions. Built with MapKit, MVVM, and dependency injection for clean separation of concerns and testability.

*Scope* </br>
• Feature objectives</br>
  • Show a map centered around the user with smooth camera control.</br>
   • Search for places with region bias to the user’s location when available.</br>
   • Calculate and display public transit routes, including steps and ETA.</br>
   • Manage and navigate to saved locations (e.g., Home, Work, Custom).</br>
<h3>Current feature focus</h3></br>
   • Turn-by-turn voice navigation.</br>
   • Offline maps and routing.</br>
   • Full persistence for saved locations (placeholder TODOs exist for SwiftData).</br>

<h2>Features</h2></br>
• Map and Location</br>
   • Request and manage location permissions.</br>
   • Start/stop location updates via a LocationServiceProtocol.</br>
   • Center and bias the map camera with MapCameraPosition.</br>
   • Smart initial positioning with a slight vertical offset to keep the user in the upper portion of the screen.</br>
• Search</br>
   • Location search using MapKit (MKLocalSearch) through SearchServiceProtocol.</br>
   • Region-aware search when the user’s location is available.</br>
   • Clean address formatting for placemarks.</br>
• Transit Routing</br>
   • Transit routes via DirectionsServiceProtocol (MKDirections under the hood).</br>
   • RouteInfo exposes distance, expected travel time, and categorized steps (walking, transit, general instructions) with SF Symbols.</br>
   • Clear the current route and handle errors gracefully (e.g., user location unavailable).</br>
• Saved Locations</br>
   • LocationType enum (home, work, custom) with display name and system icon.</br>
   • Add, remove, and navigate to saved locations.</br>
   • Hooks in place to persist later (e.g., SwiftData).</br>

<h2>Architecture</h2></br>
• MVVM with a coordinating ViewModel</br>
   • DirectionViewModel (Main coordinator)</br>
      • Lazily initializes MapViewModel, SearchViewModel, and RouteViewModel to keep startup fast.</br>
      • Forwards child state to the UI via @Published properties:</br>
         • region: MapCameraPosition</br>
         • searchResults: [MKMapItem]</br>
         • isSearching: Bool</br>
         • currentRoute: RouteInfo?</br>
         • isCalculatingRoute: Bool</br>
      • Delegates actions:</br>
         • requestLocationPermission()</br>
         • startLocationUpdates()</br>
         • centerOnUserLocation()</br>
         • searchLocation(query:)</br>
         • getDirections(to:destinationName:)</br>
         • navigateToSavedLocation(type:)</br>
         • clearRoute()</br>
   • MapViewModel</br>
      • Wraps LocationServiceProtocol publishers for location and authorization.</br>
      • Maintains userLocation and region (MapCameraPosition).</br>
      • Provides centerOnUserLocation() and setRegion(center:span:).</br>
   • SearchViewModel</br>
      • Wraps SearchServiceProtocol for async search.</br>
      • Emits searchResults, isSearching, and searchError.</br>
      • Formats placemark addresses.</br>
   • RouteViewModel</br>
      • Wraps DirectionsServiceProtocol for async transit route calculation.</br>
      • Emits currentRoute, isCalculatingRoute, and routeError.</br>
      • Ensures a user coordinate is available with a short timeout before routing.</br>
      • Manages saved locations and navigation by LocationType.</br>
• Models</br>
   • RouteInfo: wraps MKRoute and exposes distance, expectedTravelTime, and parsed TransitStep list.</br>
   • TransitStep: step details with formatted distance and type.</br>
   • TransitStepType: walking/transit/instruction with SF Symbols.</br>
   • LocationType: home/work/custom with display metadata.</br>
</br>
<h2>Tech Stack</h2></br>
• SwiftUI for UI and state binding</br>
• MapKit for maps, search, and directions</br>
• Combine for reactive bindings between services and view models</br>
• Swift Concurrency (async/await) for networked/async operations</br>
• Core Location (via LocationServiceProtocol) for permissions and updates</br>
• Dependency Injection for services (Search, Directions, Location)</br>
</br>

<h2>Project Structure</h2>
</br>(overview)</br>
• DirectionViewModel.swift􀰓 — main coordinator VM</br>
• ViewModels/</br>
   • MapViewModel.swift — location and camera</br>
   • SearchViewModel.swift — place search</br>
   • RouteViewModel.swift — routing and saved locations</br>
• Models/</br>
   • RouteInfo.swift􀰓 — route metadata and steps</br>
   • LocationType.swift􀰓 — saved location types</br>
• Services/ (not shown here)</br>
   • LocationServiceProtocol / LocationService.shared</br>
   • SearchServiceProtocol / SearchService.shared</br>
   • DirectionsServiceProtocol / DirectionsService.shared</br>
   • ServiceContainer.shared (for DI resolution)</br>

<h2>Getting Started</h2></br>
Prerequisites</br>
• Xcode 15 or later</br>
• iOS 17 / iPadOS 17 or later (adjust to your deployment target)</br>
• Swift 5.9+</br>

<h2>Setup</h2></br>
1. Clone</br>
git clone https://github.com/your-org/marty.git</br>
cd marty</br>
2. Open
Open Marty.xcodeproj or Marty.xcworkspace in Xcode.
3. Configure Info.plist
Add keys with meaningful descriptions:
• NSLocationWhenInUseUsageDescription
• NSLocationAlwaysAndWhenInUseUsageDescription (if you support always-on)
4. Build & Run
Use a device or simulator with location enabled. You can simulate location in Xcode (a metro Atlanta location is recommended, as that is the project's focus area).

Usage in the App</br>
• Permissions</br>
   • Call DirectionViewModel.requestLocationPermission() on first launch or when the map appears.</br>
• Location updates</br>
   • Call startLocationUpdates() to begin receiving user location.</br>
• Center map</br>
   • Call centerOnUserLocation() to move the camera to the user’s coordinate.</br>
• Search</br>
   • Call searchLocation(query:) to search; it will bias to the user’s region when available.</br>
• Directions</br>
   • Call getDirections(to:destinationName:) with a destination coordinate to compute a transit route.</br>
• Saved locations</br>
   • Call navigateToSavedLocation(type:) to route to a saved place (home/work/custom).</br>
   • Use addSavedLocation/removeSavedLocation on RouteViewModel to manage entries.</br>
• Clear route</br>
   • Call clearRoute() to remove the current route and errors.</br>

<h2>Design Notes</h2></br>
• Lazy Initialization</br>
   • Child view models are created only when needed to keep app launch responsive.</br>
• Binding Strategy</br>
   • DirectionViewModel forwards child @Published properties via Combine pipelines.</br>
• Location Availability</br>
   • Route calculation waits for a user coordinate (with timeout) to avoid hanging.</br>
• DI and Testability</br>
   • View models depend on protocols; swap in mock services for unit tests.</br>

*Roadmap*</br>
• Persist saved locations with SwiftData and sync across devices.</br>
• Add route options (avoid tolls/highways, transport modes).</br>
• Enhanced overlays and annotations for steps and stations.</br>
• Offline caching for recent searches and routes.</br>
• Swift Testing test suites for services and view models.</br>
</br>
*Troubleshooting*
• No location permission</br>
   • Ensure Info.plist contains required keys and the user has granted permission.</br>
• Location not updating</br>
   • Verify location services are enabled in device settings; startLocationUpdates() must be called.</br>
• Empty search results</br>
   • Check network connectivity; try a broader query; confirm region bias is appropriate.</br>
• Route fails</br>
   • Ensure a valid destination coordinate; confirm network connectivity and that transit is available in the selected region.</br>

<h3>Contributing</h3></br>
• Issues and pull requests are welcome. Please discuss major changes in an issue first.</br>
• Follow MVVM and DI patterns consistent with the current codebase.</br>

License
*TBD*

**Acknowledgments**</br>
• Built with SwiftUI, MapKit, and Combine.
• ❤️Thanks to Apple Developer Documentation and community examples for MapKit and Core Location❤️
