//
//  BayliqApp.swift
//  Bayliq
//
//  Created by David Razmadze on 7/15/22.
//

import SwiftUI
import Firebase
import GoogleSignIn
import Network
import FirebaseMessaging
import LocalAuthentication

    @main
struct BayliqApp: App {
  
  // MARK: - Variables
  
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  @StateObject var viewRouter = ViewRouter()
  @StateObject private var vm = HomeViewModel()
  @StateObject private var currencyExchangeService = CurrencyExchangeService()
  @AppStorage("FirstTime") var firstTime = true
  @StateObject var viewModel = GoogleAuthenticationViewModel()
    @StateObject var networkMonitor = NetworkMonitor()
    @State private var isUnlocked = false
    @State private var isAppOpened = false
    @AppStorage("BiometricLogin") private var BiometricLogin = false
    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            if viewRouter.isLoggedIn == false {
                // ✅ If the user is logged in and is verified, go to Main View
                if (Auth.auth().currentUser != nil && ((Auth.auth().currentUser?.isEmailVerified) != false) && viewRouter.currentPage != .deleteAccountPage) || viewModel.state == .signedIn {
                    if BiometricLogin {
                        VStack{
                            if isUnlocked == true && BiometricLogin == true && isAppOpened == true {
                                
                                MainView().environmentObject(viewRouter).environmentObject(vm).dynamicTypeSize(.medium)
                                    .fullScreenCover(isPresented: $firstTime) {
                                        WalkthroughView(manager: FirestoreManager()).dynamicTypeSize(.medium)
                                            .environmentObject(networkMonitor)
                                    }.environmentObject(currencyExchangeService)
                                    .onAppear{
                                        viewRouter.isLoggedIn = true
                                    }
                            }else if isAppOpened && isUnlocked == false && BiometricLogin {
                                // ❌ Go to Auth Flow
                                ViewManager().environmentObject(viewRouter).environmentObject(vm).dynamicTypeSize(.medium)
                            }
                        }.onAppear{
                            if isAppOpened == false{
                                let biometricIDAuth = BiometricIDAuth()
                                
                                biometricIDAuth.canEvaluate { (canEvaluate, _, canEvaluateError) in
                                    guard canEvaluate else {
                                        // Face ID/Touch ID may not be available or configured
                                        isUnlocked = false
                                        isAppOpened = true
                                        return
                                    }
                                    
                                    biometricIDAuth.evaluate {  (success, error) in
                                        guard success else {
                                            // Face ID/Touch ID may not be configured
                                            isUnlocked = false
                                            isAppOpened = true
                                            return
                                        }
                                        //already logged in
                                        isUnlocked = true
                                        isAppOpened = true
                                    }
                                }
                            }
                        }
                    }else if isAppOpened == true && isUnlocked == true && BiometricLogin == true{
                        MainView().environmentObject(viewRouter).environmentObject(vm).dynamicTypeSize(.medium)
                            .fullScreenCover(isPresented: $firstTime) {
                                WalkthroughView(manager: FirestoreManager()).dynamicTypeSize(.medium)
                                    .environmentObject(networkMonitor)
                            }.environmentObject(currencyExchangeService)
                            .onAppear{
                                viewRouter.isLoggedIn = true
                            }
                    }else if BiometricLogin == false{
                        MainView().environmentObject(viewRouter).environmentObject(vm).dynamicTypeSize(.medium)
                            .fullScreenCover(isPresented: $firstTime) {
                                WalkthroughView(manager: FirestoreManager()).dynamicTypeSize(.medium)
                                    .environmentObject(networkMonitor)
                            }.environmentObject(currencyExchangeService)
                            .onAppear{
                                viewRouter.isLoggedIn = true
                            }
                    }
                } else {
                    // ❌ Go to Auth Flow
                    ViewManager().environmentObject(viewRouter).environmentObject(vm).dynamicTypeSize(.medium)
                }
            }else{
                MainView().environmentObject(viewRouter).environmentObject(vm).dynamicTypeSize(.medium)
                    .fullScreenCover(isPresented: $firstTime) {
                        WalkthroughView(manager: FirestoreManager()).dynamicTypeSize(.medium)
                            .environmentObject(networkMonitor)
                    }.environmentObject(currencyExchangeService)
                    .onAppear{
                        viewRouter.isLoggedIn = true
                    }
            }
        }
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate {
  var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      
      FirebaseApp.configure()
      
      Messaging.messaging().delegate = self
      
      //ask for push notification
      UNUserNotificationCenter.current().delegate = self

      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )

      if let isfirstOpenInterval = UserDefaults.standard.value(forKey: "isFirstOpen") as? TimeInterval {
          let firstOpendate = Date(timeIntervalSince1970: isfirstOpenInterval)
          let days = Calendar.current.numberOfDaysBetween(firstOpendate, and: Date())
          if days == 7 {
              if let isReviewed = UserDefaults.standard.value(forKey: "isReviewed") as? Bool{
                  if isReviewed == false{
                      UserDefaults.standard.setValue(true, forKey: "ShowReviewAlert")
                  }else{
                      UserDefaults.standard.setValue(false, forKey: "ShowReviewAlert")
                  }
              }else{
                  UserDefaults.standard.setValue(false, forKey: "ShowReviewAlert")
              }
          }
          if days == 30 {
              if let isInvitedShowed = UserDefaults.standard.value(forKey: "isInviteFriendShowed") as? Bool{
                  if isInvitedShowed == false{
                      UserDefaults.standard.setValue(true, forKey: "ShowInviteFriends")
                  }
              }
          }
      }else{
          UserDefaults.standard.setValue(Date().timeIntervalSince1970, forKey: "isFirstOpen")
          UserDefaults.standard.set(false, forKey: "isInviteFriendShowed")
          UserDefaults.standard.set(false, forKey: "isReviewed")
      }
      application.registerForRemoteNotifications()

    return true
  }
    
//    func application(_ application: UIApplication,
//                     didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async
//      -> UIBackgroundFetchResult {
//
//      if let messageID = userInfo[gcmMessageIDKey] {
//        print("Message ID: \(messageID)")
//      }
//
//      // Print full message.
//      print(userInfo)
//
//      return UIBackgroundFetchResult.newData
//    }
  
  func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
    return GIDSignIn.sharedInstance.handle(url)
  }
  
}
extension Calendar {
    func numberOfDaysBetween(_ from: Date, and to: Date) -> Int {
        let fromDate = startOfDay(for: from) // <1>
        let toDate = startOfDay(for: to) // <2>
        let numberOfDays = dateComponents([.day], from: fromDate, to: toDate) // <3>
        
        return numberOfDays.day!
    }
}

class BiometricIDAuth {
    private let context = LAContext()
    private let policy: LAPolicy
    private let localizedReason: String

    private var error: NSError?

    init(policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics,
         localizedReason: String = "Verify your Identity",
         localizedFallbackTitle: String = "Login Again",
         localizedCancelTitle: String = "Cancel") {
        self.policy = policy
        self.localizedReason = localizedReason
        context.localizedFallbackTitle = localizedFallbackTitle
        context.localizedCancelTitle = localizedCancelTitle
    }
    
    private func biometricType(for type: LABiometryType) -> BiometricType {
        switch type {
        case .none:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        @unknown default:
            return .unknown
        }
    }

    private func biometricError(from nsError: NSError) -> BiometricError {
        let error: BiometricError
        
        switch nsError {
        case LAError.authenticationFailed:
            error = .authenticationFailed
        case LAError.userCancel:
            error = .userCancel
        case LAError.userFallback:
            error = .userFallback
        case LAError.biometryNotAvailable:
            error = .biometryNotAvailable
        case LAError.biometryNotEnrolled:
            error = .biometryNotEnrolled
        case LAError.biometryLockout:
            error = .biometryLockout
        default:
            error = .unknown
        }
        
        return error
    }
    
    func canEvaluate(completion: (Bool, BiometricType, BiometricError?) -> Void) {
        // Asks Context if it can evaluate a Policy
        // Passes an Error pointer to get error code in case of failure
        guard context.canEvaluatePolicy(policy, error: &error) else {
            // Extracts the LABiometryType from Context
            // Maps it to our BiometryType
            let type = biometricType(for: context.biometryType)
            
            // Unwraps Error
            // If not available, sends false for Success & nil in BiometricError
            guard let error = error else {
                return completion(false, type, nil)
            }
            
            // Maps error to our BiometricError
            return completion(false, type, biometricError(from: error))
        }
        
        // Context can evaluate the Policy
        completion(true, biometricType(for: context.biometryType), nil)
    }
    
    func evaluate(completion: @escaping (Bool, BiometricError?) -> Void) {
        // Asks Context to evaluate a Policy with a LocalizedReason
        context.evaluatePolicy(policy, localizedReason: localizedReason) { [weak self] success, error in
            // Moves to the main thread because completion triggers UI changes
            DispatchQueue.main.async {
                if success {
                    // Context successfully evaluated the Policy
                    completion(true, nil)
                } else {
                    // Unwraps Error
                    // If not available, sends false for Success & nil for BiometricError
                    guard let error = error else { return completion(false, nil) }
                    
                    // Maps error to our BiometricError
                    completion(false, self?.biometricError(from: error as NSError))
                }
            }
        }
    }
}

enum BiometricType {
    case none
    case touchID
    case faceID
    case unknown
}

enum BiometricError: LocalizedError {
    case authenticationFailed
    case userCancel
    case userFallback
    case biometryNotAvailable
    case biometryNotEnrolled
    case biometryLockout
    case unknown

    var errorDescription: String? {
        switch self {
        case .authenticationFailed: return "There was a problem verifying your identity."
        case .userCancel: return "You pressed cancel."
        case .userFallback: return "You pressed password."
        case .biometryNotAvailable: return "Face ID/Touch ID is not available."
        case .biometryNotEnrolled: return "Face ID/Touch ID is not set up."
        case .biometryLockout: return "Face ID/Touch ID is locked."
        case .unknown: return "Face ID/Touch ID may not be configured"
        }
    }
}

//cloud messeging
extension AppDelegate : MessagingDelegate{
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
      print("Firebase registration token: \(String(describing: fcmToken))")

      let dataDict: [String: String] = ["token": fcmToken ?? ""]
      NotificationCenter.default.post(
        name: Notification.Name("FCMToken"),
        object: nil,
        userInfo: dataDict
      )
    }

}

// user notification (in app notification)
extension AppDelegate : UNUserNotificationCenterDelegate{
    // Receive displayed notifications for iOS 10 devices.
//      func userNotificationCenter(_ center: UNUserNotificationCenter,
//                                  willPresent notification: UNNotification) async
//        -> UNNotificationPresentationOptions {
//        let userInfo = notification.request.content.userInfo
//
//        print(userInfo)
//
//        // Change this to your preferred presentation option
//        return [[.alert, .sound]]
//      }

      func userNotificationCenter(_ center: UNUserNotificationCenter,
                                  didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo

        print(userInfo)
      }
    
    func application(_ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
      Messaging.messaging().apnsToken = deviceToken;
    }
     
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
      withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
      let userInfo = notification.request.content.userInfo

      Messaging.messaging().appDidReceiveMessage(userInfo)

      // Change this to your preferred presentation option
        completionHandler([[.banner, .sound]])
    }


    func application(_ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable : Any],
       fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
      Messaging.messaging().appDidReceiveMessage(userInfo)
      completionHandler(.noData)
    }
}
extension UIApplication {
  var currentKeyWindow: UIWindow? {
    UIApplication.shared.connectedScenes
      .filter { $0.activationState == .foregroundActive }
      .map { $0 as? UIWindowScene }
      .compactMap { $0 }
      .first?.windows
      .filter { $0.isKeyWindow }
      .first
  }

  var rootViewController: UIViewController? {
    currentKeyWindow?.rootViewController
  }
}
class NetworkMonitor: ObservableObject {
    private let networkMonitor = NWPathMonitor()
    private let workerQueue = DispatchQueue(label: "Monitor")
    var isConnected = false

    init() {
        networkMonitor.pathUpdateHandler = { path in
            self.isConnected = path.status == .satisfied
            Task {
                await MainActor.run {
                    self.objectWillChange.send()
                }
            }
        }
        networkMonitor.start(queue: workerQueue)
    }
}
