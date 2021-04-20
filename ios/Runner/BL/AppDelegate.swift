import UIKit
import Flutter
import CoreData

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    var isFlutterReady: Bool = false {
        didSet {
            guard isFlutterReady else { return }

            PerrFuncs.runBlockAfterDelay(afterDelay: 0.5) { // Avoiding endless calls
                //AppDelegate.shared.callFlutterPendingMethods()
            }
        }
    }
    lazy var flutterPendingMethods: [MethodCall] = []
    
    lazy var globalImagePickerController: UIImagePickerController = UIImagePickerController()
    lazy var bridgeCallbacks: [CallbackClosure<String?>] = []

    lazy var flutterViewController: FlutterViewController = FlutterViewController.instantiate()
    lazy var methodChannel = FlutterMethodChannel(name: FlutterViewController.FlutterMethodChannelName, binaryMessenger: flutterViewController.binaryMessenger)
    private(set) var isConnectedToTheInternet = true {
        didSet {
            if isConnectedToTheInternet {
                //NotificationCenter.
            }
        }
    }

    static var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    // MARK: - Application Lifecycle Events

    override func application (_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? ) -> Bool {

        isFlutterReady = false

        // Was `GeneratedPluginRegistrant.register(with: self)`
        GeneratedPluginRegistrant.register(with: flutterViewController)
        flutterViewController.observeMethodChannel(onFlutterCall: onFlutterCall)

        window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = MainNavigationController(rootViewController: flutterViewController)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        super.application(application, handleEventsForBackgroundURLSession: identifier, completionHandler: completionHandler)
    }

    override func applicationWillTerminate(_ application: UIApplication) {
        //super.applicationWillTerminate(application)
    }
    
    override func applicationDidBecomeActive(_ application: UIApplication) {
        super.applicationDidBecomeActive(application)

        flutterViewController.callFlutter(methodName: "application_entered_foreground")
    }

    override func applicationDidEnterBackground(_ application: UIApplication) {
        super.applicationDidEnterBackground(application)

        flutterViewController.callFlutter(methodName: "application_entered_background")
    }

    // MARK: - Core Data stack

    // Lazy instantiation variable - will be allocated (and initialized) only once
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.perrchick.SomeApp" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "SomeApp", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        let url = applicationDocumentsDirectory.appendingPathComponent("SingleViewCoreData.sqlite")
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch let error {
            // Report any error we got.
            let wrappedError = NSError.create(errorDomain: "YOUR_ERROR_DOMAIN", errorCode: 9999, description: "Failed to initialize the application's saved data", failureReason: "There was an error creating or loading the application's saved data.", underlyingError: error)

            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator: NSPersistentStoreCoordinator = persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
}

class MethodCall {
    let methodName: String
    let arguments: Any?
    var callback: CallbackClosure<Any?>? = nil

    init(methodName: String, arguments: Any?, callback: CallbackClosure<Any?>? = nil) {
        self.methodName = methodName
        self.arguments = arguments
        self.callback = callback
    }
}

class MainNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isNavigationBarHidden = true
    }
}
