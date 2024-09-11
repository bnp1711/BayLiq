//
//  SignUpView.swift
//  Bayliq
//
//  Created by Nuno Mestre on 7/27/22.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import Combine
struct SignUpView: View {
  
  // MARK: - Enunm
  
  enum Field {
    case usernameField
    case emailAddress
    case passwordField
    case passwordAgainField
  }
  
  // MARK: - Variables
  
  let db = Firestore.firestore()
  
  @EnvironmentObject var viewRouter: ViewRouter
  @ObservedObject var firestore = FirestoreManager()
  
  @State var username = ""
  @State var email = ""
  @State var password = ""
  @State var passwordAgain = ""
  @State var signUpProcessing = false
  @State var signUpErrorMessage = ""
  @State var isInvalidChar = false
  
  var showErrorMessage: Bool {
    !signUpErrorMessage.isEmpty
  }
  
  @FocusState private var focusedField: Field?
  
  // MARK: - Body
  
  var body: some View {
    ZStack {
      // Background Color
      Color("background").ignoresSafeArea(edges: .all)
      // Main View
      VStack {
        Text("Sign Up")
          .foregroundColor(.white).font(.system(size: 32)).fontWeight(.bold).frame(width: UIScreen.main.bounds.size.width, height: 50, alignment: .leading).offset(x: 15, y: 25).padding(.bottom)
        credentials
        createAccountButton
        loginButton
      }
    }.alert(signUpErrorMessage, isPresented: .constant(showErrorMessage)) {
      Button("OK", role: .cancel) {
        signUpErrorMessage = ""
      }
    }
    .onTapGesture {
      self.hideKeyboard()
    }
  }
  
  // MARK: - SignUp Functions
  
  private func createNewUser() {
    
    if password != passwordAgain {
      signUpProcessing = false
      signUpErrorMessage = "Passwords do not match"
      return
    }
    if username.isEmpty && email.isEmpty && password.isEmpty && passwordAgain.isEmpty {
      signUpProcessing = false
      signUpErrorMessage = "Please fill in all account fields first"
      return
    } else if username.isEmpty {
      signUpProcessing = false
      signUpErrorMessage = "Username field is empty"
      return
    } else if email.isEmpty {
      signUpProcessing = false
      signUpErrorMessage = "Email field is empty"
      return
    } else if password.isEmpty {
      signUpProcessing = false
      signUpErrorMessage = "Password field is empty"
      return
    }
    
    Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
      guard error == nil else {
        signUpErrorMessage = error!.localizedDescription
        signUpProcessing = false
        return
      }
      switch authResult {
      case .none:
        print("Could not create account.")
        signUpProcessing = false
      case .some:
        print("User created")
        signUpProcessing = false
        sendVerificationCode()
        firestore.registerUserData(userName: username)
        viewRouter.currentPage = .checkEmailPage
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

// MARK: - credentials

private extension SignUpView {
  var credentials: some View {
    VStack {
      TextField("", text: $username).disableAutocorrection(true).autocapitalization(.none).padding().foregroundColor(.white).keyboardType(.emailAddress).cornerRadius(12).focused($focusedField, equals: .usernameField)
        .placeholder(when: username.isEmpty) {
          Text("Username").foregroundColor(Color.white).offset(x: 15, y: 0)
        }
        .overlay {
          RoundedRectangle(cornerRadius: 12).stroke(Color("loginFields"), lineWidth: 2)
        }
        .padding(.horizontal)
        .padding(.bottom, 5)
      TextField("", text: $email).disableAutocorrection(true).autocapitalization(.none).padding().foregroundColor(.white).keyboardType(.emailAddress).cornerRadius(12).focused($focusedField, equals: .emailAddress)
        .placeholder(when: email.isEmpty) {
          Text("Email").foregroundColor(Color.white).offset(x: 15, y: 0)
        }
        .overlay {
          RoundedRectangle(cornerRadius: 12).stroke(Color("loginFields"), lineWidth: 2)
        }
        .padding(.horizontal)
        .padding(.bottom, 5)
      SecureField("", text: $password).disableAutocorrection(true).autocapitalization(.none).padding().foregroundColor(.white).keyboardType(.emailAddress).cornerRadius(12).focused($focusedField, equals: .passwordField)
        .placeholder(when: password.isEmpty) {
          Text("Password").foregroundColor(Color.white).offset(x: 15, y: 0)
        }
        
        .onReceive(Just(password)) { newValue in
            let allowedCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._-"
            let filtered = newValue.filter { allowedCharacters.contains($0) }
            if filtered != newValue {
                self.password = filtered
                isInvalidChar = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0){
                    isInvalidChar = false
                }
            }
        }
        .overlay {
          RoundedRectangle(cornerRadius: 12).stroke(Color("loginFields"), lineWidth: 2)
            if passwordAgain != "" {
                RoundedRectangle(cornerRadius: 12).stroke(Color.red, lineWidth: passwordAgain != password ? 2 : 0)
                RoundedRectangle(cornerRadius: 12).stroke(Color.green, lineWidth: (passwordAgain == password && !password.isEmpty) ? 2 : 0)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 5)
        if isInvalidChar {
            Text("Only A-Z,a-z, 0-9, ._- are allowed").foregroundColor(Color.red).offset(x: 15, y: 0)
        }
      SecureField("", text:$passwordAgain).disableAutocorrection(true).autocapitalization(.none).padding().foregroundColor(.white).keyboardType(.emailAddress).cornerRadius(12).focused($focusedField, equals: .passwordAgainField)
        .placeholder(when: passwordAgain.isEmpty) {
          Text("Confirm Password").foregroundColor(Color.white).offset(x: 15, y: 0)
        }
        .onReceive(Just(passwordAgain)) { newValue in
            let allowedCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._-"
            let filtered = newValue.filter { allowedCharacters.contains($0) }
            if filtered != newValue {
                self.passwordAgain = filtered
                isInvalidChar = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0){
                    isInvalidChar = false
                }
            }
        }
        .overlay {
          RoundedRectangle(cornerRadius: 12).stroke(Color("loginFields"), lineWidth: 2)
            if passwordAgain != "" {
                RoundedRectangle(cornerRadius: 12).stroke(Color.red, lineWidth: passwordAgain != password ? 2 : 0)
                RoundedRectangle(cornerRadius: 12).stroke(Color.green, lineWidth: (passwordAgain == password && !passwordAgain.isEmpty) ? 2 : 0)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 5)
        if passwordAgain != "" && (passwordAgain != password && !passwordAgain.isEmpty) {
            Text("Passwords doesn't match").foregroundColor(Color.red).offset(x: 15, y: 0)
        }
    }
    .padding(.top, 15)
    .onSubmit {
      switch focusedField {
      case .usernameField:
        focusedField = .emailAddress
      case .emailAddress:
        focusedField = .passwordField
      case .passwordField:
        focusedField = .passwordAgainField
      default:
        print("Creating account…")
      }
    }
  }
}

// MARK: - createAccountButton

private extension SignUpView {
  var createAccountButton: some View {
    VStack {
      Button(action: {
        createNewUser()
      }, label: {
        Text("Create Account")
          .foregroundColor(Color.white)
          .frame(width: UIScreen.main.bounds.width, height: 50)
          .padding(.horizontal, -18)
          .background(Color("orange"))
          .font(.system(size: 20, weight: .bold))
      })
      .cornerRadius(12)
      .disabled(!signUpProcessing ? false : true)
      if signUpProcessing {
        ProgressView()
      }
      Spacer()
    }
  }
}

// MARK: - loginButton

private extension SignUpView {
  var loginButton: some View {
    VStack {
      Button(action: {
        withAnimation {
          viewRouter.currentPage = .signInPage
        }
      }, label: {
        Text("Already have an account? Login")
          .foregroundColor(Color("orange"))
          .cornerRadius(12)
          .frame(width:400, height: 50)
      })
    }
  }
}

// MARK: - Preview

struct SignUpView_Previews: PreviewProvider {
  static var previews: some View {
    SignUpView()
      .environmentObject(ViewRouter())
  }
}
