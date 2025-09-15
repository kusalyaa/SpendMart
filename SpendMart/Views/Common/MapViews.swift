import SwiftUI
import MapKit

// MARK: - Tap-to-drop MKMapView (all gestures enabled)
struct SelectableMapView: UIViewRepresentable {
    @Binding var selectedCoordinate: CLLocationCoordinate2D?

    var center: CLLocationCoordinate2D
    var span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    var showsUserLocation: Bool = false
    var markerTint: UIColor = UIColor.systemBlue

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView(frame: .zero)
        map.mapType = .mutedStandard
        map.isZoomEnabled = true
        map.isScrollEnabled = true
        map.isRotateEnabled = true
        map.isPitchEnabled = true
        map.showsUserLocation = showsUserLocation
        map.delegate = context.coordinator

        map.setRegion(MKCoordinateRegion(center: center, span: span), animated: false)

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.cancelsTouchesInView = false // keep gestures working
        map.addGestureRecognizer(tap)

        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        // Keep region reasonable; don’t fight user’s current zoom/pan
        // Only update annotation if binding changed externally
        context.coordinator.markerTint = markerTint

        let current = map.annotations.compactMap { $0 as? MKPointAnnotation }.first?.coordinate
        if current?.latitude != selectedCoordinate?.latitude || current?.longitude != selectedCoordinate?.longitude {
            // refresh annotations
            map.removeAnnotations(map.annotations.filter { !($0 is MKUserLocation) })
            if let coord = selectedCoordinate {
                let ann = MKPointAnnotation()
                ann.coordinate = coord
                map.addAnnotation(ann)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, markerTint: markerTint)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: SelectableMapView
        var markerTint: UIColor

        init(_ parent: SelectableMapView, markerTint: UIColor) {
            self.parent = parent
            self.markerTint = markerTint
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let coord = mapView.convert(point, toCoordinateFrom: mapView)

            // Update binding
            parent.selectedCoordinate = coord

            // Drop/replace marker
            mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
            let ann = MKPointAnnotation()
            ann.coordinate = coord
            mapView.addAnnotation(ann)
        }

        // Marker style
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }
            let id = "marker"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.annotation = annotation
            view.markerTintColor = markerTint
            view.glyphImage = nil
            view.canShowCallout = false
            return view
        }
    }
}

// MARK: - Read-only MKMapView with a single pin (all gestures enabled)
struct ReadOnlyMapView: UIViewRepresentable {
    var coordinate: CLLocationCoordinate2D
    var span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    var markerTint: UIColor = UIColor.systemBlue

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView(frame: .zero)
        map.mapType = .mutedStandard
        map.isZoomEnabled = true
        map.isScrollEnabled = true
        map.isRotateEnabled = true
        map.isPitchEnabled = true
        map.delegate = context.coordinator

        map.setRegion(MKCoordinateRegion(center: coordinate, span: span), animated: false)

        let ann = MKPointAnnotation()
        ann.coordinate = coordinate
        map.addAnnotation(ann)

        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(markerTint: markerTint)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var markerTint: UIColor
        init(markerTint: UIColor) { self.markerTint = markerTint }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }
            let id = "readonly_marker"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.markerTintColor = markerTint
            view.canShowCallout = false
            return view
        }
    }
}
