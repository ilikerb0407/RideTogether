//
//  JourneyView.swift
//  RideTogether
//
//  Created by Auto on 2024/12/19.
//

import SwiftUI
import MapKit
import UIKit

struct JourneyView: View {
    var body: some View {
        ZStack {
            // Map will be implemented using UIViewRepresentable
            // For now, using standard MKMapView until GPXMapView is available
            MapViewWrapper()
            
            // Overlay controls
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    // Controls here
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Map View Wrapper

struct MapViewWrapper: UIViewRepresentable {
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.mapType = .mutedStandard
        mapView.showsUserLocation = true
        
        // Set default region (Taipei)
        let center = CLLocationCoordinate2D(latitude: 25.042393, longitude: 121.56496)
        let span = MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: true)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Update map view if needed
    }
}

