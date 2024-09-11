//
//  DeleteAccountView.swift
//  Bayliq
//
//  Created by David Razmadze on 10/23/22.
//

import SwiftUI
import Firebase

struct DeleteAccountView: View {
  
  // MARK: - Variables
  
  @EnvironmentObject var viewRouter: ViewRouter
  @State var email = ""
  @State var password = ""
  @State var errorMessage = ""
  
  var showErrorMessage: Bool {
    !errorMessage.isEmpty
  }
  
  // MARK: - Body
  
  var body: some View {
    ZStack {
      // Background Color
      Color("background").ignoresSafeArea(edges: .all)
      // Main View
      VStack {
        Text("Delete Account")
          .foregroundColor(.white).font(.system(size: 32)).fontWeight(.bold).frame(width: UIScreen.main.bounds.size.width, height: 50, alignment: .leading).offset(x: 15, y: 25).padding(.bottom)
        credentials
        deleteAccountButton
        loginButton
      }
    }.alert(errorMessage, isPresented: .constant(showErrorMessage)) {
      Button("OK", role: .cancel) {
        errorMessage = ""
      }
    }
    .onTapGesture {
      self.hideKeyboard()
    }
  }
  
  // MARK: - Reset Password Function
  
  /// Delete account. First reauthenticate with current credentials, then call `user.delete`
  private func deleteFirebaseAccount() {
    
    guard !email.isEmpty && !password.isEmpty else { return }
    let user = Auth.auth().currentUser
    let credential = EmailAuthProvider.credential(withEmail: email, password: password)
    
    user?.reauthenticate(with: credential, completion: { _, error in
      if let error = error {
        errorMessage = "Error: \(error.localizedDescription)"
        return
      }
      
      user?.delete(completion: { error in
        if let error = error {
          errorMessage = "Error: \(error.localizedDescription)"
          return
        }
        
        print("Deleted account")
        viewRouter.currentPage = .signInPage
      })
      
    })
    
  }
  
}

// MARK: - credentials

private extension DeleteAccountView {
  
  var credentials: some View {
    VStack {
      TextField("", text: $email).disableAutocorrection(true).autocapitalization(.none).padding().foregroundColor(.white).keyboardType(.emailAddress).cornerRadius(12)
        .placeholder(when: email.isEmpty) {
          Text("Email").foregroundColor(Color.white).offset(x: 15, y: 0)
        }
        .overlay {
          RoundedRectangle(cornerRadius: 12).stroke(Color("loginFields"), lineWidth: 2)
        }
        .padding(.horizontal)
        .padding(.bottom, 5)
      
      SecureField("", text: $password).disableAutocorrection(true).autocapitalization(.none).padding().foregroundColor(.white).cornerRadius(12)
        .placeholder(when: password.isEmpty) {
          Text("Password").foregroundColor(Color.white).offset(x: 15, y: 0)
        }
        .overlay {
          RoundedRectangle(cornerRadius: 12).stroke(Color("loginFields"), lineWidth: 2)
        }
        .padding(.horizontal)
        .padding(.bottom, 5)
      
    }
    .padding(.top, 15)
  }
}

// MARK: - resetPasswordButton

private extension DeleteAccountView {
  var deleteAccountButton: some View {
    VStack {
      Button(action: {
        deleteFirebaseAccount()
      }, label: {
        Text("Delete Account")
          .foregroundColor(Color.white)
          .frame(width: UIScreen.main.bounds.width, height: 50)
          .padding(.horizontal, -18)
          .background(Color.red)
          .font(.system(size: 20, weight: .bold))
      })
      .cornerRadius(12)
      Spacer()
    }
  }
}

// MARK: - loginButton

private extension DeleteAccountView {
  var loginButton: some View {
    VStack {
      Button(action: {
        withAnimation {
          viewRouter.currentPage = .signInPage
        }
      }, label: {
        Text("Go back")
          .foregroundColor(Color("orange"))
          .frame(width:400, height: 50)
          .cornerRadius(8)
      })
    }
  }
}

// MARK: - Preview

struct DeleteAccountView_Previews: PreviewProvider {
  static var previews: some View {
    DeleteAccountView()
      .environmentObject(ViewRouter())
  }
}
