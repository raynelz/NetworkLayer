//
//  ApiService.swift
//  NetworkLayer
//
//  Created by Захар Литвинчук on 12.03.2025.
//

import Foundation

/// Модель ответа от сервера
public struct AuthorizationResponse: Decodable {
	/// ID юзера
	public let userID: String
	
	/// Токен доступа
	public let accessToken: String

	/// Обновляемый токен
	public let refreshToken: String
	
}

@MainActor
public protocol APIServiceType {
	func signIn(body: SignInRequest) async throws -> AuthorizationResponse
}

@MainActor
public final class APIService: APIServiceType {
	
	// MARK: - Private properties
	
	private let networkClient: NetworkClient
	private let baseURL: URL
	
	public init(
		networkClient: NetworkClient,
		baseURL: URL = URL(string: "https://eventify.website/api/v1/")!
	) {
		self.networkClient = networkClient
		self.baseURL = baseURL
	}
	
	private func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
		guard let url = URL(string: endpoint.path, relativeTo: baseURL) else {
			throw APIError.badUrl
		}
		
		let request = NetworkRequest(
			url: url,
			method: endpoint.method,
			headers: endpoint.headers,
			body: endpoint.body
		)
		
		return try await networkClient.sendRequest(request)
	}
	
	public func signIn(body: SignInRequest) async throws -> AuthorizationResponse {
		try await request(AuthEndpoint.signIn(body: body))
	}
}
