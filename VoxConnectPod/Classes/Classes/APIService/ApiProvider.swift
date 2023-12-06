//
//  ApiProvider.swift
//  VoxConnectLib
//
//  Created by Jayesh Mardiya on 06/12/23.
//

import Foundation
import RxSwift

class ApiProvider {
    
    func headRequest(url: URL, authHeader: String? = nil) -> Single<Data> {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "HEAD"
        if let header = authHeader {
            urlRequest.setAuthHeader(header)
        }
        
        return self.dataRequest(urlRequest)
    }
    
    /// Performs an HTTP DELETE Request to the URL using a serialized JSON Body
    /// - Parameters
    ///   - url:
    func deleteRequest(url: URL, authHeader: String? = nil) -> Single<Data> {
        
        var urlRequest = URLRequest(url: url)
        urlRequest.setContentTypeJson()
        urlRequest.httpMethod = "DELETE"
        if let header = authHeader {
            urlRequest.setAuthHeader(header)
        }
        
        return self.dataRequest(urlRequest)
    }
    
    /// Performs an HTTP Post Request to the URL using a serialized JSON Body
    /// - Parameters
    ///   - url:
    func postRequest(url: URL, body: Data, authHeader: String? = nil) -> Single<Data> {
        
        var urlRequest = URLRequest(url: url)
        urlRequest.setContentTypeJson()
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = body
        if let header = authHeader {
            urlRequest.setAuthHeader(header)
        }
        
        return self.dataRequest(urlRequest)
    }
    
    func getRequest(url: URL, authHeader: String? = nil) -> Single<Data> {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        if let header = authHeader {
            urlRequest.setAuthHeader(header)
        }
        
        return self.dataRequest(urlRequest)
    }
}

private extension ApiProvider {
    // TODO: Error handling should be refactored
    /// Performs a data task using the provided `URLRequest`
    ///
    /// - Parameters:
    ///   - request: URLRequest.
    /// - Returns
    ///   - ``Single`` of Serialized Response
    func dataRequest(_ request: URLRequest) -> Single<Data> {
        let session = URLSession(configuration: .default)
        
        //        print("Request URL: \(request.url!)")
        
        return Single.create { single  in
            
            session.dataTask(with: request) { (rawData, urlResponse, sessionError) in
                
                if let error = sessionError as NSError? {
                    if (error.domain == NSURLErrorDomain) && (error.code == NSURLErrorCancelled) {
                        
                        single(.failure(GenericError("API connection was cancelled")))
                        return
                    }
                    
                    if (error.domain == NSURLErrorDomain) && (error.code == NSURLErrorNotConnectedToInternet) {
                        
                        single(.failure(GenericError("Network connection error")))
                        return
                    }
                    
                    single(.failure(GenericError("Unknown error")))
                    return
                }
                
                guard let response = urlResponse as? HTTPURLResponse else {
                    single(.failure(GenericError("Invalid response")))
                    return
                }
                
                let code = response.statusCode
                switch code {
                case 200..<300:
                    if let d = rawData {
                        single(.success(d))
                    } else {
                        single(.failure(GenericError("Invalid response")))
                    }
                default:
                    single(.failure(GenericError("Request failure")))
                }
                
            }.resume()
            
            
            return Disposables.create()
        }
    }
}
