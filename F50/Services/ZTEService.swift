import Foundation
import OSLog

private nonisolated let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app.F50", category: "ZTEService")

enum RequestBody {
    case none
    case json([String: Any])
    case form([String: String])
}

nonisolated protocol AutoCmds: Codable & Sendable {
    associatedtype CodingKeys: CaseIterable & RawRepresentable where CodingKeys.RawValue == String

    static func get(_ zteSvc: ZTEService) async -> Result<Self, Error>
}

extension AutoCmds {
    static func get(_ zteSvc: ZTEService) async -> Result<Self, Error> {
        let keys = Self.CodingKeys.allCases.map { $0.rawValue }
        let cmds = keys.compactMap { Cmds(rawValue: $0) }
        let resp: Result<(Self, URLResponse), Error> = await zteSvc.get_cmd(cmds: cmds)
        return resp.map(\.0)
    }
}

public actor ZTEService {
    let host: URL
    let session: URLSession
    let headers: [String: String]

    public init(host: URL, headers: [String: String] = [:]) {
        self.host = host
        self.headers = headers

        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage()
        config.httpCookieAcceptPolicy = .always
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
    }

    private func makeRequest(path: String, method: String = "GET", body: RequestBody = .none) -> URLRequest {
        var url = host
        var requestBody: Data? = nil
        var headers = self.headers

        switch body {
        case .none:
            break
        case .json(let dict):
            requestBody = try? JSONSerialization.data(withJSONObject: dict, options: [])
            headers["Content-Type"] = "application/json"
        case .form(let params):
            if method == "GET" {
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

    func sendRequest(path: String, method: String = "GET", body: RequestBody = .none) async -> Result<(Data, URLResponse), Error> {
        let request = makeRequest(path: path, method: method, body: body)
        logger.debug("\(method) \(path)")
        do {
            let (data, response) = try await session.data(for: request)
            logger.debug("\(method) \(path) -> \(response)")
            return .success((data, response))
        } catch {
            logger.error("Request failed [\(method)] \(path): \(error.localizedDescription)")
            return .failure(error)
        }
    }

    private func toDictStrStr<Params: Encodable>(params: Params) -> Result<[String: String], Error> {
        let jsonData: Data
        switch Result { try JSONEncoder().encode(params) } {
        case .success(let data):
            jsonData = data
        case .failure(let err):
            return .failure(err)
        }

        guard let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return .failure(NSError(domain: "ZTEService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize params to dictionary"]))
        }

        return .success(dict.compactMapValues { "\($0)" })
    }

    func get_cmd<Resp: Decodable, Extras: Encodable>(cmds: [Cmds], extras: Extras = [String: String]()) async -> Result<(Resp, URLResponse), Error> {
        logger.debug("GET cmds: \(cmds.map(\.rawValue).joined(separator: ","))")

        let extraStrs: [String: String]
        switch toDictStrStr(params: extras) {
        case .success(let v): extraStrs = v
        case .failure(let err): return .failure(err)
        }

        let merged = [
            "isTest": "false",
            "multi_data": "1",
            "_": Date().timeIntervalSince1970.description,
            "cmd": cmds.map(\.rawValue).joined(separator: ","),
        ].merging(extraStrs) { _, new in new }

        let (data, response): (Data, URLResponse)
        switch await sendRequest(path: "/goform/goform_get_cmd_process", method: "GET", body: .form(merged)) {
        case .success(let v): (data, response) = v
        case .failure(let err): return .failure(err)
        }

        let decoded: Resp
        switch Result { try JSONDecoder().decode(Resp.self, from: data) } {
        case .success(let v): decoded = v
        case .failure(let err):
            return .failure(err)
        }

        logger.debug("GET response: \(String(data: data, encoding: .utf8) ?? "empty")")
        return .success((decoded, response))
    }

    func get_cmd_by_keys<Resp: AutoCmds>() async -> Result<(Resp, URLResponse), Error> {
        let keys = Resp.CodingKeys.allCases.map { $0.rawValue }
        let cmds = keys.compactMap { Cmds(rawValue: $0) }
        return await get_cmd(cmds: cmds)
    }

    func set_cmd<Params: Encodable, Resp: Decodable, Extras: Encodable>(goformId: GoFormIds, params: Params, extras: Extras = [String: String]()) async -> Result<(Resp, URLResponse), Error> {
        logger.debug("SET \(goformId.rawValue)")

        let paramStrs: [String: String]
        switch toDictStrStr(params: params) {
        case .success(let v): paramStrs = v
        case .failure(let err): return .failure(err)
        }

        let extraStrs: [String: String]
        switch toDictStrStr(params: extras) {
        case .success(let v): extraStrs = v
        case .failure(let err): return .failure(err)
        }

        let merged = [
            "isTest": "false",
            "_": Date().timeIntervalSince1970.description,
            "goformId": goformId.rawValue,
        ].merging(paramStrs) { _, new in new }.merging(extraStrs, uniquingKeysWith: { _, new in new })

        logger.debug("SET \(goformId.rawValue) params: \(paramStrs)")

        let (data, response): (Data, URLResponse)
        switch await sendRequest(path: "/goform/goform_set_cmd_process", method: "POST", body: .form(merged)) {
        case .success(let v): (data, response) = v
        case .failure(let err): return .failure(err)
        }

        let decoded: Resp
        switch Result { try JSONDecoder().decode(Resp.self, from: data) } {
        case .success(let v): decoded = v
        case .failure(let err): return .failure(err)
        }

        logger.debug("SET response: \(String(data: data, encoding: .utf8) ?? "empty")")
        return .success((decoded, response))
    }
}
