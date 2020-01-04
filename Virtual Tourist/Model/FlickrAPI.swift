//
//  FlickrAPI.swift
//  Virtual Tourist
//
//  Created by Philip on 12/25/19.
//  Copyright © 2019 Philip Khegay. All rights reserved.
//

import Foundation

class FlickrAPI {
    
    var session = URLSession.shared
    
    class func getPhotosJSON(completion: @escaping (Bool, Error?, FlickrResponse?) -> Void, lat: Double, long: Double, page: Int) {
        var photo: FlickrResponse!
        let newURL = "\(Constants.BASE)&api_key=\(Constants.APIKEY)&lat=\(lat)&lon=\(long)&per_page=\(Constants.PHOTOSPERPAGE)&page=\(page)&format=json&nojsoncallback=1"
        print(newURL)
        let request = URLRequest(url: URL(string: newURL)!)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if error != nil {
                completion(false, error, nil)
                return
            }
            
            let decoder = JSONDecoder()

            do {
                photo = try decoder.decode(FlickrResponse.self, from: data!)
                completion(true, error, photo)
            } catch {
                print(error)
            }
        }
        task.resume()
    }
}
