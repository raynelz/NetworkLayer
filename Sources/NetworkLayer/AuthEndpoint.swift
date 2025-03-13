//
//  File.swift
//  NetworkLayer
//
//  Created by Захар Литвинчук on 13.03.2025.
//

import Foundation

public struct ValidateRequest: Encodable {
	let email: String
	let password: String
	
	public init(email: String, password: String) {
		self.email = email
		self.password = password
	}
}

public struct SignUpRequest: Encodable {
	let email: String
	let password: String
	let code: String
	
	public init(email: String, password: String, code: String) {
		self.email = email
		self.password = password
		self.code = code
	}
}

public struct SignInRequest: Encodable {
	let email: String
	let password: String
	
	public init(email: String, password: String) {
		self.email = email
		self.password = password
	}
}

enum AuthEndpoint: Endpoint {
	case validateEmail(body: ValidateRequest)
	case signUp(validationId: String, body: SignUpRequest)
	case signIn(body: SignInRequest)
	
	var path: String {
		switch self {
		case .validateEmail:
			"auth/validation"
		case let .signUp(validationId, _):
			"auth/registration/\(validationId)"
		case .signIn:
			"auth/login"
		}
	}
	
	var method: HTTPMethod {
		switch self {
		case .validateEmail, .signUp, .signIn:
			.POST
		}
	}
	
	var body: Data? {
		switch self {
		case .validateEmail(let body):
			try? JSONEncoder().encode(body)
		case let .signUp(_, body):
			try? JSONEncoder().encode(body)
		case .signIn(let body):
			try? JSONEncoder().encode(body)
		}
	}
	
	var headers: [String : String] {
		["Content-Type": "application/json"]
	}
}
