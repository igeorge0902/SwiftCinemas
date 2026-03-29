//
//  AppError.swift
//  SwiftCinemas
//
//  Created by GYORGY GASPAR on 2026. 03. 28..
//  Copyright © 2026 George Gaspar. All rights reserved.
//

enum AppError: Error {
    case networkFailure(underlying: Error)
    case httpError(statusCode: Int, message: String)
    case authRequired
    case activationRequired(voucherActive: Bool)
    case decodingFailed
}
