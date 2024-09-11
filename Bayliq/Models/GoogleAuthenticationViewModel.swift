//
//  GoogleAuthenticationViewModel.swift
//  Bayliq
//
//  Created by David Razmadze on 11/15/22.
//
//  Followed guide: https://blog.codemagic.io/google-sign-in-firebase-authentication-using-swift/

import Firebase
import GoogleSignIn
import FirebaseFirestore

class GoogleAuthenticationViewModel: ObservableObject {
  
  enum SignInState {
    case signedIn
    case signedOut
  }
  
  @Published var state: SignInState = .signedOut
  var firestore = FirestoreManager()
  
  func signIn(viewRouter:ViewRouter) {
    if GIDSignIn.sharedInstance.hasPreviousSignIn() {
      GIDSignIn.sharedInstance.restorePreviousSignIn { [unowned self] user, error in
        authenticateUser(for: user, with: error,viewRouter: viewRouter)
      }
    } else {
      guard let clientID = FirebaseApp.app()?.options.clientID else { return }
      
      let configuration = GIDConfiguration(clientID: clientID)
      
      guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
      guard let rootViewController = windowScene.windows.first?.rootViewController else { return }
      
      GIDSignIn.sharedInstance.signIn(with: configuration, presenting: rootViewController) { [unowned self] user, error in
        authenticateUser(for: user, with: error,viewRouter: viewRouter)
      }
    }
  }
  
  private func authenticateUser(for user: GIDGoogleUser?, with error: Error?,viewRouter:ViewRouter) {
    if let error = error {
      print(error.localizedDescription)
      return
    }
    
    guard let authentication = user?.authentication, let idToken = authentication.idToken else { return }
    
    let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken)
    
    Auth.auth().signIn(with: credential) { [unowned self] (result, error) in
      if let error = error {
        print(error.localizedDescription)
      } else {
        if let username = result?.user.displayName as? String {
            firestore.registerGoogleUser(displayName: username, viewRouter: viewRouter)
         
        }
        self.state = .signedIn
      }
    }
  }
  
  func signOut() {
    GIDSignIn.sharedInstance.signOut()
    state = .signedOut
  }
  
}
