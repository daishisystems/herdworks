//
//  AuthUser.swift
//  HerdWorks
//
//  Created by Paul Mooney on 2025/10/14.
//


import Foundation

public struct AuthUser: Equatable, Sendable {
    public let uid: String
    public let email: String?

    public init(uid: String, email: String?) {
        self.uid = uid
        self.email = email
    }
}
