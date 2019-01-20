//
//  ViewController.swift
//  GeoFencingRadiusSelection
//
//  Created by Gaurav Parvadiya on 2019-01-19.
//  Copyright © 2019 Gaurav Parvadiya. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController {

    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var touchView: UIView!
    @IBOutlet weak var radiusCircle: UIImageView!
    @IBOutlet weak var mapPin: UIImageView!
    
    var touchStartPoint = CGPoint.zero
    var previousTouchPoint = CGPoint.zero
    var lastXDiff: CGFloat = 0
    
    var rediusCircleWidth: CGFloat = 0
    var radiusCircleHeight: CGFloat = 0
    
    var currentRadius: CLLocationDistance = 200
    
    var currentCoordinate: CLLocationCoordinate2D?
    
    let locationManager = CLLocationManager()
    
    var circle = MKCircle()
    var mapCircles = [MKCircle]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        rediusCircleWidth = radiusCircle.frame.width
        radiusCircleHeight = radiusCircle.frame.height
    }
    
    func recenterToSelectedLocation() {
        guard let currentCoordinate = self.currentCoordinate else {
            return
        }
        let coordinatesInMapPoints = MKMapPoint(currentCoordinate)
        let distancesInMapPoints = currentRadius * MKMapPointsPerMeterAtLatitude(currentCoordinate.latitude)
        let newCoordinatesInMapPoints = MKMapPoint(x: coordinatesInMapPoints.x + distancesInMapPoints, y: coordinatesInMapPoints.y)
        let newCoordinate = newCoordinatesInMapPoints.coordinate
        let points = mapView.convert(newCoordinate, toPointTo: contentView)
        changeCircleImageSize(circlePoint: points)
    }
    
    func changeCircleImageSize(circlePoint: CGPoint) {
        radiusCircle.frame.size = CGSize(width: (circlePoint.x - mapView.center.x) * 2, height: (circlePoint.x - mapView.center.x) * 2)
        radiusCircle.center = mapView.center
    }
    
    func setMapRegion() {
        let distance: CLLocationDistance = abs(currentRadius) * 5
        let region = MKCoordinateRegion(center: currentCoordinate!, latitudinalMeters: distance, longitudinalMeters: distance)
        mapView.setRegion(region, animated: false)
    }
}

extension ViewController: UIGestureRecognizerDelegate {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first?.location(in: self.contentView) {
            if let viewTouched = self.contentView.hitTest(touch, with: event), viewTouched == touchView {
                touchStartPoint = touch
                
                previousTouchPoint = touchStartPoint
                lastXDiff = touchStartPoint.x - mapView.center.x
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first?.location(in: self.contentView) {
            if let viewTouched = self.contentView.hitTest(touch, with: event), viewTouched == touchView {
                
                let currentPoint = touch
                radiusCircle.isHidden = false
                
                let deltaRatio = abs((currentPoint.x - previousTouchPoint.x) / (contentView.frame.width / 2))
                if currentPoint.x - mapView.center.x < lastXDiff {
                    radiusCircleHeight *= (1 - deltaRatio)
                    rediusCircleWidth *= (1 - deltaRatio)
                    currentRadius *= abs((1 - Double(deltaRatio)))
                } else {
                    radiusCircleHeight *= (1 + deltaRatio)
                    rediusCircleWidth *= (1 + deltaRatio)
                    currentRadius *= abs((1 + Double(deltaRatio)))
                }
                recenterToSelectedLocation()
                lastXDiff = currentPoint.x - mapView.center.x
                previousTouchPoint = currentPoint
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        setMapRegion()
        recenterToSelectedLocation()
        //radiusCircle.isHidden = true
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        currentCoordinate = mapView.centerCoordinate
        setMapRegion()
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay.isKind(of: MKCircle.self) {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.strokeColor = #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1)
            circleRenderer.lineWidth = 0.5
            return circleRenderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            locationManager.stopUpdatingLocation()
            currentCoordinate = location.coordinate
            setMapRegion()
            recenterToSelectedLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error:: \(error)")
    }
}
