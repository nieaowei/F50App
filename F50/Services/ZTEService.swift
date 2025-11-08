//
//  ZTEService.swift
//  F50
//
//  Created by Nekilc on 2025/9/21.
//

import Foundation

enum RequestBody {
    case none
    case json([String: Any])
    case form([String: String])
}

nonisolated protocol AutoCmds: Codable & Sendable{
    associatedtype CodingKeys: CaseIterable & RawRepresentable where CodingKeys.RawValue == String
    
    static func get(_ zteSvc: ZTEService) async throws -> Self
}

extension AutoCmds {
    static func get(_ zteSvc: ZTEService) async throws -> Self {
        
        let keys = Self.CodingKeys.allCases.map { $0.rawValue }
        let cmds = keys.compactMap { Cmds(rawValue: $0) }
        let res: Self = try await zteSvc.get_cmd(cmds: cmds).0
        return res
    }
}

public actor ZTEService {
    let host: URL
    let session: URLSession
    var headers: [String: String]
    
    public init(host: URL, headers: [String: String] = [:]) {
        self.host = host
        self.headers = headers
        
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage()
        config.httpCookieAcceptPolicy = .always
        session = URLSession(configuration: config)
    }
    
    private func makeRequest(path: String, method: String = "GET", body: RequestBody = .none) -> URLRequest {
        var url = host
        var requestBody: Data? = nil
        
        switch body {
        case .none:
            break
        case .json(let dict):
            requestBody = try? JSONSerialization.data(withJSONObject: dict, options: [])
            headers["Content-Type"] = "application/json"
        case .form(let params):
            if method.uppercased() == "GET" {
                var components = URLComponents(url: url.appendingPathComponent(path), resolvingAgainstBaseURL: false)
                components?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
                if let newURL = components?.url {
                    url = newURL
                }
            } else {
                let formString = params.map { "\($0.key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }.joined(separator: "&")
                requestBody = formString.data(using: .utf8)
                headers["Content-Type"] = "application/x-www-form-urlencoded"
            }
        }
        
        var request = URLRequest(url: url.appendingPathComponent(path))
        request.httpMethod = method
        request.httpBody = requestBody
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
    
    func sendRequest(path: String, method: String = "GET", body: RequestBody = .none) async throws -> (Data, URLResponse) {
        let request = makeRequest(path: path, method: method, body: body)
        return try await session.data(for: request)
    }
    
    private func toDictStrStr<Params: Encodable>(params: Params) throws -> [String: String] {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        let extrasJson = try encoder.encode(params)
        let jsonOj = try JSONSerialization.jsonObject(with: extrasJson) as? [String: Any]
        
        return jsonOj?.compactMapValues { "\($0)" } ?? [:]
    }
    
    func get_cmd<Resp: Decodable, Extras: Encodable>(cmds: [Cmds], extras: Extras = [String: String]()) async throws -> (Resp, URLResponse) {

        let defaultItems = [
            "isTest": "false",
            "multi_data": "1",
            "_": Date().timeIntervalSince1970.description,
            "cmd": cmds.map { $0.rawValue }.joined(separator: ","),
        ]
        let extraItems: [String: String] = try toDictStrStr(params: extras)
        
        let merged = defaultItems.merging(extraItems) { _, new in new }
        let (data, response) = try await sendRequest(path: "/goform/goform_get_cmd_process", method: "GET", body: .form(merged))
        #if DEBUG
        print(String(data: data, encoding: .utf8) ?? "")
        #endif
        return try (JSONDecoder().decode(Resp.self, from: data), response)
    }
    
    func get_cmd_by_keys<Resp: AutoCmds, Extras: Encodable>(extras: Extras? = [String: String]()) async throws -> (Resp, URLResponse) {
        let keys = Resp.CodingKeys.allCases.map { $0.rawValue }
        let cmds = keys.compactMap { Cmds(rawValue: $0) }
        return try await get_cmd(cmds: cmds, extras: extras)
    }
    
    func set_cmd<Params: Encodable, Resp: Decodable, Extras: Encodable>(goformId: GoFormIds, params: Params, extras: Extras? = [String: String]()) async throws -> (Resp, URLResponse) {
        let defaultItems = [
            "isTest": "false",
            "_": Date().timeIntervalSince1970.description,
            "goformId": goformId.rawValue,
        ]
        let paramItems: [String: String] = try toDictStrStr(params: params)
        
        let extraItems: [String: String] = try toDictStrStr(params: extras)
        
        let merged = defaultItems.merging(paramItems) { _, new in new }.merging(extraItems, uniquingKeysWith: { _, new in new })

        let (data, response) = try await sendRequest(path: "/goform/goform_set_cmd_process", method: "POST", body: .form(merged))
        return try (JSONDecoder().decode(Resp.self, from: data), response)
    }
}
