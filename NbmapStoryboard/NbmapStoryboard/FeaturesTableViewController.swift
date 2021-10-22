import UIKit

class FeaturesTableViewController: UITableViewController{
    
    let features = [
        Feature(name: "Simple Maps", type: FeatureType.simpleMaps, description: "Display a simple map without any effects or features andded"),
        Feature(name: "Directions", type: FeatureType.directions, description: "Showcase the usage of Directions API"),
        //Feature(name: "Marker", type: FeatureType.marker, description: "How to add a marker and popup"),
        //Feature(name: "Polyline", type: FeatureType.polyline, description: "How to add a polyline and customise the style of polyline"),
        //Feature(name: "Polygon", type: FeatureType.polygon, description: "How to add a polygon and customise the style of polygon"),
        Feature(name: "Snap to Road", type: FeatureType.matching, description: "Showcase the usage of Snap to road API"),
        Feature(name: "Geocoding", type: FeatureType.geocoding, description: "Showcase the usage of the Geocoding API"),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return features.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let feature = features[indexPath.row]
        cell.textLabel?.text = feature.name
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)        
        let mainStoryBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
        guard let destinationViewController = mainStoryBoard.instantiateViewController(withIdentifier: "featureDetail") as? FeatureViewController else {
            return
        }
        destinationViewController.feature = features[indexPath.row]
        navigationController?.pushViewController(destinationViewController, animated: true)
        
        
    }
    
    

}
