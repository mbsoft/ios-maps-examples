import UIKit
import Nbmap

class FeatureViewController: UIViewController, NGLMapViewDelegate {

    struct Config: Decodable {
        private enum CodingKeys: String, CodingKey {
            case NBMapKey, NBGeocodeKey
        }

        let NBMapKey: String
        let NBGeocodeKey: String
    }
    
    var feature: Feature?
    private let apiClient: NBAPIClient = NBAPIClient()
    var mapView: NGLMapView!
    var miniMapview: NGLMapView!
    var locs: [CLLocationCoordinate2D] = []
    
    func updateUI() {
        print("update")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView = NGLMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.setCenter(CLLocationCoordinate2D(latitude: 37.76218, longitude: -122.43817), zoomLevel: 12, animated: false)
        mapView.delegate = self
        
        // Set inset map View's center
        miniMapview = NGLMapView(frame: CGRect.zero)
        miniMapview.allowsScrolling = false
        miniMapview.allowsTilting = false
        miniMapview.allowsZooming = false
        miniMapview.allowsRotating = false
        miniMapview.compassView.isHidden = false
        miniMapview.logoView.isHidden = true
        miniMapview.attributionButton.tintColor = UIColor.clear
        miniMapview.layer.borderColor = UIColor.black.cgColor
        miniMapview.layer.borderWidth = 1
        miniMapview.setCenter(self.mapView.centerCoordinate,
                              zoomLevel: mapView.zoomLevel - 4, animated: false)
        miniMapview.translatesAutoresizingMaskIntoConstraints = false
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(sender:)))
        for recognizer in mapView.gestureRecognizers! where recognizer is UITapGestureRecognizer {
            singleTap.require(toFail: recognizer)
        }
        mapView.addGestureRecognizer(singleTap)
        
        view.addSubview(mapView)
        view.addSubview(miniMapview)
        installConstraints()

    }
    
    func parseConfig() -> Config {
        let url = Bundle.main.url(forResource: "Info", withExtension: "plist")!
        let data = try! Data(contentsOf: url)
        let decoder = PropertyListDecoder()
        return try! decoder.decode(Config.self, from: data)
    }
    
    @objc @IBAction func handleMapTap(sender: UITapGestureRecognizer) {
        // Convert tap location (CGPoint) to geographic coordinate (CLLocationCoordinate2D).
        let tapPoint: CGPoint = sender.location(in: mapView)
        let tapCoordinate: CLLocationCoordinate2D = mapView.convert(tapPoint, toCoordinateFrom: nil)
 
        mapView.setCenter(tapCoordinate, zoomLevel: mapView.zoomLevel, direction: mapView.direction, animated: true)

        switch feature?.type {
        case .directions:
            doRouting()
            break
        case .geocoding:
            revGeocode(tapCoordinate:tapCoordinate) { [weak self] (feature) in
                self?.addItemToMap(feature: feature)
            }
            break
        case .matching:
            revGeocode(tapCoordinate:tapCoordinate) { [weak self] (feature) in
                self?.addItemToMap(feature: feature)
            }
            break
        default:
            revGeocode(tapCoordinate:tapCoordinate) { [weak self] (feature) in
                self?.addItemToMap(feature: feature)
            }
            break
        }
    }
    
    func revGeocode(tapCoordinate:CLLocationCoordinate2D, withCompletion completion: @escaping ((NGLPointAnnotation) -> Void)) {
        let config = parseConfig()
        let request = URLRequest(url: URL(string: "https://api.nextbillion.io/h/revgeocode?at=\(tapCoordinate.latitude),\(tapCoordinate.longitude)&key=\(config.NBGeocodeKey)")!)

        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            guard error == nil else {
                preconditionFailure("Failed to load GeoJSON data: \(error!)")
            }

            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject],
                let items = json["items"] as? [[String: AnyObject]]
                else {
                    preconditionFailure("Failed to parse GeoJSON data")
            }

            DispatchQueue.main.async {
                completion(self.parseJSONItems(items: items))
            }
        }).resume()
    }
    
    // Reverse geocoding response has been received - parse it
    func parseJSONItems(items: [[String: AnyObject]]) -> NGLPointAnnotation{
        let feature = NGLPointAnnotation()
        for item in items {
            guard let label = item["address"] as? [String: AnyObject],
                  let title = label["label"] as? String else { continue }
            guard let coor = item["position"] as? [String: AnyObject],
                  let lat = coor["lat"] as? Double else { continue }
            guard let coor = item["position"] as? [String: AnyObject],
                  let lng = coor["lng"] as? Double else { continue }
            
            feature.title = title
            feature.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)

        }
        return feature
    }
    
    func addItemToMap(feature: NGLPointAnnotation) {
        mapView.selectAnnotation(feature, animated: true, completionHandler: nil)
    }
    
    func installConstraints() {
        if #available(iOS 11.0, *) {
            let safeArea = self.view.safeAreaLayoutGuide
            NSLayoutConstraint.activate([
                miniMapview.bottomAnchor.constraint(equalTo:
                    safeArea.bottomAnchor, constant: -1),
                miniMapview.trailingAnchor.constraint(equalTo:
                    safeArea.trailingAnchor, constant: -1),
                miniMapview.widthAnchor.constraint(equalTo:
                    safeArea.widthAnchor, multiplier: 0.33),
                miniMapview.heightAnchor.constraint(equalTo:
                    miniMapview.widthAnchor)
            ])
        } else {
            miniMapview.autoresizingMask = [.flexibleTopMargin,
                                            .flexibleLeftMargin,
                                            .flexibleRightMargin]
        }
    }
    
    @objc func draggedMap(panGestureRecognizer: UIPanGestureRecognizer) {
        // Check to see the state of the passed panGestureRocognizer
        if panGestureRecognizer.state == UIGestureRecognizer.State.began {
            print("pan start")
        }
    }
    
    func mapViewRegionIsChanging(_ mapView: NGLMapView) {
         miniMapview.setCenter(self.mapView.centerCoordinate,
         zoomLevel: mapView.zoomLevel - 4, animated: false)
        print("region change detected")
     }

    func mapView(_ mapView: NGLMapView, viewFor annotation: NGLAnnotation) -> NGLAnnotationView? {
        // This example is only concerned with point annotations.
        guard annotation is NGLPointAnnotation else {
            return nil
        }

        // For better performance, always try to reuse existing annotations. To use multiple different annotation views, change the reuse identifier for each.
        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "draggablePoint") {
            return annotationView
        } else {
            return DraggableAnnotationView(reuseIdentifier: "draggablePoint", size: 30)
        }
        
    }
    
    func mapView(_ mapView: NGLMapView, annotationCanShowCallout annotation: NGLAnnotation) -> Bool {
        print("annotation callout")
        return true
    }
    
    func mapView(_ mapView: NGLMapView, regionDidChangeAnimated animated: Bool) {
        print("change detected")
    }
    
    func mapView(_ mapView: NGLMapView, annotationView view: NGLAnnotationView,
                 didChangeDragstate newState:NGLAnnotationViewDragState, fromOldState oldState:NGLAnnotationViewDragState) {
        print("drag action detected")
        switch newState {
        case .starting:
            print("start DRAG")
        case .ending:
            print("ending DRAG")
        case .canceling:
            print("canceling DRAG")
        default: break;
        }
    }
    
    func mapView(_ mapView: NGLMapView, didFinishLoading style: NGLStyle) {
        switch feature?.type {
        case .directions:
            showDirections(mapView:mapView)
            break
        case .geocoding:
            showGeocoding(mapView:mapView)
            break;
        case .matching:
            showMatching(mapView:mapView)
            break
        default:
            loadSimpleMap(mapView:mapView)
        }
    }
    
    
    private func loadSimpleMap(mapView:NGLMapView) {
        
    }

    private func showGeocoding(mapView: NGLMapView) {
        
    }
    
    private func doRouting() {
        if let currentAnnotations = mapView.annotations {
            locs.removeAll()
            // we already have an O:D pair on the map - let's set coords based on these
            for (_, value) in currentAnnotations.enumerated() {
                let annotation = value
                if annotation.title == "Start" || annotation.title == "End" {
                    locs.append(annotation.coordinate)
                }
            }
            locs.reverse()
        }
        apiClient.getDirections(self.locs) { [self]
            resp in
            
            let first = resp?.routes.first;
            
            if first is NBRoute {
                let route:NBRoute? = first as? NBRoute
                let geometry = route?.geometry
                self.showToast(message: String(format:"%.1f min %.1f miles",
                                route!.duration/60.0,
                               route!.distance/1609.344),
                                font: .systemFont(ofSize: 15.0))
                let routeline = GeometryDecoder.covert(toFeature: geometry, precision:5)
                if let routeSource = mapView.style?.source(withIdentifier: "route-style-source") {
                    mapView.style?.removeLayer((mapView.style?.layer(withIdentifier: "route-layer"))!)
                    mapView.style?.removeSource(routeSource)
                    let routeSource = NGLShapeSource.init(identifier: "route-style-source", shape: routeline)
                    mapView.style?.addSource(routeSource)
                    let routeLayer = NGLLineStyleLayer.init(identifier: "route-layer", source: routeSource)
                    routeLayer.lineColor = NSExpression.init(forConstantValue: UIColor.systemTeal)
                    routeLayer.lineWidth = NSExpression.init(forConstantValue: 6)
                    mapView.style?.addLayer(routeLayer)
                } else {
                    let routeSource = NGLShapeSource.init(identifier: "route-style-source", shape: routeline)
                    mapView.style?.addSource(routeSource)
                    let routeLayer = NGLLineStyleLayer.init(identifier: "route-layer", source: routeSource)
                    routeLayer.lineColor = NSExpression.init(forConstantValue: UIColor.systemTeal)
                    routeLayer.lineWidth = NSExpression.init(forConstantValue: 6)
                    mapView.style?.addLayer(routeLayer)
                }

                mapView.setZoomLevel(12.0, animated: true)
                
                if let currentAnnotations = mapView.annotations {
                    mapView.removeAnnotations(currentAnnotations)
                }
                
                if (self.locs.count == 2) {
                    for (index, value) in locs.enumerated() {
                        //NGLPointAnnotation in
                        let annotation = NGLPointAnnotation()
                        annotation.coordinate = value
                        if (index == 0) {
                            annotation.title = "Start"
                        } else {
                            annotation.title = "End"
                        }
                        mapView.selectAnnotation(annotation, animated: true, completionHandler: nil)
                    }
                }

            }
        }
    }
    
    private func showDirections(mapView: NGLMapView) {
        // set a default origin:destination pair and do routing
        locs.append(CLLocationCoordinate2D(latitude: 37.78676, longitude: -122.41238))
        locs.append(CLLocationCoordinate2D(latitude: 37.77554, longitude: -122.46524))
        doRouting()
 
    }
    

    private func showMatching(mapView: NGLMapView) {
        let locations: [NBLocation] = [
            NBLocation().inti(withValues: 37.78513, lng: -122.41855),
            NBLocation().inti(withValues: 37.78621, lng: -122.40971),
            NBLocation().inti(withValues: 37.78845, lng: -122.40523),
        ]
        
        //let apiClient: NBAPIClient = NBAPIClient()
        apiClient.getMatching(locations) { resp in
            let geometry:String? = resp?.geometry[0] as? String
            let routeline = GeometryDecoder.covert(toFeature: geometry, precision:5)
            let routeSource = NGLShapeSource.init(identifier: "snapped-route-style-source", shape: routeline)
            mapView.style?.addSource(routeSource)
            let routeLayer = NGLLineStyleLayer.init(identifier: "snapped-route-layer", source: routeSource)
            routeLayer.lineColor = NSExpression.init(forConstantValue: UIColor.red)
            routeLayer.lineWidth = NSExpression.init(forConstantValue: 2)
            mapView.style?.addLayer(routeLayer)
        }
    }
    
    // NGLAnnotationView subclass
    class DraggableAnnotationView: NGLAnnotationView {
        init(reuseIdentifier: String, size: CGFloat) {
            super.init(reuseIdentifier: reuseIdentifier)

            // `isDraggable` is a property of NGLAnnotationView, disabled by default.
            isDraggable = true

            // This property prevents the annotation from changing size when the map is tilted.
            scalesWithViewingDistance = false

            // Begin setting up the view.
            frame = CGRect(x: 0, y: 0, width: size, height: size)

            backgroundColor = UIColor.systemTeal

            // Use CALayer’s corner radius to turn this view into a circle.
            layer.cornerRadius = size / 2
            layer.borderWidth = 1
            layer.borderColor = UIColor.white.cgColor
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.1
        }

        // These two initializers are forced upon us by Swift.
        override init(frame: CGRect) {
            super.init(frame: frame)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // Custom handler for changes in the annotation’s drag state.
        override func setDragState(_ dragState: NGLAnnotationViewDragState, animated: Bool) {
            super.setDragState(dragState, animated: animated)

            switch dragState {
            case .starting:
                print("Starting", terminator: "")
                startDragging()
            case .dragging:
                print(".", terminator: "")
            case .ending, .canceling:
                print("Ending")
                endDragging()
            case .none:
                break
            @unknown default:
                fatalError("Unknown drag state")
            }
        }

        func startDragging() {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [], animations: {
                self.layer.opacity = 0.8
                self.transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
            }, completion: nil)

            // Initialize haptic feedback generator and give the user a light thud.
            if #available(iOS 10.0, *) {
                let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
                hapticFeedback.impactOccurred()
            }

        }

        func endDragging() {
            transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [], animations: {
                self.layer.opacity = 1
                self.transform = CGAffineTransform.identity.scaledBy(x: 1, y: 1)
            }, completion: nil)
            
            // Give the user more haptic feedback when they drop the annotation.
            if #available(iOS 10.0, *) {
                let hapticFeedback = UIImpactFeedbackGenerator(style: .heavy)
                hapticFeedback.impactOccurred()
            }
            
        }
    }

}

extension UIViewController {

    func showToast(message : String, font: UIFont) {

        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-200, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 30.0, delay: 0.1, options: .curveEaseInOut, animations: {
            toastLabel.alpha = 0.25
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
}
