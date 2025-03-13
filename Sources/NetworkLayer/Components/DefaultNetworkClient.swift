//
//  File.swift
//  NetworkLayer
//
//  Created by Захар Литвинчук on 13.03.2025.
//

import Foundation

@MainActor
public protocol NetworkClient {
	func sendRequest<T: Decodable>(_ request: NetworkRequest) async throws -> T
}

@MainActor
public final class DefaultNetworkClient: NetworkClient {
	
	// MARK: - Private properties
	
	private let urlSession: URLSession
	private let decoder: JSONDecoder
	private let isLoggingEnabled: Bool
	
	public init(
		urlSession: URLSession = .shared,
		decoder: JSONDecoder = JSONDecoder(),
		isLoggingEnabled: Bool = true
	) {
		self.urlSession = urlSession
		self.decoder = decoder
		self.isLoggingEnabled = isLoggingEnabled
	}
	
	public func sendRequest<T>(_ request: NetworkRequest) async throws -> T where T : Decodable {
		// Логирование запроса
		logRequest(request)
		
		var urlRequest = URLRequest(url: request.url)
		urlRequest.httpMethod = request.method.rawValue
		
		// Добавление заголовков
		if let headers = request.headers {
			for (key, value) in headers {
				urlRequest.setValue(value, forHTTPHeaderField: key)
			}
		}
		
		urlRequest.httpBody = request.body
		
		do {
			log("⬆️ Отправка запроса: \(request.url.absoluteString)")
			let startTime = Date()
			let (data, response) = try await urlSession.data(for: urlRequest)
			let timeInterval = Date().timeIntervalSince(startTime)
			log("⬇️ Получен ответ через \(String(format: "%.3f", timeInterval))с")
			
			// Логирование ответа
			logResponse(data: data, response: response)
			
			guard let httpResponse = response as? HTTPURLResponse else {
				log("❌ Ошибка: Неверный формат ответа (не HTTPURLResponse)")
				throw APIError.network(NSError(domain: "Invalid response", code: -1))
			}
			
			guard (200...299).contains(httpResponse.statusCode) else {
				log("❌ Ошибка HTTP статуса: \(httpResponse.statusCode)")
				if let responseString = String(data: data, encoding: .utf8) {
					log("📄 Тело ответа с ошибкой: \(responseString)")
				}
				throw APIError.invalidResponse(statusCode: httpResponse.statusCode)
			}
			
			log("🔄 Начало декодирования ответа в тип: \(T.self)")
			do {
				let decodedResponse = try decoder.decode(T.self, from: data)
				log("✅ Декодирование успешно завершено")
				return decodedResponse
			} catch {
				log("❌ Ошибка декодирования: \(error)")
				if let decodingError = error as? DecodingError {
					logDecodingError(decodingError, data: data)
				}
				throw APIError.decoding(error as? DecodingError ?? DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Unknown decoding error", underlyingError: error)))
			}
		} catch let urlError as URLError {
			log("❌ Ошибка URL-сессии: \(urlError.localizedDescription), код: \(urlError.code.rawValue)")
			throw APIError.network(urlError)
		} catch let apiError as APIError {
			// Пробрасываем APIError дальше без обертывания
			throw apiError
		} catch {
			log("❌ Неизвестная ошибка: \(error.localizedDescription)")
			throw APIError.network(error)
		}
	}
	
	// MARK: - Logging methods
	
	private func log(_ message: String) {
		if isLoggingEnabled {
			print("📡 NetworkClient: \(message)")
		}
	}
	
	private func logRequest(_ request: NetworkRequest) {
		guard isLoggingEnabled else { return }
		
		log("📤 ЗАПРОС ➡️ \(request.method.rawValue) \(request.url.absoluteString)")
		
		if let headers = request.headers, !headers.isEmpty {
			log("📋 Заголовки:")
			for (key, value) in headers {
				log("   \(key): \(value)")
			}
		}
		
		if let body = request.body {
			log("📦 Тело запроса (\(body.count) байт):")
			if let bodyString = String(data: body, encoding: .utf8) {
				log("   \(bodyString)")
			} else {
				log("   [Двоичные данные]")
			}
			
			// Попытка представить JSON в читаемом виде
			do {
				if let jsonObject = try JSONSerialization.jsonObject(with: body, options: []) as? [String: Any] {
					let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
					if let prettyString = String(data: prettyData, encoding: .utf8) {
						log("📝 JSON в читаемом виде:")
						log("   \(prettyString)")
					}
				}
			} catch {
				log("   Невозможно отформатировать JSON: \(error.localizedDescription)")
			}
		}
	}
	
	private func logResponse(data: Data, response: URLResponse) {
		guard isLoggingEnabled else { return }
		
		if let httpResponse = response as? HTTPURLResponse {
			log("📥 ОТВЕТ ⬅️ \(httpResponse.statusCode) \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))")
			log("📋 Заголовки ответа:")
			for (key, value) in httpResponse.allHeaderFields {
				log("   \(key): \(value)")
			}
		}
		
		log("📦 Тело ответа (\(data.count) байт):")
		if let responseString = String(data: data, encoding: .utf8) {
			if responseString.count > 1000 {
				log("   \(responseString.prefix(1000))... [обрезано, полный размер: \(responseString.count) символов]")
			} else {
				log("   \(responseString)")
			}
			
			// Попытка представить JSON в читаемом виде
			do {
				if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
					let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
					if let prettyString = String(data: prettyData, encoding: .utf8) {
						log("📝 JSON в читаемом виде:")
						if prettyString.count > 1000 {
							log("   \(prettyString.prefix(1000))... [обрезано]")
						} else {
							log("   \(prettyString)")
						}
					}
				}
			} catch {
				log("   Невозможно отформатировать JSON: \(error.localizedDescription)")
			}
		} else {
			log("   [Двоичные данные]")
		}
	}
	
	private func logDecodingError(_ error: DecodingError, data: Data) {
		guard isLoggingEnabled else { return }
		
		log("🔍 Детали ошибки декодирования:")
		
		switch error {
		case .typeMismatch(let type, let context):
			log("   Несоответствие типа: ожидался \(type), путь: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
			log("   Описание: \(context.debugDescription)")
			if let underlyingError = context.underlyingError {
				log("   Базовая ошибка: \(underlyingError)")
			}
			
		case .valueNotFound(let type, let context):
			log("   Значение не найдено: для типа \(type), путь: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
			log("   Описание: \(context.debugDescription)")
			if let underlyingError = context.underlyingError {
				log("   Базовая ошибка: \(underlyingError)")
			}
			
		case .keyNotFound(let key, let context):
			log("   Ключ не найден: \(key.stringValue), путь: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
			log("   Описание: \(context.debugDescription)")
			if let underlyingError = context.underlyingError {
				log("   Базовая ошибка: \(underlyingError)")
			}
			
		case .dataCorrupted(let context):
			log("   Поврежденные данные: путь: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
			log("   Описание: \(context.debugDescription)")
			if let underlyingError = context.underlyingError {
				log("   Базовая ошибка: \(underlyingError)")
			}
			
		@unknown default:
			log("   Неизвестная ошибка декодирования: \(error)")
		}
		
		// Попытка показать структуру JSON для отладки
		do {
			if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
				log("📊 Структура полученного JSON:")
				logJSONStructure(json, indent: 3)
			}
		} catch {
			log("   Невозможно проанализировать JSON для отладки: \(error)")
		}
	}
	
	private func logJSONStructure(_ json: Any, indent: Int = 0, maxDepth: Int = 3, currentDepth: Int = 0) {
		guard currentDepth <= maxDepth else {
			log(String(repeating: " ", count: indent) + "... [максимальная глубина]")
			return
		}
		
		let indentation = String(repeating: " ", count: indent)
		
		if let dictionary = json as? [String: Any] {
			for (key, value) in dictionary {
				let valueType = type(of: value)
				if value is [Any] || value is [String: Any] {
					log("\(indentation)\(key) [\(valueType)]:")
					logJSONStructure(value, indent: indent + 3, maxDepth: maxDepth, currentDepth: currentDepth + 1)
				} else {
					let valueString = String(describing: value).prefix(100)
					log("\(indentation)\(key) [\(valueType)]: \(valueString)")
				}
			}
		} else if let array = json as? [Any] {
			log("\(indentation)Массив [\(array.count) элементов]:")
			if !array.isEmpty {
				// Логируем только первые несколько элементов для больших массивов
				let itemsToLog = min(array.count, 3)
				for i in 0..<itemsToLog {
					log("\(indentation)[\(i)]:")
					logJSONStructure(array[i], indent: indent + 3, maxDepth: maxDepth, currentDepth: currentDepth + 1)
				}
				if array.count > itemsToLog {
					log("\(indentation)... и еще \(array.count - itemsToLog) элементов")
				}
			}
		} else {
			log("\(indentation)\(json)")
		}
	}
}
