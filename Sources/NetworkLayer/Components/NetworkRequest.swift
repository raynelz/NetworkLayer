//
//  File.swift
//  NetworkLayer
//
//  Created by Захар Литвинчук on 13.03.2025.
//

import Foundation

public struct NetworkRequest {
	let url: URL
	let method: HTTPMethod
	let headers: [String: String]?
	let body: Data?
}
