//
//  FlickrNetworkClient.swift
//  VirtualTourist
//
//  Created by ian robert blair on 2021/11/25.
//

import Foundation
import OSLog

class FlickrClient {
    
    static var defaultLog = Logger()
    static var apiKey = "42681d9a4364a54042c67a5f528a8790"
    static var apiSecret = "40d66340a7a0fe47"
    static var radius = 16  //Radiaus around latitude/longitude is 16km or 10 miles
    
    enum Endpoints {
        
        case searchLocation(Double,Double)
        case getPicture(String, String, String)
        
        var stringValue:String {
            switch self {
            //case .searchLocation(let longitude, let latitude): return "https://flickr.photos.search?api_key=\(apiKey)&radius=\(String(radius))&lon=\(longitude)&lat=\(latitude)"
    
            case .searchLocation(let longitude, let latitude): return "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(FlickrClient.apiKey)&lat=\(latitude)&lon=\(longitude)&radius=\(FlickrClient.radius)&format=json&nojsoncallback=1"
            case .getPicture(let serverId, let pictureId, let secret): return "https://live.staticflickr.com/{\(serverId)}/{\(pictureId)}_{\(secret)}.jpg" //returns 500pix pic
            }
        }
        
        var url:URL {
            return URL(string: stringValue)!
        }
    }
    
    class func searchByLocation(url: URL, completion: @escaping (SearchResponse?, Error?) -> Void) {
        self.defaultLog.info("searchByLocationCalled, \(url)")
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                completion(nil, error)
                return
            }
            let httpresponse = response as! HTTPURLResponse
            self.defaultLog.info("HTTP searchByLocation Response: \(httpresponse.statusCode)")
            
            let decoder = JSONDecoder()
            do {
                let downloadedPictures = try decoder.decode(SearchResponse.self, from: data)
                self.defaultLog.info("Pictures downloaded. \(data)")
                completion(downloadedPictures, nil)
            } catch {
                //defaultLog.info("Error decoding JSON. \(error.localizedDescription)")
                completion(nil, error)
            }
        }
        task.resume()
    }
    
    class func getPicture(url: URL, completion: @escaping (Data?, Error?) -> Void) {
        
    }
}
