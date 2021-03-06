//
//  File.swift
//  
//
//  Created by Maarten Vergouwe on 16/07/2020.
//

import Foundation

public final class Mediater : MediaterProtocol {
    private static var instance = Mediater()
    
    public static var shared: MediaterProtocol { return Mediater.instance }

    var preProcessors = [Any]()
    var handlers = [Any]()
    var postProcessors = [Any]()

    public func registerPreProcessor(processor: RequestProcessorProtocol) {
        preProcessors.append(processor)
    }

    public func registerPostProcessor(processor: RequestProcessorProtocol) {
        postProcessors.append(processor)
    }

    public func registerHandler(handler: RequestProcessorProtocol) {
        handlers.append(handler)
    }

    public func send<R>(request: R) throws -> (R.TResponse) where R : RequestProtocol {
        var response: R.TResponse!
        let semaphore = DispatchSemaphore.init(value: 0)
        try sendAsync(request: request) { innerResponse in
            response = innerResponse
            semaphore.signal()
        }
        let dispatchResult = semaphore.wait(timeout: .now() + 60)
        if dispatchResult == DispatchTimeoutResult.timedOut {
            throw MediaterError.handlerNotFound
        }
        return response
    }

    public func sendAsync<R>(request: R, completion: @escaping (R.TResponse) -> Void) throws where R : RequestProtocol {
        let handler = self.handlers.first { handler in
            if let handler = handler as? RequestHandlerProtocol {
                return handler.canHandle(request: request)
            }
            return false
        }
        if let handler = handler as? RequestHandlerProtocol {
            let requestPreProcessors = preProcessors.filter { proc in
               if let proc = proc as? RequestPreProcessorProtocol {
                   return proc.canHandle(request: request)
               }
               return false
            } as! [RequestPreProcessorProtocol]

            let requestPostProcessors = postProcessors.filter { proc in
                if let proc = proc as? RequestPostProcessorProtocol {
                    return proc.canHandle(request: request)
                }
                return false
            } as! [RequestPostProcessorProtocol]

            var preCompletion = { (preResponse: R) throws in
                var postCompletion = { (postResponse: R.TResponse) throws in
                    completion(postResponse)
                }
                for postProc in requestPostProcessors.reversed() {
                    let nextCompletion = postCompletion
                    postCompletion = { postResponse in
                        try postProc.handle(request: preResponse, response: postResponse) { resp in
                            try nextCompletion(resp)
                        }
                    }
                }

                try handler.handle(request: preResponse) { response in
                    try postCompletion(response)
                }
            }

            for preProc in requestPreProcessors.reversed() {
                let nextCompletion = preCompletion
                preCompletion = { preResponse in
                    try preProc.handle(request: preResponse) { resp in
                        try nextCompletion(resp)
                    }
                }
            }

            try preCompletion(request)
        }
    }
}
