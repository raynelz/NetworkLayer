//
//  File.swift
//  NetworkLayer
//
//  Created by Захар Литвинчук on 13.03.2025.
//

import Foundation

protocol Endpoint {
	var path: String { get }
	var method: HTTPMethod { get }
	var body: Data? { get }
	var headers: [String: String] { get }
}
