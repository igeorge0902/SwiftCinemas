//
//  AppDelegate.swift
//  SwiftLoginScreen
//
//  Copyright (c) 2015 Gaspar Gyorgy. MIT
//

import Contacts
import CoreData
import CoreLocation
import Realm
import SwiftyJSON
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

var expiryDate: Date?
@main
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {
    var window: UIWindow?
    var locationManager: CLLocationManager?
    var contactStore: CNContactStore?
    var socketManager: WebSocketManager?
    
    func application(_: UIApplication, willFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        setenv("CFNETWORK_DIAGNOSTICS", "3", 1)
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Nav, Tool bar appearance tweaks
        UINavigationBar.appearance().barStyle = .blackTranslucent
        UINavigationBar.appearance().barTintColor = UIColor.darkGray
        UINavigationBar.appearance().backgroundColor = UIColor.darkGray

        UIToolbar.appearance().barStyle = .blackTranslucent
        UITabBar.appearance().barStyle = .black
        UITabBar.appearance().isTranslucent = true
        UITabBar.appearance().tintColor = UIColor.white

        UIBarButtonItem.appearance().tintColor = UIColor.white
        UIButton.appearance().tintColor = UIColor.white

        contactStore = CNContactStore()
        contactStore!.requestAccess(for: .contacts) { succeeded, err in
            guard err == nil, succeeded else {
                return
            }
        }

        checkRealm()
        requestNotificationPermission()
        requestLocationPermission()
        loadLocations()
        setupFirebase()
        
        registerForPushNotifications()
        
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        print("dB location: \(urls[urls.count - 1] as URL)")
        
        socketManager = WebSocketManager()
        socketManager!.connect()
        
        return true
    }

    func applicationWillResignActive(_: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    // Request notification permission
    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                print("Notification permission granted.")
            } else {
                print("Notification permission denied.")
            }
        }
    }

    func requestLocationPermission() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self

        // First, request 'when in use' authorization
        locationManager?.requestWhenInUseAuthorization()

        // Then, upgrade to 'always' authorization (this must be done after 'when in use' is granted)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
                self.locationManager?.requestAlwaysAuthorization()
                self.locationManager!.allowsBackgroundLocationUpdates = true
            }
        }
    }

    // Trigger a notification when entering the geofence
    func locationManager(_: CLLocationManager, didEnterRegion region: CLRegion) {
        sendNotification(title: "You’re near, body!", body: "You are near to \(region.identifier).")
    }

    func locationManager(_: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            print("Location permission not determined yet")
        case .restricted, .denied:
            print("Location permission denied")
        case .authorizedWhenInUse:
            print("Granted 'When In Use' permission, requesting 'Always'...")
            locationManager?.requestAlwaysAuthorization()
        case .authorizedAlways:
            print("Granted 'Always' permission")
        @unknown default:
            break
        }
    }

    func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    func loadLocations() {
        var errorOnLogin: GeneralRequestManager?
        let geofenceManager = GeofenceManager()

        errorOnLogin = GeneralRequestManager(url: URLManager.mbooks("/locations"), errors: "", method: "GET", headers: nil, queryParameters: nil, bodyParameters: nil, isCacheable: "", contentType: "", bodyToPost: nil)

        errorOnLogin?.getResponse {
            (json: JSON, _: NSError?) in

            if let list = json["locations"].object as? NSArray {
                for i in 0 ..< list.count {
                    if let dataBlock = list[i] as? NSDictionary {
                        let name = dataBlock["name"] as? String
                        let latitude = dataBlock["latitude"] as! Double
                        let longitude = dataBlock["longitude"] as! Double

                        geofenceManager.addGeofence(latitude: latitude, longitude: longitude, radius: 500, identifier: name!)
                    }
                }
            }
        }
    }

    func checkRealm() {
        let p = NSPredicate(format: "url == %@", argumentArray: [URLManager.mbooks("/movies/paging")])

        // Query
        if let results = CachedResponse.objects(with: p) as AnyObject? {
            if results.count > 0 {
                for _ in 0 ..< results.count {
                    let data = results.object(at: 0) as? CachedResponse
                    if (data?.timestamp.addingTimeInterval(3600))! < Date() {
                        let realm = RLMRealm.default()
                        realm.beginWriteTransaction()
                        realm.delete(results.object(at: 0) as! RLMObject)

                        do {
                            try realm.commitWriteTransaction()

                        } catch {
                            print("Something went wrong!")
                        }
                    }
                }
            }
        }
    }
    
    func setupFirebase() {
      //  let environment = Bundle.main.object(forInfoDictionaryKey: "ENVIRONMENT") as? String ?? "prod"
      //  let plistFileName = environment == "dev" ? "GoogleService-Info-Dev" : "GoogleService-Info-Prod"
        
        let plistFileName = "FireBaseGoogleService-Info"
        if let filePath = Bundle.main.path(forResource: plistFileName, ofType: "plist"),
           let options = FirebaseOptions(contentsOfFile: filePath) {
            FirebaseApp.configure(options: options)
        } else {
            fatalError("Could not load Firebase configuration file.")
        }
    }

    func registerForPushNotifications() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device Token: \(token)") // Send this token to your server
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register: \(error.localizedDescription)")
    }
    
    func applicationWillTerminate(_: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: - Core Data stack
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "org.CoreData" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count - 1]
    }()

    func application(_: UIApplication, open _: URL, sourceApplication _: String?, annotation _: Any) -> Bool {
        false
    }

    func applicationDidReceiveMemoryWarning(_: UIApplication) {}
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("User interacted with notification: \(response.notification.request.content.userInfo)")
        completionHandler()
    }
}
