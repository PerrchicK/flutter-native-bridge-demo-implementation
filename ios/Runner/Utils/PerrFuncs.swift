//
//  PerrFuncs.swift
//  SomeApp
//
//  Created by Perry on 2/12/16.
//  Copyright © 2016 PerrchicK. All rights reserved.
//

import UIKit
import ObjectiveC
//import OnGestureSwift
import LocalAuthentication
import Vision
import StoreKit


// MARK: - "macros"
func WIDTH(_ frame: CGRect?) -> CGFloat { return frame == nil ? 0 : (frame?.size.width)! }
func HEIGHT(_ frame: CGRect?) -> CGFloat { return frame == nil ? 0 : (frame?.size.height)! }

// MARK: - Global Methods
private let globalLoggerDateFormatter: DateFormatter = {
    let globalLoggerDateFormatter = DateFormatter()
    globalLoggerDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
    return globalLoggerDateFormatter
}()

class AppLogger {
    static func log(_ logMessage: Any, file: String = #file, function: String = #function, line: Int = #line) {
        if PerrFuncs.isReleaseMode() { return }

        NSLog("\(file.components(separatedBy: "/").last!) ➤ \(function.components(separatedBy: "(").first!) (\(line)): \(String(describing: logMessage))")
    }
}

public func 📗(_ logMessage: Any, file: String = #file, function: String = #function, line: Int = #line) {
    if PerrFuncs.isReleaseMode() { return }

    let timesamp = globalLoggerDateFormatter.string(from: Date())
    print("〈\(timesamp)〉\(file.components(separatedBy: "/").last!) ➤ \(function.components(separatedBy: "(").first!) (\(line)): \(String(describing: logMessage))")
}

public func 📗(_ logMessage: Any?, file: String = #file, function: String = #function, line: Int = #line) {
    var logMessage = logMessage
    if logMessage == nil {
        logMessage = "nil"
    }
    📗(logMessage!, file: file, function: function, line: line)
}

public func 📕(_ logMessage: Any, file:String = #file, function:String = #function, line:Int = #line) {
    if PerrFuncs.isReleaseMode() { return }

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
    let timesamp = formatter.string(from: Date())

    print("Error:〈\(timesamp)〉\(file.components(separatedBy: "/").last!) ➤ \(function.components(separatedBy: "(").first!) (\(line)): \(logMessage)")
}

// MARK: - Operators Overloading

// Allows this: { let temp = -3 ~ -80 ~ 5 ~ 10 }
precedencegroup Additive {
    associativity: left // Explanation: https://en.wikipedia.org/wiki/Operator_associativity
}
infix operator ~ : Additive // https://developer.apple.com/documentation/swift/operator_declarations

infix operator ^ : Additive // https://developer.apple.com/documentation/swift/operator_declarations

/// Inclusively raffles a number from `left` hand operand value to the `right` hand operand value.
///
/// For example: the expression `{ let random: Int =  -3 ~ 5 }` will declare a random number between -3 and 5.
/// - parameter left:   The value represents `from`.
/// - parameter right:  The value represents `to`.
///
/// - returns: A random number between `left` and `right`.
func ~ (left: Int, right: Int) -> Int { // Reference: http://nshipster.com/swift-operators/
    return PerrFuncs.random(from: left, to: right)
}

func ^ (left: Bool, right: Bool) -> Bool { // Reference: http://nshipster.com/swift-operators/
    return PerrFuncs.xor(arg1: left, arg2: right)
}

// MARK: - Class

/// The timestamp in milliseconds
typealias Timestamp = UInt64

typealias SharedPreferences = UserDefaults

open class PerrFuncs {
    /// Allows us to make AOP (Aspect-Oriented Programming) in iOS: https://github.com/steipete/Aspects
    /// Read more about AOP here: https://en.wikipedia.org/wiki/Aspect-oriented_programming
    static var originalViewAppeared: (originalImplementation: IMP, originalSelector: Selector)?

    static func onAppLoaded() {
    }
    
    private static var dispatchTokens: [String] = []
    static public func dispatchOnce(dispatchToken: String, block: @escaping () -> ()) {
        if let currentQueue = OperationQueue.current {
            OperationQueue.main.addOperation {
                guard !dispatchTokens.contains(dispatchToken) else { return }
                dispatchTokens.append(dispatchToken)
                currentQueue.addOperation {
                    block()
                }
            }
        } else {
            fatalError("Failed to find current queue!! 😱")
        }
    }

    class func copyToClipboard(textToCopy: String) -> Bool {
        UIPasteboard.general.string = textToCopy
        return stringFromClipboard() == textToCopy
    }

    class func stringFromClipboard() -> String? {
        return UIPasteboard.general.string
    }

    /// Returns a number between 0.0 - 100.0
    static func percentage(ofValue: Double, fromValue: Double) -> Double {
      if ofValue == 0 || fromValue == 0 { return 0 }

      return ofValue / fromValue * Double(100); // Example: 50 / 2000 * 100 == 2.5%
    }

    static func valueOf(percentage: Double, fromValue: Double) -> Double {
      let _percentage = max(0, percentage);
      return fromValue * _percentage / Double(100); // Example: 2000 * 2.5% / 100 == 50
    }

    @available(iOS 11.0, *)
    static public func readText(fromImage image: UIImage, block: @escaping (String?) -> ()) {
        guard let cgImage = image.cgImage else { block(nil); return }

        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: image.inferOrientation(),
            options: [VNImageOption: Any]()
        )
        
        let request = VNDetectTextRectanglesRequest(completionHandler: { request, error in
            DispatchQueue.main.async {
                //self?.handle(image: image, request: request, error: error)
                block(request.results?.first.debugDescription) // TODO: Please learn :)
            }
        })
        
        request.reportCharacterBoxes = true
        
        do {
            try handler.perform([request])
        } catch {
            📕(error as Any)
        }
    }

    // dispatch block on main queue
    static public func runOnBackground(afterDelay seconds: Double = 0.0, block: @escaping ()->()) {
        runBlockAfterDelay(afterDelay: seconds, onQueue: DispatchQueue.global(), block: block)
    }

    // dispatch block on main queue
    static public func runOnUiThread(afterDelay seconds: Double = 0.0, block: @escaping ()->()) {
        runBlockAfterDelay(afterDelay: seconds, block: block)
    }
    
    // runClosureAfterDelay
    static public func runBlockAfterDelay(afterDelay seconds: Double, onQueue: DispatchQueue = DispatchQueue.main, block: @escaping ()->()) {
        let delayTime = DispatchTime.now() + Double(Int64(seconds * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC) // 2 seconds delay before retry
        onQueue.asyncAfter(deadline: delayTime, execute: block)
    }
    
    static public func className(_ aClass: AnyClass) -> String {
        let className = NSStringFromClass(aClass)
        let components = className.components(separatedBy: ".")
        
        if components.count > 0 {
            return components.last!
        } else {
            return className
        }
    }

    static func isRunningOnSimulator() -> Bool {
        return false
    }

    static func isReleaseMode() -> Bool {
        return false //UtilsObjC.isReleaseMode()
    }

    static func isAppStoreVersion() -> Bool {
        return isReleaseMode()
    }

    #if !os(macOS) && !os(watchOS)
    /// This is an async operation (it needs an improvement - in case this method is being called again before the previous is completed?)
    public static func runBackgroundTask(withName taskName: String? = "Perry's BG task", block: @escaping (_ completionHandler: @escaping () -> ()) -> ()) {
        // Beware and use it: https://geek-is-stupid.github.io/2018-10-15-0x8badf00d-ate-bad-food/
        func endBackgroundTask(_ task: inout UIBackgroundTaskIdentifier) {
            UIApplication.shared.endBackgroundTask(task)
            task = UIBackgroundTaskIdentifier.invalid
        }

        // Interesting: https://github.com/Instabug/Instabug-iOS/issues/305#issuecomment-454023906
        var backgroundTaskId: UIBackgroundTaskIdentifier!
        backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: taskName, expirationHandler: {
            endBackgroundTask(&backgroundTaskId!)
        })
        
        let onDone = {
            endBackgroundTask(&backgroundTaskId!)
        }
        
        block(onDone)
    }
    #endif

    static var safeAreaInsets: UIEdgeInsets {
        let insets: UIEdgeInsets

        if #available(iOS 11.0, *) {
            insets = UIApplication.shared.keyWindow?.safeAreaInsets ?? UIEdgeInsets.zero
        } else {
            insets = UIEdgeInsets.zero
        }
        
        return insets
    }

    static var screenSize: CGSize {
        return UIScreen.main.bounds.size
    }

    static var isRunningOnMainThread: Bool {
        return isRunningOnUiThread
    }

    static var isRunningOnUiThread: Bool {
        return Thread.isMainThread
    }

    static func random(from: Int = 0, to: Int) -> Int {
        guard to != from else { return to }

        var _from: Int = from, _to: Int = to
        
        if to < from {// Error handling
            swap(&_to, &_from)
        }

        let randdomNumber: UInt32 = arc4random() % UInt32(_to - _from)
        return Int(randdomNumber) + _from
    }

    static func doesFileExistAtUrl(url: URL) -> Bool {
        return doesFileExistAtPath(path: url.absoluteString)
    }

    static func doesFileExistAtPath(path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path.replacingOccurrences(of: "file://", with: ""))
    }

    @discardableResult
    static func postRequest(urlString: String, jsonDictionary: [String: Any], httpHeaders: [String:String]? = nil, completion: @escaping ([String: Any]?) -> ()) -> URLSessionDataTask? {

        guard let url = URL(string: urlString) else { completion(nil); return nil }

        do {
            // here "jsonData" is the dictionary encoded in JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDictionary, options: .prettyPrinted)
            // create post request
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            if let httpHeaders = httpHeaders {
                for httpHeader in httpHeaders {
                    request.setValue(httpHeader.value, forHTTPHeaderField: httpHeader.key)
                }
            }
            
            //request.setValue("application/json", forHTTPHeaderField: "Content-Type") // OR: setValue
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            // insert json data to the request
            request.httpBody = jsonData
            request.timeoutInterval = 30


            let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
                if let error = error {
                    📗("Error: \(error)")
                    completion(nil)
                    return
                }
                guard let data = data else { completion(nil); return }
                
                do {
                    guard let result = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { completion(nil); return }
                    completion(result)
                } catch let deserializationError {
                    📗("Failed to parse JSON: \(deserializationError), data string: \(String(describing: String(data: data, encoding: String.Encoding.utf8)))")
                    completion(nil)
                }
            }
            
            task.resume()
            return task
        } catch let serializationError {
            📗("Failed to serialize JSON: \(serializationError)")
            completion(nil)
        }
        
        return nil
    }

    static public var deviceId: String {
        let uuid: String = UIDevice
            .current
            .identifierForVendor?
            .uuidString ?? ""
        return uuid
    }

    @discardableResult
    static func goToSettings() -> Bool {
        if let openSettingsUrl = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(openSettingsUrl) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(openSettingsUrl, options: [:], completionHandler: nil)
            } else {
                // Fallback on earlier versions
                UIApplication.shared.openURL(openSettingsUrl)
            }

            return true
        } else {
            📕("Failed getting url: \(UIApplication.openSettingsURLString)")
        }

        return false
    }

    static func share(image: UIImage, onViewController viewController: UIViewController) {
        share(item: image, onViewController: viewController)
    }

    static func share(item: Any, onViewController viewController: UIViewController) {
        let shareItems: Array = [item]
        let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivity.ActivityType.print, UIActivity.ActivityType.addToReadingList, UIActivity.ActivityType.postToVimeo]
        
        let isRunningOnIpad = UIDevice.current.userInterfaceIdiom == .pad

        if isRunningOnIpad {
            activityViewController.popoverPresentationController?.sourceView = viewController.view
            activityViewController.popoverPresentationController?.sourceRect = viewController.view.bounds
            // Dr. Emmett Brown : "(It means that) this damn thing doesn't work at all!"
        }

        viewController.present(activityViewController, animated: true, completion: nil)
    }

    /// Verifies whether the device has a configured local authentication AND the user is the owner. Reference: https://www.techotopia.com/index.php/Implementing_TouchID_Authentication_in_iOS_8_Apps
    static public func verifyDeviceOwner(callbackClosure: @escaping CallbackClosure<Bool?>) {
        let localAuthenticationContext = LAContext()
        let localAuthenticationLocalizedReasonString = "To proceed you must be the iPhone owner"
        
        var authError: NSError? // This exactly is how Swift's try-catch works (what happens behind the scenes)!
        if #available(iOS 11.0, *) { //if #available(iOS 8.0, macOS 10.12.1, *) {
            if localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
                switch localAuthenticationContext.biometryType {
                    case .faceID: // Device support Face ID
                        fallthrough
                    case .touchID: // Device supports Touch ID
                        localAuthenticationContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: localAuthenticationLocalizedReasonString) { success, evaluateError in
                            if success {
                                // User authenticated successfully, take appropriate action
                                UIAlertController.alert(title: "Alrighty then", message: "You're in 😃")
                                callbackClosure(true)
                            } else {
                                // User did not authenticate successfully, look at error and take appropriate action
                                UIAlertController.alert(title: "Hmmmm...", message: "Who are you again? 🤔")
                                callbackClosure(false)
                            }
                    }
                default: // Device has no biometric support
                    callbackClosure(nil)
                }
            } else {
                // Could not evaluate policy; look at authError and present an appropriate message to user
                callbackClosure(nil)
            }
        } else {
            // Fallback on earlier versions
            callbackClosure(nil)
        }
    }

    static func xor(arg1: Bool, arg2: Bool) -> Bool {
        return (arg1 && !arg2) || (arg2 && !arg1)
    }

    func pointerAddress(pointee: AnyObject) -> UnsafeMutableRawPointer {
        return Unmanaged<AnyObject>.passUnretained(pointee).toOpaque()
    }
}

// MARK: - Global Extensions

extension String {
    func jsonToDictionary() -> RawJsonFormat? {
        guard let data = self.data(using: .utf8) else { return nil }

        guard let dictionary = try? JSONSerialization.jsonObject(with: data, options: []) as? RawJsonFormat else { return nil }
        
        return dictionary
    }

    func length() -> Int {
        return self.count
    }

    func toEmoji() -> String {
        // "Hard" guard
        assert(self.length() > 0, "Cannot make emoji from an empty string")
        guard self.length() > 0 else { return self }
        
        var emoji = ""
        
        switch self {
        case "virus":
            emoji = "🤢"
        case "allergy":
            emoji = "🤧"
        case "fire":
            emoji = "🔥"
        // Just for fun
        case "yo":
            emoji = "👋🏻"
        case "ahalan":
            emoji = "👋🏾"
        case "ok":
            emoji = "👌"
        case "victory":
            fallthrough
        case "peace":
            emoji = "✌🏽"

            // Icons for menu titles
        case "UI":
            emoji = "👋🏻"
        case "Communication & Location":
        emoji = "🌏"
        case "GCD & Multithreading":
        emoji = "🚦"
        case "Notifications":
            emoji = "👻"
        case "Persistence & Data":
            emoji = "📂"
        case "Views & Animations":
            emoji = "👀"
        case "Operators Overloading":
            emoji = "🔧"
        case "Collection View":
            emoji = "📚"
        case "Images & Core Motion":
            emoji = "📷"
        case "Crazy Whack":
            emoji = "😜"

        default:
            📗("Error: Couldn't find emoji for string '\(self)'")
            break
        }
        
        📗("string to emoji: \(self) -> \(emoji)")
        
        return emoji
    }

    func localized(comment: String = "") -> String {
        return NSLocalizedString(self, comment: comment)
    }

    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    
    subscript (bounds: CountableRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ..< end]
    }
    
    subscript (bounds: CountableClosedRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ... end]
    }
    
    subscript (bounds: CountablePartialRangeFrom<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(endIndex, offsetBy: -1)
        return self[start ... end]
    }
    
    subscript (bounds: PartialRangeThrough<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ... end]
    }
    
    subscript (bounds: PartialRangeUpTo<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ..< end]
    }
    
    func toUrl() -> URL? {
        if isEmpty {
            return nil
        }

        return URL(string: self)
    }

    func toEncodedUrlString() -> String? {
        let allowedCharacterSet = CharacterSet(charactersIn: "!*'();@+$,#[] ").inverted
        return addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)
    }

    func addingFileSchemePrefix() -> String {
        guard !starts(with: "file://") else { return self }
        return "file://\(self)"
    }

    func removingFileSchemePrefix() -> String {
        return replacingOccurrences(of: "file://", with: "")
    }
}

extension Substring {
    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    
    subscript (bounds: CountableRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ..< end]
    }
    
    subscript (bounds: CountableClosedRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ... end]
    }
    
    subscript (bounds: CountablePartialRangeFrom<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(endIndex, offsetBy: -1)
        return self[start ... end]
    }
    
    subscript (bounds: PartialRangeThrough<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ... end]
    }
    
    subscript (bounds: PartialRangeUpTo<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ..< end]
    }
}

extension UIColor {
    static var appMainColor: UIColor {
        return UIColor(hexString: "ED8A00") //UIColor.orange
    }

    convenience init(hexString: String) {
        let hexString:NSString = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) as NSString
        let scanner = Scanner(string: hexString as String)
        
        if (hexString.hasPrefix("#")) {
            scanner.scanLocation = 1
        }
        
        var color:UInt32 = 0
        scanner.scanHexInt32(&color)
        
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        
        self.init(red:red, green:green, blue:blue, alpha:1)
    }
    
    func toHexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return NSString(format:"#%06x", rgb) as String
    }
}

extension UIImage {
    public func inferOrientation() -> CGImagePropertyOrientation {
        switch self.imageOrientation {
        case .up:
            return CGImagePropertyOrientation.up
        case .upMirrored:
            return CGImagePropertyOrientation.upMirrored
        case .down:
            return CGImagePropertyOrientation.down
        case .downMirrored:
            return CGImagePropertyOrientation.downMirrored
        case .left:
            return CGImagePropertyOrientation.left
        case .leftMirrored:
            return CGImagePropertyOrientation.leftMirrored
        case .right:
            return CGImagePropertyOrientation.right
        case .rightMirrored:
            return CGImagePropertyOrientation.rightMirrored
        }
    }

    func addMargin(withInsets insets: UIEdgeInsets) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(
            CGSize(width: self.size.width + insets.left + insets.right,
                   height: self.size.height + insets.top + insets.bottom), false, self.scale)
        let _ = UIGraphicsGetCurrentContext()
        let origin = CGPoint(x: insets.left, y: insets.top)
        self.draw(at: origin)
        let imageWithInsets = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imageWithInsets
    }

    public func rotated(byDegrees degrees: CGFloat) -> UIImage {
        //Calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        let t: CGAffineTransform = CGAffineTransform(rotationAngle: degrees * CGFloat.pi / 180)
        rotatedViewBox.transform = t
        let rotatedSize: CGSize = rotatedViewBox.frame.size
        //Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        //Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        //Rotate the image context
        bitmap.rotate(by: (degrees * CGFloat.pi / 180))
        //Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0)
        bitmap.draw(self.cgImage!, in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }

    public func fixedOrientation() -> UIImage {
        if imageOrientation == UIImage.Orientation.up {
            return self
        }
        
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        switch imageOrientation {
        case UIImage.Orientation.down, UIImage.Orientation.downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat.pi)
            break
        case UIImage.Orientation.left, UIImage.Orientation.leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi/2)
            break
        case UIImage.Orientation.right, UIImage.Orientation.rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -CGFloat.pi/2)
            break
        case UIImage.Orientation.up, UIImage.Orientation.upMirrored:
            break
        }
        
        switch imageOrientation {
        case UIImage.Orientation.upMirrored, UIImage.Orientation.downMirrored:
            transform.translatedBy(x: size.width, y: 0)
            transform.scaledBy(x: -1, y: 1)
            break
        case UIImage.Orientation.leftMirrored, UIImage.Orientation.rightMirrored:
            transform.translatedBy(x: size.height, y: 0)
            transform.scaledBy(x: -1, y: 1)
        case UIImage.Orientation.up, UIImage.Orientation.down, UIImage.Orientation.left, UIImage.Orientation.right:
            break
        }
        
        let ctx: CGContext = CGContext(data: nil,
                                       width: Int(size.width),
                                       height: Int(size.height),
                                       bitsPerComponent: self.cgImage!.bitsPerComponent,
                                       bytesPerRow: 0,
                                       space: self.cgImage!.colorSpace!,
                                       bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        ctx.concatenate(transform)
        
        switch imageOrientation {
        case UIImage.Orientation.left, UIImage.Orientation.leftMirrored, UIImage.Orientation.right, UIImage.Orientation.rightMirrored:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            break
        }
        
        let cgImage: CGImage = ctx.makeImage()!
        
        return UIImage(cgImage: cgImage)
    }

    static func fetchImage(withUrl urlString: String, completionClosure: CallbackClosure<UIImage?>?) {
        guard let url = URL(string: urlString) else { completionClosure?(nil); return }

        let backgroundQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        // Run on background thread:
        backgroundQueue.async {
            var image: UIImage? = nil
            
            // No matter what, make the callback call on the main thread:
            defer {
                // Run on UI thread:
                DispatchQueue.main.async {
                    completionClosure?(image)
                }
            }

            // The most (and inefficient) simple way to download a photo from the web (no timeout, error handling etc.)
            do {
                let data = try Data(contentsOf: url)
                image = UIImage(data: data)
            } catch let error {
                📕("Failed to fetch image from url: \(url)\nwith error: \(error)")
            }
        }
    }
    
    public func resized(toSize size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    public func resized(byMultiplying multiplier: CGFloat) -> UIImage? {
        let size = CGSize(width: self.size.width * multiplier, height: self.size.height * multiplier)
        return resized(toSize: size)
    }
    
    public func resized(toFitDimension dimension: CGFloat?) -> UIImage? {
        let minimumDimension: CGFloat = dimension ?? 1000
        let maximumDimension: CGFloat = max(self.size.width, self.size.height)
        let ratio = minimumDimension / maximumDimension

        return ratio < 1 ? resized(byMultiplying: ratio) : self
    }

}

extension UIImageView {
    func fetchImage(withUrl urlString: String, completionClosure: CallbackClosure<UIImageView>?) {
        guard urlString.length() > 0 else { completionClosure?(self); return }

        UIImage.fetchImage(withUrl: urlString) { (image) in
            defer {
                DispatchQueue.main.async {
                    completionClosure?(self)
                }
            }

            guard let image: UIImage = image else { return }

            self.image = image
            self.contentMode = .scaleAspectFit
        }
    }
}

// Declare a global var to produce a unique address as the assoc object handle
var SompApplicationHuggedProperty: UInt8 = 0

extension NSObject { // try extending 'AnyObject'...

    // Cool use: https://marcosantadev.com/swift-arrays-holding-elements-weak-references/
    var pointerAddress: UnsafeMutableRawPointer {
        return Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque()
    }
    
    /**
     << EXPERIMENTAL METHOD >>
     Attaches any object to this NSObject.
     This enables the same idea of user info, to every object that inherits from NSObject.
     */
    @discardableResult
    @objc func 😘(huggedObject: Any) -> Bool {
        //infix operator 😘 { associativity left precedence 140 }
        📗("\(self) is hugging \(huggedObject)")

        objc_setAssociatedObject(self, &SompApplicationHuggedProperty, huggedObject, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        return true
    }
    
    /**
     << EXPERIMENTAL METHOD >>
     Extracts the hugged object from an NSObject.
     */
    @objc func 😍() -> Any? { // 1
        guard let value = objc_getAssociatedObject(self, &SompApplicationHuggedProperty) else {
            return nil
        }
        
        return value as Any?
    }
}

extension UIViewController {
    class func instantiate(storyboardName: String? = nil) -> Self {
        return instantiateFromStoryboardHelper(storyboardName)
    }
    
    fileprivate class func instantiateFromStoryboardHelper<T: UIViewController>(_ storyboardName: String?) -> T {
        let storyboard = storyboardName != nil ? UIStoryboard(name: storyboardName!, bundle: nil) : UIStoryboard(name: "Main", bundle: nil)
        let identifier = NSStringFromClass(T.self).components(separatedBy: ".").last!
        let controller = storyboard.instantiateViewController(withIdentifier: identifier) as! T

        return controller
    }

    func mostTopViewController() -> UIViewController {
        guard let topController = self.presentedViewController else { return self }

        return topController.mostTopViewController()
    }

    @objc func perrfuncs_viewDidAppear(_ animated: Bool) {
        guard let originalViewAppeared = PerrFuncs.originalViewAppeared else { return }
        
        // Do some aspect programming in iOS 😃
        📗("View controller '\(self)' did appear...")
        
        let originalMethodClosure = unsafeBitCast(originalViewAppeared.originalImplementation, to: (@convention(c) (AnyObject, Selector, Bool) -> Void).self)
        return originalMethodClosure(self, originalViewAppeared.originalSelector, animated)
    }
}

extension UIApplication {
    static var mainWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.connectedScenes
                .filter({$0.activationState == .foregroundActive})
                .map({$0 as? UIWindowScene})
                .compactMap({$0})
                .first?.windows
                .filter({$0.isKeyWindow}).first
            
            return window
        } else {
            return UIApplication.shared.keyWindow
        }
    }

    static func mostTopViewController() -> UIViewController? {
        guard let topController = UIApplication.mainWindow?.rootViewController else { return nil }
        return topController.mostTopViewController()
    }
}

extension UIAlertController {

    /**
     Dismisses the current alert (if presented) and pops up the new one
     */
    @discardableResult
    func show(completion: (() -> Swift.Void)? = nil) -> UIAlertController? {
        guard let mostTopViewController = UIApplication.mostTopViewController() else { 📗("Failed to present alert [title: \(String(describing: self.title)), message: \(String(describing: self.message))]"); return nil }

        mostTopViewController.present(self, animated: true, completion: completion)

        return self
    }

    func withAction(_ action: UIAlertAction) -> UIAlertController {
        self.addAction(action)
        return self
    }

    func withInputText(configurationBlock: @escaping ((_ textField: UITextField) -> Void)) -> UIAlertController {
        self.addTextField(configurationHandler: { (textField: UITextField!) -> () in
            configurationBlock(textField)
        })

        return self
    }
    
    static func make(style: UIAlertController.Style, title: String, message: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        return alertController
    }

    static func makeActionSheet(title: String, message: String) -> UIAlertController {
        return make(style: .actionSheet, title: title, message: message)
    }

    static func makeAlert(title: String, message: String) -> UIAlertController {
        return make(style: .alert, title: title, message: message)
    }

    /**
     A service method that alerts with title and message in the top view controller
     
     - parameter title: The title of the UIAlertView
     - parameter message: The message inside the UIAlertView
     */
    static func alert(title: String, message: String, dismissButtonTitle:String = "OK", onGone: (() -> Void)? = nil) {
        UIAlertController.makeAlert(title: title, message: message).withAction(UIAlertAction(title: dismissButtonTitle, style: UIAlertAction.Style.cancel, handler: { (alertAction) -> Void in
            onGone?()
        })).show()
    }
}

protocol RoundCorneredView {
}

protocol RoundCorneredViewVisitor {
    func visit(view: UIView)
}

extension RoundCorneredViewVisitor {
    func visit(view: UIView) {
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
    }
}

extension UIView: RoundCorneredView {
    func accept(visitor: RoundCorneredViewVisitor) {
        visitor.visit(view: self)
    }
}

extension UIView {
    
    // Using a function since `var image` might conflict with an existing variable
    // (like on `UIImageView`)
    @available(iOS 10.0, *)
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }

    // Inspired from: https://stackoverflow.com/questions/25513271/how-to-initialize--a-custom-uiview-class-with-a-xib-file-in-swift
    class func instantiateFromNib<T>() -> T {
        let xibFileName: String = PerrFuncs.className(self.classForCoder().self)
        let nib: UINib = UINib(nibName: xibFileName, bundle: nil)
        let nibObject = nib.instantiate(withOwner: nil, options: nil).first
        return nibObject as! T
    }

    var isPresented: Bool {
        get {
            return !isHidden
        }
        set {
            isHidden = !newValue
        }
    }
    
    /**
     Hides the view if it's shown.
     Shows the view if it's hidden.
     */
    func toggleVisibility() {
        isPresented = !isPresented
    }

    @discardableResult
    func addBlurEffect(blurEffectStyle: UIBlurEffect.Style, withAlpha alpha: CGFloat = 1) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: blurEffectStyle)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.alpha = alpha
        addSubview(blurEffectView)
        blurEffectView.stretchToSuperViewEdges()
        
        return blurEffectView
    }
    
    func removeAllBlurEffects() {
        for subView in subviews {
            if subView is UIVisualEffectView {
                subView.animateFade(fadeIn: false, duration: 0.3, completion: { (done) in
                    subView.removeFromSuperview()
                })
            }
        }
    }

    // MARK: - Animations
    func animateScaleAndFadeOut(_ completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions(), animations: {
            // Core Graphics Affine Transformation: https://en.wikipedia.org/wiki/Affine_transformation
            self.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self.alpha = 0.0
        }, completion: { (completed) -> Void in
            completion?(completed)
        })
    }

    public func animateBounce(_ completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0.1, delay: 0, options: UIView.AnimationOptions.curveEaseIn, animations: { [weak self] () -> () in
            self?.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { (succeeded) -> Void in
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 6.0, options: UIView.AnimationOptions.curveEaseOut   , animations: { [weak self] () -> Void in
                self?.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }) { (succeeded) -> Void in
                completion?(succeeded)
            }
        }
    }

    public func animateFlip(fromRight: Bool = true, duration: TimeInterval = 1, doInTheMiddle: (() -> ())? = nil, completion:  ((Bool) -> Void)? = nil) {
        UIView.transition(with: self, duration: duration, options: fromRight ? .transitionFlipFromRight : .transitionFlipFromLeft, animations: {
            // Other animation?
        }, completion: completion)
        PerrFuncs.runOnUiThread(afterDelay: duration / 2) {
            doInTheMiddle?()
        }
    }

    static var BreathAnimationKey: String {
        return "BREATH_ANIMATION_KEY"
    }
    
    func animateBreath(play shouldPlay: Bool = true, duration: CFTimeInterval = 7) {
        if shouldPlay {
            let floatAnimation = CAKeyframeAnimation()
            floatAnimation.keyPath = "transform"
            
            let overshootScale = CATransform3DScale(layer.transform, 1.2, 1.2, 1.0)
            let startingScale = layer.transform
            
            floatAnimation.values = [startingScale, overshootScale, startingScale]
            floatAnimation.duration = duration
            floatAnimation.repeatCount = Float.greatestFiniteMagnitude
            
            //            floatAnimation.timingFunctions = [
            //                CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeOut),
            //                CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut),
            //                CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut),
            //                CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut),
            //                CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut)
            //            ]
            
            floatAnimation.isRemovedOnCompletion = false
            
            layer.add(floatAnimation, forKey: UIView.BreathAnimationKey)
        } else {
            layer.removeAnimation(forKey: UIView.BreathAnimationKey)
        }
    }

    public func animateNo(_ completion: CallbackClosure<Bool>? = nil) {
        /*
        let noAnimation = CAKeyframeAnimationWithClosure()
        noAnimation.keyPath = "position.x"
        
        noAnimation.values = [0, 10, -10, 10, 0]
        let keyTimes: [NSNumber] = [0, NSNumber(value: Float(1.0 / 6.0)), NSNumber(value: Float(3.0 / 6.0)), NSNumber(value: Float(5.0 / 6.0)), 1]
        noAnimation.keyTimes = keyTimes
        noAnimation.duration = 0.4
        
        noAnimation.isAdditive = true
        noAnimation.delegate = self
        noAnimation.isRemovedOnCompletion = false

        noAnimation.completionClosure = completion

        self.layer.add(noAnimation, forKey: ANIMATION_NO_KEY) // shake animation
         */

        // another implementation without using CAKeyframeAnimation:
        let originX = self.frame.origin.x

        UIView.animate(withDuration: 0.1, animations: { [weak self] () -> Void in
            self?.frame.origin.x = originX - 10
        }, completion: { done in
            UIView.animate(withDuration: 0.1, animations: { [weak self] () -> Void in
                self?.frame.origin.x = originX + 10
            }, completion: { done in
                UIView.animate(withDuration: 0.05, animations: { [weak self] () -> Void in
                    self?.frame.origin.x = originX
                    }, completion: { (done: Bool) in
                    completion?(done)
                })
            })
        })
    }

    public func animateMoveCenterTo(x: CGFloat, y: CGFloat, duration: TimeInterval = 1, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: {
            self.center.x = x
            self.center.y = y
        }, completion: completion)
    }
    
    public func animateZoom(zoomIn: Bool, duration: TimeInterval = 1, delay: TimeInterval = 0, completion: ((Bool) -> Void)? = nil) {
        if zoomIn {
            self.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
        }

        UIView.animate(withDuration: duration, delay: delay, animations: { () -> Void in
            if zoomIn {
                self.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            } else {
                self.frame.size = CGSize(width: 0.0, height: 0.0)
            }
            }, completion: { (finished) in
                self.show(show: zoomIn)
                completion?(finished)
        }) 
    }
    
    public func animateFade(fadeIn: Bool, duration: TimeInterval = 1, completion: ((Bool) -> Void)? = nil) {
        // Skip redundant calls
        guard (fadeIn == false && (alpha > 0 || isHidden == false)) || (fadeIn == true && (alpha == 0 || isHidden == true)) else { return }

        self.alpha = fadeIn ? 0.0 : 1.0
        self.show(show: true)
        UIView.animate(withDuration: duration, animations: {// () -> Void in
            self.alpha = fadeIn ? 1.0 : 0.0
        }, completion: { (finished) in
            self.show(show: fadeIn)
            completion?(finished)
        }) 
    }
    
    // MARK: - Property setters-like methods

    public func show(show: Bool, faded: Bool = false) {
        if faded {
            animateFade(fadeIn: show)
        } else {
            self.isPresented = show
        }
    }
    
    // MARK: - Property setters-like methods

    /**
    Recursively remove all receiver’s immediate subviews... and their subviews... and their subviews... and their subviews...
    */
    public func removeAllSubviews() {
        for subView in self.subviews {
            subView.removeAllSubviews()
        }

        //📗("Removing: \(self), bounds: \(bounds), frame: \(frame):")
        self.removeFromSuperview()
    }

    func beOval() {
//        frame.width = frame.height
        self.layer.cornerRadius = frame.width / 2
        self.layer.masksToBounds = true
    }

    func makeRoundedCorners(_ radius: CGFloat = 5) {
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }
    
    // MARK: - Constraints methods
    
    func stretchToSuperViewEdges(_ insets: UIEdgeInsets = UIEdgeInsets.zero) {
        // Validate
        guard let superview = superview else { fatalError("superview not set") }
        
        let leftConstraint = constraintWithItem(superview, attribute: .left, multiplier: 1, constant: insets.left)
        let topConstraint = constraintWithItem(superview, attribute: .top, multiplier: 1, constant: insets.top)
        let rightConstraint = constraintWithItem(superview, attribute: .right, multiplier: 1, constant: insets.right)
        let bottomConstraint = constraintWithItem(superview, attribute: .bottom, multiplier: 1, constant: insets.bottom)
        
        let edgeConstraints = [leftConstraint, rightConstraint, topConstraint, bottomConstraint]
        
        translatesAutoresizingMaskIntoConstraints = false

        superview.addConstraints(edgeConstraints)
    }
    
    func pinToSuperViewCenter(_ offset: CGPoint = CGPoint.zero) {
        // Validate
        assert(self.superview != nil, "superview not set")
        let superview = self.superview!
        
        let centerX = constraintWithItem(superview, attribute: .centerX, multiplier: 1, constant: offset.x)
        let centerY = constraintWithItem(superview, attribute: .centerY, multiplier: 1, constant: offset.y)
        
        let centerConstraints = [centerX, centerY]
        
        translatesAutoresizingMaskIntoConstraints = false
        superview.addConstraints(centerConstraints)
    }
    
    func pinToSuperViewBottom(_ offset: CGPoint = CGPoint.zero) {
        // Validate
        assert(self.superview != nil, "superview not set")
        let superview = self.superview!
        
        let bottomX = constraintWithItem(superview, attribute: .bottom, multiplier: 1, constant: offset.x)
        let bottomY = constraintWithItem(superview, attribute: .bottom, multiplier: 1, constant: offset.y)
        
        let bottomConstraints = [bottomX, bottomY]
        
        translatesAutoresizingMaskIntoConstraints = false
        superview.addConstraints(bottomConstraints)
    }

    func constraintWithItem(_ view: UIView, attribute: NSLayoutConstraint.Attribute, multiplier: CGFloat, constant: CGFloat) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: self, attribute: attribute, relatedBy: .equal, toItem: view, attribute: attribute, multiplier: multiplier, constant: constant)
    }

    /**
     Adds a transparent gradient layer to the view's mask.
     */
    func addTransparentGradientLayer() -> CALayer {
        let gradientLayer = CAGradientLayer()
        let normalColor = UIColor.white.withAlphaComponent(1.0).cgColor
        let fadedColor = UIColor.white.withAlphaComponent(0.0).cgColor
        gradientLayer.colors = [normalColor, normalColor, normalColor, fadedColor]
        
        // Hoizontal - commenting these two lines will make the gradient veritcal (haven't tried this yet)
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        
        gradientLayer.locations = [0.0, 0.4, 0.6, 1.0]
        gradientLayer.anchorPoint = CGPoint.zero

        self.layer.mask = gradientLayer
/*
        override func layoutSubviews() {
            super.layoutSubviews()
            
            transparentGradientLayer.bounds = self.bounds
        }
*/

        return gradientLayer
    }

    @discardableResult
    func addVerticalGradientBackgroundLayer(topColor: UIColor, bottomColor: UIColor) -> CALayer {
        let gradientLayer = CAGradientLayer()
        let topCGColor = topColor.cgColor
        let bottomCGColor = bottomColor.cgColor
        gradientLayer.colors = [topCGColor, bottomCGColor]
        gradientLayer.frame = frame
        layer.insertSublayer(gradientLayer, at: 0)

        return gradientLayer
    }

    func firstResponder() -> UIView? {
        var firstResponder: UIView? = self
        
        if isFirstResponder {
            return firstResponder
        }
        
        for subView in subviews {
            firstResponder = subView.firstResponder()
            if firstResponder != nil {
                return firstResponder
            }
        }
        
        return nil
    }
}

extension URL {
    func queryStringComponents() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        // Check for query string
        if let query = self.query {
            // Loop through pairings (separated by &)
            for pair in query.components(separatedBy: "&") {
                // Pull key, val from from pair parts (separated by =) and set dict[key] = value
                let components = pair.components(separatedBy: "=")
                dict[components[0]] = components[1] as AnyObject?
            }
        }
        
        return dict
    }
}

// Computed variable
var localStorage: UserDefaults {
    return UserDefaults.standard
}

extension NSError {
    static func create(errorDomain: String? = Bundle.main.bundleIdentifier, errorCode: Int, description: String, failureReason: String, underlyingError: Error?) -> NSError {
        var dict = [String: Any]()
        dict[NSLocalizedDescriptionKey] = description
        dict[NSLocalizedFailureReasonErrorKey] = failureReason

        if let underlyingError = underlyingError {
            dict[NSUnderlyingErrorKey] = underlyingError
        }

        return NSError(domain: errorDomain ?? "missing-domain", code: errorCode, userInfo: dict)
    }
}

extension Dictionary {
    func toJsonString() -> String? {
        let _objectDictionaryData: Data? = try? JSONSerialization.data(withJSONObject: self, options: [])

        guard let objectDictionaryData = _objectDictionaryData else { return nil }

        return String(data: objectDictionaryData, encoding: .utf8)
    }
}

public protocol DictionaryConvertible: Codable {
    // Starting from Swift 4, the mapping methods are genereated automatically behind the scenes
    init?(json: RawJsonFormat)
}

// Other considerations: https://stackoverflow.com/questions/29599005/how-to-convert-or-parse-swift-objects-to-json
public extension DictionaryConvertible {
    init?(json: RawJsonFormat) { return nil }
    
    static var decoder: JSONDecoder {
        get { return JSONDecoder() }
    }
    
    static var encoder: JSONEncoder {
        get { return JSONEncoder() }
    }
    
    static func fromDictionary<T: DictionaryConvertible>(objectDictionary: RawJsonFormat) -> T? {
        if let obj = T(json: objectDictionary) {
            return obj
        }
        
        let _objectDictionaryData: Data? = try? JSONSerialization.data(withJSONObject: objectDictionary, options: [])
        guard let objectDictionaryData = _objectDictionaryData else { return nil }
        guard let jsonString = String(data: objectDictionaryData, encoding: .utf8) else { return nil }
        
        return fromJson(jsonString: jsonString)
    }
    
    static func fromJson<T: DictionaryConvertible>(jsonString: String) -> T? {
        guard let jsonData = jsonString.data(using: .utf8) else { return nil }
        
        return try? Self.decoder.decode(T.self, from: jsonData)
    }
    
    func toJsonString() -> String? {
        let _objectData: Data? = try? Self.encoder.encode(self)
        guard let objectData = _objectData else { return nil }
        return String(data: objectData, encoding: .utf8)
    }
    
    func toDictionary() -> RawJsonFormat {
        let _objectData: Data? = try? Self.encoder.encode(self)
        guard let objectData = _objectData else { return [:] }
        
        guard let firebaseDictionary = try? JSONSerialization.jsonObject(with: objectData, options: JSONSerialization.ReadingOptions.allowFragments) as? RawJsonFormat else { return [:] }
        
        return firebaseDictionary
    }
}
