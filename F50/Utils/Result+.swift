//
//  Result+.swift
//  Decentralized
//
//  Created by Nekilc on 2024/10/19.
//

import Foundation

/// A collection of convenient extensions to Swift’s native `Result`.
public extension Result {
    /// Create a `Result` from a throwing closure.
    ///
    /// - Parameter transform: A throwing closure that produces a value of type `Success`.
    /// - Returns: `.success` if the closure succeeds, otherwise `.failure` with the thrown error.
    init(_ transform: () throws -> Success) {
        do {
            self = try .success(transform())
        } catch let error as Failure {
            self = .failure(error)
        } catch {
            fatalError("\(error)")
        }
    }

    /// Create a `Result` from an async‑throwing closure.
    ///
    /// - Parameter transform: An async throwing closure that produces a value of type `Success`.
    init(_ transform: () async throws -> Success) async {
        do {
            self = try .success(await transform())
        } catch let error as Failure {
            self = .failure(error)
        } catch {
            fatalError("\(error)")
        }
    }

    /// Returns `true` if the result is a success.
    var isOk: Bool { if case .success = self { return true }; return false }

    /// Returns `true` if the result is a failure.
    var isErr: Bool { !isOk }

    /// Force‑unwraps the success value.
    ///
    /// - Returns: The wrapped `Success` value if the result is `.success`.
    /// - Note: Calls `preconditionFailure` when the result is a failure.
    func unwrap() -> Success {
        switch self {
        case .success(let value): return value
        case .failure(let error):
            preconditionFailure("Unwrapped a failure: \(error)")
        }
    }

    nonisolated func unwrapErr() -> Failure {
        switch self {
        case .success(let value):
            preconditionFailure("Unwrapped a success: \(value)")
        case .failure(let error):
            return error
        }
    }

    /// Returns the success value or a supplied default.
    func unwrapOr(_ defaultValue: Success) -> Success {
        switch self { case .success(let value): return value; case .failure: return defaultValue }
    }

    /// Transforms the failure value.
    func mapErr<NewFailure>(_ transform: (Failure) -> NewFailure) -> Result<Success, NewFailure> {
        switch self { case .success(let value): return .success(value); case .failure(let error): return .failure(transform(error)) }
    }

    /// Flat‑maps a success value to a new `Result`.
    func flatMap<NewSuccess>(_ transform: (Success) -> Result<NewSuccess, Failure>) -> Result<NewSuccess, Failure> {
        switch self { case .success(let value): return transform(value); case .failure(let error): return .failure(error) }
    }

    /// Flat‑maps a success value to a new `Result` asynchronously.
    func flatMapAsync<NewSuccess>(_ transform: @escaping (Success) async -> Result<NewSuccess, Failure>) async -> Result<NewSuccess, Failure> {
        switch self { case .success(let value): return await transform(value); case .failure(let error): return .failure(error) }
    }

    /// Maps a success value to a new `Result` asynchronously.
    func mapAsync<NewSuccess>(_ transform: @escaping (Success) async -> NewSuccess) async -> Result<NewSuccess, Failure> {
        switch self { case .success(let value): return .success(await transform(value)); case .failure(let error): return .failure(error) }
    }

    /// Handles the failure case by mapping it to a new `Result`.
    func orElse(_ transform: (Failure) -> Result<Success, Failure>) -> Result<Success, Failure> {
        switch self { case .success: return self; case .failure(let error): return transform(error) }
    }


    /// Returns the wrapped failure value or `nil` if it is a success.
    func err() -> Failure? { if case .failure(let error) = self { return error }; return nil }

    /// Maps the success value or returns a default on failure.
    func mapOr<T>(_ defaultValue: T, _ transform: (Success) -> T) -> T {
        switch self { case .success(let value): return transform(value); case .failure: return defaultValue }
    }

    /// Executes a side‑effect on the success value.
    @inlinable
    func inspect(_ transform: (Success) -> Void) -> Self {
        if case .success(let success) = self { transform(success) }
        return self
    }

    /// Executes a side‑effect on the failure value.
    @inlinable
    func inspectError(_ transform: (Failure) -> Void) -> Self {
        if case .failure(let error) = self { transform(error) }
        return self
    }

    /// Executes a side‑effect on the failure value asynchronously.
    func inspectErrorAsync(_ transform: @Sendable (Failure) async -> Void) async -> Self {
        if case .failure(let error) = self { await transform(error) }
        return self
    }

    /// Executes a side‑effect on the success value asynchronously.
    func inspectAsync(_ transform: (Success) async -> Void) async -> Self {
        if case .success(let success) = self { await transform(success) }
        return self
    }

    /// Optional: A `fold` helper for a single closure that handles both cases.
    func fold<T>(transform: (Result<Success, Failure>) -> T) -> T { transform(self) }
}
