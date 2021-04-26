import XCTest
@testable import Mediater_Swift

class MyRequest : RequestProtocol {
    typealias TResponse = String
    
    public var var1: String
    public var var2: Int
    
    init(var1: String, var2: Int) {
        self.var1 = var1
        self.var2 = var2
    }
    
    convenience  init() {
        self.init(var1: "Convenience init", var2: 1)
    }
}

class MyRequestHandler : RequestHandlerProtocol {
    func handle<R>(request: R, completion: @escaping (R.TResponse) throws -> Void) throws where R : RequestProtocol {
        let request = request as! MyRequest
        try completion("\(request.var1) \(request.var2) evaluated" as! R.TResponse)
    }
    
    func canHandle<R>(request: R) -> Bool where R : RequestProtocol {
        return request is MyRequest
    }
}

class MyRequestPreHandler : RequestPreProcessorProtocol {
    func handle<R>(request: R, completion: @escaping (R) throws -> Void) throws where R : RequestProtocol {
        let requestCopy = request as! MyRequest
        requestCopy.var1 = "PreHandler"
        try completion(requestCopy as! R)
    }
    
    func canHandle<R>(request: R) -> Bool where R : RequestProtocol {
        return request is MyRequest
    }
    
    
}

class MyRequestPostHandler : RequestPostProcessorProtocol {
    func handle<R>(request: R, response: R.TResponse, completion: @escaping (R.TResponse) throws -> Void) throws where R : RequestProtocol {
        try completion("\(response) and postHandled" as! R.TResponse)
    }
    
    func canHandle<R>(request: R) -> Bool where R : RequestProtocol {
        return request is MyRequest
    }
    
    
}

final class Mediater_SwiftTests: XCTestCase {
    func testExample() {
        let request = MyRequest(var1: "Initial", var2: 1)
        let requestHandler = MyRequestHandler()
        let requestPreProcessor = MyRequestPreHandler()
        let requestPostProcessor = MyRequestPostHandler()
        let mediater = Mediater()
        mediater.registerHandler(handler: requestHandler)
        mediater.registerPreProcessor(processor: requestPreProcessor)
        mediater.registerPostProcessor(processor: requestPostProcessor)
        try? mediater.send(request: request) { result in
            NSLog(result)
            XCTAssert(result == "PreHandler 1 evaluated and postHandled")
        }
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
