//
//  SignInView.swift
//  Bayliq
//
//  Created by Nuno Mestre on 7/27/22.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import GoogleSignIn
import CryptoKit
import FirebaseAuth
import AuthenticationServices

struct SignInView: View {
  
  // MARK: - Enum
  
  enum Field {
    case emailAddress
    case passwordField
  }
  
  // MARK: - Variables
  
  let db = Firestore.firestore()
  
  @EnvironmentObject var viewRouter: ViewRouter
  @StateObject var googleViewModel = GoogleAuthenticationViewModel()
  
  @State var email = ""
  @State var password = ""
  @State var signInProcessing = false
  @State var signInErrorMessage = ""
  @State var signInWithAppleViewModel : SignInWithAppleViewModel!
  var showErrorMessage: Bool {
    !signInErrorMessage.isEmpty
  }
  
  @FocusState private var focusedField: Field?
  
  // MARK: - Body
    var body: some View {
    ZStack {
      // Background Color
      Color("background").ignoresSafeArea(edges: .all)
      // Main View
        ScrollView(showsIndicators: false){
            VStack {
                VStack {
                    bayliqImage
                    credentials
                    loginButton
                    Button(action: {
                        googleViewModel.signIn(viewRouter: viewRouter)
                    }) {
                        HStack {
                            Image("icons8-google")
                            //                        .font(.title)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 30, height: 30.0,alignment: .leading)
                            Text("Sign in")
                                .fontWeight(.semibold)
                                .font(.subheadline)
                        }
                        .foregroundColor(Color.black)
                        .frame(width: UIScreen.main.bounds.width, height: 50)
                        .padding(.horizontal, -50)
                        .background(Color.white)
                        .font(.system(size: 20, weight: .bold))
                    }
                    .cornerRadius(5)
                    .offset(y:10)
                    
                    QuickSignInWithApple()
                        .offset(y:20)
                        .padding(.leading, 50)
                        .padding(.trailing, 50)
                        .frame(height: 50,alignment: .center)
                        .onTapGesture(perform: self.showAppleLoginView)
                }
                .offset(y:-50)
                VStack {
                    resetPasswordButton
                    createAccountButton
                }
            }
        }
    }.alert(signInErrorMessage, isPresented: .constant(showErrorMessage)) {
      Button("OK", role: .cancel) {
        signInErrorMessage = ""
      }
    }
    .onTapGesture {
      self.hideKeyboard()
    }
  }
  
  // MARK: - Login Functions
    private  func showAppleLoginView() {
        // 1. Instantiate the AuthorizationAppleIDProvider
        let provider = ASAuthorizationAppleIDProvider()
        // 2. Create a request with the help of provider - ASAuthorizationAppleIDRequest
        let request = provider.createRequest()
        // 3. Scope to contact information to be requested from the user during authentication.
        request.requestedScopes = [.fullName, .email]
        let nonce = randomNonceString()
        signInWithAppleViewModel = SignInWithAppleViewModel(viewRouter: viewRouter, currentNonce: nonce)
        request.nonce = sha256(nonce)
        // 4. A controller that manages authorization requests created by a provider.
        let controller = ASAuthorizationController(authorizationRequests: [request])
        // 5. Set delegate to perform action
        controller.delegate = signInWithAppleViewModel
        // 6. Initiate the authorization flows.
        controller.performRequests()
    }
    
    
    //Hashing function using CryptoKit
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
        return String(format: "%02x", $0)
        }.joined()

        return hashString
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
         Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
            }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }
    
  private func login(userEmail: String, userPassword: String) {
    
    signInProcessing = true
    
    if email.isEmpty && password.isEmpty {
      signInProcessing = false
      signInErrorMessage = "Please fill in both account fields first"
      return
    } else if email.isEmpty {
      signInProcessing = false
      signInErrorMessage = "Email field is empty"
      return
    } else if password.isEmpty {
      signInProcessing = false
      signInErrorMessage = "Password field is empty"
      return
    }
    Auth.auth().signIn(withEmail: userEmail, password: userPassword) { authResult, error in
      if let user = Auth.auth().currentUser {
        if !user.isEmailVerified {
          signInProcessing = false
          signInErrorMessage = "Sorry. Your email address has not yet been verified. Please check your email for a new verification link! You may need to check the spam folder."
          sendVerificationCode()
          return
        }
      }
      guard error == nil else {
        signInProcessing = false
        signInErrorMessage = error!.localizedDescription
        return
      }
      switch authResult {
      case .none:
        print("Could not sign in user.")
        signInProcessing = false
      case .some:
        print("User signed in")
        email = ""
        password = ""
        signInProcessing = false
        withAnimation {
          viewRouter.currentPage = .homePage
        }
      }
    }
  }
  
  private func sendVerificationCode() {
    Auth.auth().currentUser?.sendEmailVerification { error in
      if let err = error {
        print("Error: \(err.localizedDescription)")
        return
      }
    }
  }
  
}

// MARK: - bayliqImage

private extension SignInView {
  var bayliqImage: some View {
    VStack {
      Image("logo")
        .resizable()
        .scaledToFit()
        .frame(width: 100, height: 100)
      VStack {
        Text("**bay**")
          .foregroundColor(Color.white)
          .font(.system(size: 70)) +
        Text("liq")
          .foregroundColor(Color.white)
          .font(.system(size: 70, weight: .ultraLight))
        Text("Liquid investment")
          .foregroundColor(Color("orange"))
          .font(.system(size: 22))
      }.padding(.vertical, -14)
    }
    .padding(.init(top: 80, leading: 0, bottom: 40, trailing: 0))
  }
}

// MARK: - credentials

extension SignInView {
  var credentials: some View {
    VStack {
      TextField("", text: $email).disableAutocorrection(true).autocapitalization(.none).padding().keyboardType(.emailAddress).cornerRadius(12).focused($focusedField, equals: .emailAddress).foregroundColor(.white)
        .placeholder(when: email.isEmpty) {
          Text("Email").foregroundColor(Color.white).offset(x: 15, y: 0)
        }
        .overlay {
          RoundedRectangle(cornerRadius: 12).stroke(Color("loginFields"), lineWidth: 2)
        }
        .padding(.horizontal, 50)
        .padding(.bottom, 10)
      SecureField("", text: $password).disableAutocorrection(true).autocapitalization(.none).padding().foregroundColor(.white).keyboardType(.emailAddress).cornerRadius(12).focused($focusedField, equals: .passwordField)
        .placeholder(when: password.isEmpty) {
          Text("Password").foregroundColor(Color.white).offset(x: 15, y: 0)
        }
        .overlay {
          RoundedRectangle(cornerRadius: 12).stroke(Color("loginFields"), lineWidth: 2)
        }
        .padding(.horizontal, 50)
        .padding(.bottom)
    }
    .onSubmit {
      switch focusedField {
      case .emailAddress:
        focusedField = .passwordField
      default:
        print("Signing In…")
      }
    }
  }
}

// MARK: - loginButton

private extension SignInView {
  var loginButton: some View {
    VStack {
      Button(action: {
        login(userEmail: email, userPassword: password)
      }, label: {
        Text("Login")
          .foregroundColor(Color.white)
          .frame(width: UIScreen.main.bounds.width, height: 50)
          .padding(.horizontal, -50)
          .background(Color("orange"))
          .font(.system(size: 20, weight: .bold))
      })
      .cornerRadius(12)
      .disabled(!signInProcessing ? false : true)
      if signInProcessing {
        ProgressView()
      }
    }
  }
}

// MARK: - resetPasswordButton

private extension SignInView {
  var resetPasswordButton: some View {
    VStack {
      Button(action: {
        withAnimation {
          viewRouter.currentPage = .forgotPassowrdPage
        }
      }, label: {
        Text("Forgot Password?")
          .foregroundColor(Color.white)
          .underline()
          .frame(width:200, height: 30)
          .cornerRadius(8)
      })
    }
  }
}

// MARK: - createAccountButton

private extension SignInView {
  var createAccountButton: some View {
    VStack {
      Button(action: {
        withAnimation {
          viewRouter.currentPage = .signUpPage
        }
      }, label: {
        Text("Create Account")
          .foregroundColor(Color.white)
          .frame(width:200, height: 50)
          .cornerRadius(12)
          .font(.system(size: 22, weight: .bold))
      })
//      .padding()
    }
  }
}

// MARK: - Google Sign in Button

struct GoogleSignInButton: UIViewRepresentable {
  
  private var button = GIDSignInButton()
  
  func makeUIView(context: Context) -> GIDSignInButton {
    //button.colorScheme = .light
    return button
  }
  
  func updateUIView(_ uiView: UIViewType, context: Context) {
//    button.colorScheme = .light
  }
}

// MARK: - Preview

struct SignInView_Previews: PreviewProvider {
  static var previews: some View {
    SignInView()
      .environmentObject(ViewRouter())
  }
}
