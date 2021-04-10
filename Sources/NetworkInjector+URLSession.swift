//
//  NetworkInjector+URLSession.swift
//  atlantis
//
//  Created by Nghia Tran on 10/24/20.
//  Copyright © 2020 Proxyman. All rights reserved.
//

import Foundation

#if canImport(Atlantis_Objc)
import Atlantis_Objc
#endif

extension NetworkInjector {

    func _swizzleURLSessionResumeSelector(baseClass: AnyClass) {
        // Prepare
        let selector = NSSelectorFromString("resume")
        guard let method = class_getInstanceMethod(baseClass, selector),
            baseClass.instancesRespond(to: selector) else {
            return
        }

        // 
        typealias NewClosureType =  @convention(c) (AnyObject, Selector) -> Void
        let originalImp: IMP = method_getImplementation(method)
        let block: @convention(block) (AnyObject) -> Void = {[weak self](me) in

            // call the original
            let original: NewClosureType = unsafeBitCast(originalImp, to: NewClosureType.self)
            original(me, selector)


            // If it's from Atlantis, skip it
            if let task = me as? URLSessionTask,
               task.isFromAtlantisFramework() {
                return
            }

            // Safe-check
            if let task = me as? URLSessionTask {
                self?.delegate?.injectorSessionDidCallResume(task: task)
            } else {
                assertionFailure("Could not get data from _swizzleURLSessionResumeSelector. It might causes due to the latest iOS changes. Please contact the author!")
            }
        }

        // Start method swizzling
        method_setImplementation(method, imp_implementationWithBlock(block))
    }

    /// urlSession(_:dataTask:didReceive:completionHandler:)
    /// https://developer.apple.com/documentation/foundation/urlsessiondatadelegate/1410027-urlsession
    func _swizzleURLSessionDataTaskDidReceiveResponse(baseClass: AnyClass) {
        if #available(iOS 13.0, *) {
            _swizzleURLSessionDataTaskDidReceiveResponseForIOS13AndLater(baseClass: baseClass)
        } else {
            _swizzleURLSessionDataTaskDidReceiveResponseForBelowIOS13(baseClass: baseClass)
        }
    }

    func _swizzleURLSessionDataTaskDidReceiveResponseForIOS13AndLater(baseClass: AnyClass) {
        // Prepare
        let selector = NSSelectorFromString("_didReceiveResponse:sniff:rewrite:")
        guard let method = class_getInstanceMethod(baseClass, selector),
            baseClass.instancesRespond(to: selector) else {
            return
        }

        // For safety, we should cast to AnyObject
        // To prevent app crashes in the future if the object type is changed
        typealias NewClosureType =  @convention(c) (AnyObject, Selector, AnyObject, Bool, Bool) -> Void
        let originalImp: IMP = method_getImplementation(method)
        let block: @convention(block) (AnyObject, AnyObject, Bool, Bool) -> Void = {[weak self](me, response, sniff, rewrite) in

            // call the original
            let original: NewClosureType = unsafeBitCast(originalImp, to: NewClosureType.self)
            original(me, selector, response, sniff, rewrite)

            // Safe-check
            if let task = me.value(forKey: "task") as? URLSessionTask,
               let response = response as? URLResponse {
                
                self?.delegate?.injectorSessionDidReceiveResponse(dataTask: task, response: response)
            } else {
                assertionFailure("Could not get data from _swizzleURLSessionDataTaskDidReceiveResponseForIOS13AndLater. It might causes due to the latest iOS changes. Please contact the author!")
            }
        }

        method_setImplementation(method, imp_implementationWithBlock(block))
    }

    private func _swizzleURLSessionDataTaskDidReceiveResponseForBelowIOS13(baseClass: AnyClass) {
        // Prepare
        let selector = NSSelectorFromString("_didReceiveResponse:sniff:")
        guard let method = class_getInstanceMethod(baseClass, selector),
            baseClass.instancesRespond(to: selector) else {
            return
        }

        typealias NewClosureType =  @convention(c) (AnyObject, Selector, AnyObject, Bool) -> Void
        let originalImp: IMP = method_getImplementation(method)
        let block: @convention(block) (AnyObject, AnyObject, Bool) -> Void = {[weak self](me, response, sniff) in

            // call the original
            let original: NewClosureType = unsafeBitCast(originalImp, to: NewClosureType.self)
            original(me, selector, response, sniff)

            // Safe-check
            if let task = me.value(forKey: "task") as? URLSessionTask,
               let response = response as? URLResponse {
                self?.delegate?.injectorSessionDidReceiveResponse(dataTask: task, response: response)
            } else {
                assertionFailure("Could not get data from _swizzleURLSessionDataTaskDidReceiveResponseForBelowIOS13. It might causes due to the latest iOS changes. Please contact the author!")
            }
        }

        method_setImplementation(method, imp_implementationWithBlock(block))
    }

    /// urlSession(_:dataTask:didReceive:)
    /// https://developer.apple.com/documentation/foundation/urlsessiondatadelegate/1411528-urlsession
    func _swizzleURLSessionDataTaskDidReceiveData(baseClass: AnyClass) {

        // Prepare
        let selector = NSSelectorFromString("_didReceiveData:")
        guard let method = class_getInstanceMethod(baseClass, selector),
            baseClass.instancesRespond(to: selector) else {
            return
        }

        typealias NewClosureType =  @convention(c) (AnyObject, Selector, AnyObject) -> Void
        let originalImp: IMP = method_getImplementation(method)
        let block: @convention(block) (AnyObject, AnyObject) -> Void = {[weak self](me, data) in

            // call the original
            let original: NewClosureType = unsafeBitCast(originalImp, to: NewClosureType.self)
            original(me, selector, data)

            // Safe-check
            if let task = me.value(forKey: "task") as? URLSessionTask,
               let data = data as? Data {
                self?.delegate?.injectorSessionDidReceiveData(dataTask: task, data: data)
            } else {
                assertionFailure("Could not get data from _swizzleURLSessionDataTaskDidReceiveData. It might causes due to the latest iOS changes. Please contact the author!")
            }
        }

        method_setImplementation(method, imp_implementationWithBlock(block))
    }

    /// urlSession(_:task:didCompleteWithError:)
    /// https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/1411610-urlsession
    func _swizzleURLSessionTaskDidCompleteWithError(baseClass: AnyClass) {
        // Prepare
        let selector = NSSelectorFromString("_didFinishWithError:")
        guard let method = class_getInstanceMethod(baseClass, selector),
            baseClass.instancesRespond(to: selector) else {
            return
        }

        typealias NewClosureType =  @convention(c) (AnyObject, Selector, AnyObject?) -> Void
        let originalImp: IMP = method_getImplementation(method)
        let block: @convention(block) (AnyObject, AnyObject?) -> Void = {[weak self](me, error) in

            // call the original
            let original: NewClosureType = unsafeBitCast(originalImp, to: NewClosureType.self)
            original(me, selector, error)

            // Safe-check
            if let task = me.value(forKey: "task") as? URLSessionTask {
                let error = error as? Error
                self?.delegate?.injectorSessionDidComplete(task: task, error: error)
            } else {
                assertionFailure("Could not get data from _swizzleURLSessionTaskDidCompleteWithError. It might causes due to the latest iOS changes. Please contact the author!")
            }
        }

        method_setImplementation(method, imp_implementationWithBlock(block))
    }
}

// MARK: - Upload

extension NetworkInjector {

    func _swizzleURLSessionUploadSelector(baseClass: AnyClass) {
        _swizzleURLSessionUploadFromFileSelector(baseClass)
        _swizzleURLSessionUploadFromFileWithCompleteHandlerSelector(baseClass)
        _swizzleURLSessionUploadFromDataSelector(baseClass)
        _swizzleURLSessionUploadFromDataWithCompleteHandlerSelector(baseClass)
    }

    private func _swizzleURLSessionUploadFromFileSelector(_ baseClass: AnyClass) {
        // Prepare
        let selector = NSSelectorFromString("uploadTaskWithRequest:fromFile:")
        guard let method = class_getInstanceMethod(baseClass, selector),
            baseClass.instancesRespond(to: selector) else {
            return
        }

        // For safety, we should cast to AnyObject
        // To prevent app crashes in the future if the object type is changed
        typealias NewClosureType =  @convention(c) (AnyObject, Selector, AnyObject, AnyObject?) -> AnyObject
        let originalImp: IMP = method_getImplementation(method)
        let block: @convention(block) (AnyObject, AnyObject, AnyObject?) -> AnyObject = {[weak self](me, request, fileURL) in

            // call the original
            let original: NewClosureType = unsafeBitCast(originalImp, to: NewClosureType.self)
            let task = original(me, selector, request, fileURL)

            // Safe-check
            if let task = task as? URLSessionTask,
               let request = request as? NSURLRequest,
               let fileURL = fileURL as? URL {
                let data = try? Data(contentsOf: fileURL)
                self?.delegate?.injectorSessionDidUpload(task: task, request: request, data: data)
            } else {
                assertionFailure("Could not get data from _swizzleURLSessionUploadSelector. It might causes due to the latest iOS changes. Please contact the author!")
            }
            return task
        }

        method_setImplementation(method, imp_implementationWithBlock(block))
    }

    private func _swizzleURLSessionUploadFromFileWithCompleteHandlerSelector(_ baseClass: AnyClass) {
        // Prepare
        let selector = NSSelectorFromString("uploadTaskWithRequest:fromFile:completionHandler:")
        guard let method = class_getInstanceMethod(baseClass, selector),
            baseClass.instancesRespond(to: selector) else {
            return
        }

        // For safety, we should cast to AnyObject
        // To prevent app crashes in the future if the object type is changed
        typealias NewClosureType =  @convention(c) (AnyObject, Selector, AnyObject, AnyObject?, AnyObject) -> AnyObject
        let originalImp: IMP = method_getImplementation(method)
        let block: @convention(block) (AnyObject, AnyObject, AnyObject?, AnyObject) -> AnyObject = {[weak self](me, request, fileURL, block) in

            // call the original
            let original: NewClosureType = unsafeBitCast(originalImp, to: NewClosureType.self)
            let task = original(me, selector, request, fileURL, block)

            // Safe-check
            if let task = task as? URLSessionTask,
               let request = request as? NSURLRequest,
                let fileURL = fileURL as? URL {
                let data = try? Data(contentsOf: fileURL)
                self?.delegate?.injectorSessionDidUpload(task: task, request: request, data: data)
            } else {
                assertionFailure("Could not get data from _swizzleURLSessionUploadSelector. It might causes due to the latest iOS changes. Please contact the author!")
            }

            return task
        }

        method_setImplementation(method, imp_implementationWithBlock(block))
    }

    private func _swizzleURLSessionUploadFromDataSelector(_ baseClass: AnyClass) {
        // Prepare
        let selector = NSSelectorFromString("uploadTaskWithRequest:fromData:")
        guard let method = class_getInstanceMethod(baseClass, selector),
            baseClass.instancesRespond(to: selector) else {
            return
        }

        // For safety, we should cast to AnyObject
        // To prevent app crashes in the future if the object type is changed
        typealias NewClosureType =  @convention(c) (AnyObject, Selector, AnyObject, AnyObject) -> AnyObject
        let originalImp: IMP = method_getImplementation(method)
        let block: @convention(block) (AnyObject, AnyObject, AnyObject) -> AnyObject = {[weak self](me, request, data) in

            // call the original
            let original: NewClosureType = unsafeBitCast(originalImp, to: NewClosureType.self)
            let task = original(me, selector, request, data)

            // Safe-check
            if let task = task as? URLSessionTask,
               let request = request as? NSURLRequest,
               let data = data as? Data {
                self?.delegate?.injectorSessionDidUpload(task: task, request: request, data: data)
            } else {
                assertionFailure("Could not get data from _swizzleURLSessionUploadSelector. It might causes due to the latest iOS changes. Please contact the author!")
            }

            return task
        }

        method_setImplementation(method, imp_implementationWithBlock(block))
    }

    private func _swizzleURLSessionUploadFromDataWithCompleteHandlerSelector(_ baseClass: AnyClass) {
        // Prepare
        let selector = NSSelectorFromString("uploadTaskWithRequest:fromData:completionHandler:")
        guard let method = class_getInstanceMethod(baseClass, selector),
            baseClass.instancesRespond(to: selector) else {
            return
        }

        // For safety, we should cast to AnyObject
        // To prevent app crashes in the future if the object type is changed
        typealias NewClosureType =  @convention(c) (AnyObject, Selector, AnyObject, AnyObject, AnyObject) -> AnyObject
        let originalImp: IMP = method_getImplementation(method)
        let block: @convention(block) (AnyObject, AnyObject, AnyObject, AnyObject) -> AnyObject = {[weak self](me, request, data, block) in

            // call the original
            let original: NewClosureType = unsafeBitCast(originalImp, to: NewClosureType.self)
            let task = original(me, selector, request, data, block)

            // Safe-check
            if let task = task as? URLSessionTask,
               let request = request as? NSURLRequest,
               let data = data as? Data {
                self?.delegate?.injectorSessionDidUpload(task: task, request: request, data: data)
            } else {
                assertionFailure("Could not get data from _swizzleURLSessionUploadSelector. It might causes due to the latest iOS changes. Please contact the author!")
            }

            return task
        }

        method_setImplementation(method, imp_implementationWithBlock(block))
    }
}

// MARK: - WebSocket

extension NetworkInjector {

    @available(iOS 13.0, *)
    func _swizzleURLSessionWebsocketSelector() {
        guard let websocketClass = NSClassFromString("__NSURLSessionWebSocketTask") else {
            print("[Atlantis][ERROR] Could not inject __NSURLSessionWebSocketTask!!")
            return
        }
        
        _swizzleURLSessionWebSocketSendWithCompleteHandlerSelector(websocketClass)
        _swizzleURLSessionWebSocketReceiveWithCompleteHandlerSelector(websocketClass)
    }

    @available(iOS 13.0, *)
    private func _swizzleURLSessionWebSocketSendWithCompleteHandlerSelector(_ baseClass: AnyClass) {

        // Prepare
        let selector = NSSelectorFromString("sendMessage:completionHandler:")
        guard let method = class_getInstanceMethod(baseClass, selector),
            baseClass.instancesRespond(to: selector) else {
            return
        }

        // For safety, we should cast to AnyObject
        // To prevent app crashes in the future if the object type is changed
        typealias NewClosureType =  @convention(c) (AnyObject, Selector, AnyObject, AnyObject) -> Void
        let originalImp: IMP = method_getImplementation(method)
        let block: @convention(block) (AnyObject, AnyObject, AnyObject) -> Void = {[weak self] (me, message, block) in

            // call the original
            let original: NewClosureType = unsafeBitCast(originalImp, to: NewClosureType.self)
            original(me, selector, message, block)

            // Safe-check
            if let task = me as? URLSessionTask {

                // As message is `NSURLSessionWebSocketMessage` and Xcode doesn't allow to cast it.
                // We use value(forKey:) to get the value
                let newMessage: URLSessionWebSocketTask.Message?
                if let strValue = message.value(forKey: "string") as? String {
                    newMessage = .string(strValue)
                } else if let dataValue = message.value(forKey: "data") as? Data {
                    newMessage = .data(dataValue)
                } else {
                    newMessage = nil
                }

                if let newMessage = newMessage {
                    self?.delegate?.injectorSessionWebSocketDidSendMessage(task: task, message: newMessage)
                }
            } else {
                assertionFailure("Could not get data from _swizzleURLSessionWebSocketSendWithCompleteHandlerSelector. It might causes due to the latest iOS changes. Please contact the author!")
            }
        }

        method_setImplementation(method, imp_implementationWithBlock(block))
    }

    @available(iOS 13.0, *)
    private func _swizzleURLSessionWebSocketReceiveWithCompleteHandlerSelector(_ baseClass: AnyClass) {

        // Prepare
        let selector = NSSelectorFromString("receiveMessageWithCompletionHandler:")
        guard let method = class_getInstanceMethod(baseClass, selector),
            baseClass.instancesRespond(to: selector) else {
            return
        }

        // For safety, we should cast to AnyObject
        // To prevent app crashes in the future if the object type is changed
        typealias NewClosureType =  @convention(c) (AnyObject, Selector, AnyObject) -> Void
        let originalImp: IMP = method_getImplementation(method)
        let block: @convention(block) (AnyObject, AnyObject) -> Void = {[weak self](me, handler) in

            // Pass the handler (AnyObject) to AtlantisHelper
            // We intentionally do this way because it's possible to use the class `NSURLSessionWebSocketMessage`
            // Xcode prohibits use this class `NSURLSessionWebSocketMessage` in Swift, so there is no way to cast it
            //
            // Pass it to Objective-C world would help it
            //
            let wrapperHandler = AtlantisHelper.swizzleWebSocketReceiveMessage(withCompleteHandler: handler, responseHandler: { (str, data, error) in
                //
                print("------- Get data \(str), \(data), \(error)")
            }) ?? handler

            // call the original
            let original: NewClosureType = unsafeBitCast(originalImp, to: NewClosureType.self)
            original(me, selector, wrapperHandler as AnyObject)


            // Safe-check
//            if let task = me as? URLSessionTask {
//                print("--")
////                self?.delegate?.injectorSessionWebSocketDidReceive(task: task, block: block)
//            } else {
//                assertionFailure("Could not get data from _swizzleURLSessionWebSocketReceiveWithCompleteHandlerSelector. It might causes due to the latest iOS changes. Please contact the author!")
//            }
        }

        method_setImplementation(method, imp_implementationWithBlock(block))
    }
}
