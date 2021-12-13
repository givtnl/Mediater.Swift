//
//  File.swift
//  
//
//  Created by Maarten Vergouwe on 16/07/2020.
//

import Foundation

public protocol RequestProtocol {
    associatedtype TResponse
}

open class NoResponseRequest: RequestProtocol {
    public typealias TResponse = Void
}
