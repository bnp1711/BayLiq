//
//  QuickSignInWithApple.swift
//  Bayliq
//
//  Created by Bhavesh Patel on 08/01/23.
//

import CryptoKit
import FirebaseAuth
import AuthenticationServices
import SwiftUI

struct QuickSignInWithApple: UIViewRepresentable {
    typealias UIViewType = ASAuthorizationAppleIDButton
    @Environment(\.colorScheme) var colorScheme
    
    func makeUIView(context: Context) -> UIViewType {
      return ASAuthorizationAppleIDButton(type: .signIn,
                                          style: colorScheme == .dark ? .white : .black)
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
    }
}

struct QuickSignInWithApple_Previews: PreviewProvider {
    static var previews: some View {
        QuickSignInWithApple()
    }
}

class SignInWithAppleViewModel: NSObject, ASAuthorizationControllerDelegate {
    // from https://firebase.google.com/docs/auth/ios/apple
     var currentNonce:String?
     var viewRouter: ViewRouter?
    var firestore = FirestoreManager()
    init(viewRouter: ViewRouter, currentNonce:String) {
        super.init()
        self.currentNonce = currentNonce
        self.viewRouter = viewRouter
    }
  func authorizationController(controller: ASAuthorizationController,
                               didCompleteWithAuthorization authorization: ASAuthorization) {
      switch authorization.credential {
            case let appleIDCredential as ASAuthorizationAppleIDCredential:

            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }

          if let authorizationCode = appleIDCredential.authorizationCode,
             let codeString = String(data: authorizationCode, encoding: .utf8) {
            
            let url = URL(string: "https://us-central1-bayliq-72340.cloudfunctions.net/getRefreshToken?code=\(codeString)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "https://apple.com")!
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
              if let data = data {
                let refreshToken = String(data: data, encoding: .utf8) ?? ""
                do {
                  try KeychainManager.save(service: "apple.com", account: "my_account", password: refreshToken.data(using: .utf8) ?? Data())
                } catch {
                  print(error)
                }
              }
            }
            task.resume()
          }
          
            let credential = OAuthProvider.credential(withProviderID: "apple.com",idToken: idTokenString,rawNonce: nonce)
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if (error != nil) {
                    // Error. If error.code == .MissingOrInvalidNonce, make sure
                    // you're sending the SHA256-hashed nonce as a hex string with
                    // your request to Apple.
                    print(error?.localizedDescription as Any)
                    return
                }
                print("signed in")
                
                if let _ = appleIDCredential.email, let _ = appleIDCredential.fullName {
                    // Apple has autherized the use with Apple ID and password
                    self.registerNewUser(credential: appleIDCredential)
                } else {
                    // User has been already exist with Apple Identity Provider
                    self.signInExistingUser(credential: appleIDCredential)
                }
            }
        default:
          break
    }
  }
  
  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    print("\n -- ASAuthorizationControllerDelegate -\(#function) -- \n")
    print(error)
    // Give Call Back to UI
  }
}

extension SignInWithAppleViewModel {
  private func registerNewUser(credential: ASAuthorizationAppleIDCredential) {
    // API Call - Pass the email, user full name, user identity provided by Apple and other details.
    // Give Call Back to UI
      if let fullName = credential.fullName {
          if let givenName = fullName.givenName, let familyName = fullName.familyName {
              let displayName = "\(givenName) \(familyName)"
              firestore.registerAppleUser(credential: credential, displayName: displayName)
              viewRouter!.currentPage = .homePage
          }
      }
  }
  
  private func signInExistingUser(credential: ASAuthorizationAppleIDCredential) {
    // API Call - Pass the user identity, authorizationCode and identity token
    // Give Call Back to UI
      if let fullName = credential.fullName {
          if let givenName = fullName.givenName, let familyName = fullName.familyName {
              let displayName = "\(givenName) \(familyName)"
              firestore.registerAppleUser(credential: credential, displayName: displayName)
          }
      }
      viewRouter!.currentPage = .homePage
  }

}
