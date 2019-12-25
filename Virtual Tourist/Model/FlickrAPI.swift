//
//  FlickrAPI.swift
//  Virtual Tourist
//
//  Created by Philip on 12/25/19.
//  Copyright © 2019 Philip Khegay. All rights reserved.
//

import Foundation

class FlickrAPI {
    
    struct Info {
        static var farm = 0
        static var serverID = 0
        static var ID = 0
        static var secret = ""
    }
    
    let APIKEY = "59489c25333eccab5c1b25e522870585"
    
    enum Endpoints {
        static let base = "https://www.flickr.com/photos/search/"
        
        case getPhotosJSON
        
        var stringValue: String {
            switch self {
            case .getPhotosJSON:
                return Endpoints.base + "59489c25333eccab5c1b25e522870585"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func getPhotosJSON(completion: @escaping (Bool, Error?, FlickrResponse?) -> Void) {
        var photo: FlickrResponse!
        let newURL = "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=883b1191a5a6afa5b15c49fdccf1cedc&user_id=cats&format=json&nojsoncallback=1"
        let request = URLRequest(url: URL(string: newURL)!)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if error != nil {
                completion(false, error, nil)
                return
            }
            
            let decoder = JSONDecoder()

            do {
                photo = try? decoder.decode(FlickrResponse.self, from: data!)
                completion(true, error, photo)
            } catch {
                print(error)
            }
        }
        task.resume()
    }
    
    
}