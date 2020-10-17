//
//  NetworkManager.swift
//  Maps App
//
//  Created by Colin Murphy on 10/16/20.
//

import MapKit

//swiftlint:disable identifier_name

class NetworkManager {
        
    static let manager = NetworkManager()
    
    private init() {}
    
    func request<T: Decodable>(_ t: T.Type, withCoordinate coordinate: CLLocationCoordinate2D, completion: @escaping (Result<T, CustomError>) -> Void) {
        
        guard var urlComponents = URLComponents(string: "https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/findAddressCandidates") else { return }
        
        let parameters = [
            "f": "json",
            "category": "Coffee Shop",
            "location": "\(coordinate.longitude), \(coordinate.latitude)",
            "outFields": "Place_addr, PlaceName",
            "maxLocations": "50"
        ]
        
        var elements: [URLQueryItem] = []
        for (key, value) in parameters {
            elements.append(URLQueryItem(name: key, value: value))
        }
        urlComponents.queryItems = elements
        
        guard let url = urlComponents.url else { return }
        var request = URLRequest(url: url,
                                 cachePolicy: .useProtocolCachePolicy,
                                 timeoutInterval: 10.0)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                let response = response as? HTTPURLResponse, (response.statusCode == 200) else {
                    DispatchQueue.main.async {
                        completion(.failure(.serverError))
                    }
                return
            }
            do {
                let obj = try JSONDecoder().decode(T.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(obj))
                }
            } catch {
                print(error)
                DispatchQueue.main.async {
                    completion(.failure(.decodingFailed))
                }
            }
        }
        task.resume()
    }
}
