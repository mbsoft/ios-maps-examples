import Foundation

enum FeatureType {
    case simpleMaps, marker, polyline, polygon, directions, geocoding, distanceMatrix, matching
}

class Feature {
    let name: String
    let type: FeatureType
    let description: String
    
    init(name: String, type: FeatureType, description: String){
        self.name = name
        self.description = description
        self.type = type
    }
}
