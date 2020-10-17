//
//  CustomError.swift
//  Maps App
//
//  Created by Colin Murphy on 10/17/20.
//

import Foundation

enum CustomError: Error {
    
    case emptyTextField
    case serverError
    case decodingFailed
    case noLocationFound
}
