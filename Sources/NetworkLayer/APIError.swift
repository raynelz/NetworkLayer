//
//  File.swift
//  NetworkLayer
//
//  Created by Захар Литвинчук on 13.03.2025.
//

import Foundation

enum APIError: Error {
	case badUrl
	case invalidResponse(statusCode: Int)
	case decoding(Error)
	case network(Error)
}
