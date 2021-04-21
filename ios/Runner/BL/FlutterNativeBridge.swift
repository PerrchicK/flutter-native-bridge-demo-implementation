//
//  FlutterNativeBridge.swift
//  Runner
//
//  Created by Perry Shalom on 19/03/2019.
//  Copyright © 2019 My TimeBank. All rights reserved.
//

import Foundation
import Security

public typealias CallbackClosure<T> = ((T) -> Void)
public typealias RawJsonFormat = [AnyHashable: Any]

extension FlutterMethodCall {
    func arg<T>(forKey: String) -> T? {
        return (arguments as? RawJsonFormat)?[forKey] as? T
    }
}

extension AppDelegate {
    func onFlutterCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let resultString: Any?

        let 👍 = Constants.FlutterMethodChannel.SUCCESS_RESULT
        let 👎 = Constants.FlutterMethodChannel.FAILURE_RESULT
        switch call.method {
        case "save_in_secured_storage":
            if let keyValue = call.arguments as? RawJsonFormat,
               let key = keyValue.first?.key as? String,
               let value = keyValue.first?.value as? String {

                let result = KeyChain.save(key: key, data: Data(from: value))
                AppLogger.log(result)
                resultString = 👍
            } else {
                resultString = 👎
            }
        case "load_from_secured_storage":
            if let keyValue = call.arguments as? RawJsonFormat, let key = keyValue.first?.key as? String {
                let defaultValue = keyValue.first?.value as? String

                let value: String?

                if let receivedData = KeyChain.load(key: key) {
                    value = receivedData.to(type: String.self)
                    AppLogger.log("loaded: \(value ?? "")")
                } else {
                    value = nil
                }

                resultString = value ?? (defaultValue ?? "")
            } else {
                resultString = ""
            }
        default:
            AppLogger.log("Unhandled bridged Flutter method call: \(call.method)")
            resultString = Constants.FlutterMethodChannel.FAILURE_RESULT // Never return nil!
        }

        if let resultString = resultString {
            result(resultString)
        } else {
            // Otherwise it will be on the callback's responsibility
        }
    }
}

extension FlutterViewController {
    static var FlutterMethodChannelName: String = "com.example.MethodChannelDemo/native_channel"
    func observeMethodChannel(onFlutterCall: @escaping ((FlutterMethodCall, @escaping FlutterResult) -> Void)) {
        AppDelegate.shared.methodChannel.setMethodCallHandler(onFlutterCall)
    }

    func callFlutter(methodName: String, arguments: Any? = nil, callback: CallbackClosure<Any?>? = nil) {
        AppDelegate.shared.methodChannel.invokeMethod(methodName, arguments: arguments) { (callbackData) in
            AppLogger.log("method: \(methodName) returned: \(String(describing: callbackData))")
            callback?(callbackData)
        }
    }
}

struct Constants {
    struct FlutterMethodChannel {
        static let SUCCESS_RESULT = "1"
        static let FAILURE_RESULT = "0"
    }
}

class KeyChain {
    // From:
    // https://stackoverflow.com/questions/37539997/save-and-load-from-keychain-swift
    class func save(key: String, data: Data) -> OSStatus {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key,
            kSecValueData as String   : data ] as [String : Any]

        SecItemDelete(query as CFDictionary)

        return SecItemAdd(query as CFDictionary, nil)
    }

    class func load(key: String) -> Data? {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecMatchLimit as String  : kSecMatchLimitOne ] as [String : Any]

        var dataTypeRef: AnyObject? = nil

        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == noErr {
            return dataTypeRef as! Data?
        } else {
            return nil
        }
    }

    class func createUniqueID() -> String {
        let uuid: CFUUID = CFUUIDCreate(nil)
        let cfStr: CFString = CFUUIDCreateString(nil, uuid)

        let swiftString: String = cfStr as String
        return swiftString
    }
}

extension Data {

    init<T>(from value: T) {
        var value = value
        self.init(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }

    func to<T>(type: T.Type) -> T {
        return self.withUnsafeBytes { $0.load(as: T.self) }
    }
}
