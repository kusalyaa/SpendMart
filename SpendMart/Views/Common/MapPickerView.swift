import SwiftUI
import MapKit
import CoreLocation
import UIKit

struct MapPickerView: View {
    var initialName: String = ""
    var onPicked: (_ name: String, _ coordinate: CLLocationCoordinate2D) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedCoord: CLLocationCoordinate2D? = nil
    @State private var placeName: String = ""
    @State private var isGeocoding = false

   
    private let defaultCenter = CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612)

    
    private var coordKey: String {
        guard let c = selectedCoord else { return "" }
        return String(format: "%.6f,%.6f", c.latitude, c.longitude)
    }

    var body: some View {
        VStack(spacing: 0) {
            SelectableMapView(
                selectedCoordinate: $selectedCoord,
                center: defaultCenter,
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03),
                showsUserLocation: false,
                markerTint: UIColor(Color.appBrand)
            )
            
            .onChange(of: coordKey) { _ in
                if let coord = selectedCoord {
                    reverseGeocode(coord)
                } else {
                    placeName = ""
                }
            }
            .ignoresSafeArea(edges: .bottom)

            VStack(alignment: .leading, spacing: 8) {
                Text(selectedCoord == nil
                     ? "Tap on the map to drop a pin"
                     : (placeName.isEmpty ? "Pinned location" : placeName))
                    .font(.headline)

                HStack {
                    Button("Use this location") {
                        if let coord = selectedCoord {
                            onPicked(placeName, coord)
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedCoord == nil)

                    Button("Clear") {
                        selectedCoord = nil
                        placeName = ""
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .navigationTitle("Pick Location")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func reverseGeocode(_ coord: CLLocationCoordinate2D) {
        isGeocoding = true
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(CLLocation(latitude: coord.latitude, longitude: coord.longitude)) { placemarks, _ in
            isGeocoding = false
            placeName = placemarks?.first.map { pm in
                [pm.name, pm.locality, pm.country].compactMap{$0}.joined(separator: ", ")
            } ?? ""
        }
    }
}
