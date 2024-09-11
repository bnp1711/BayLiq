//
//  ResetPasswordView.swift
//  Bayliq
//
//  Created by Nuno Mestre on 7/27/22.
//

import SwiftUI
import Firebase

struct ResetPasswordView: View {
  
  // MARK: - Variables
  
  @EnvironmentObject var viewRouter: ViewRouter
  @State var email = ""
  @State var resetErrorMessage = ""
  
  var showErrorMessage: Bool {
    !resetErrorMessage.isEmpty
  }
  
  // MARK: - Body
  
  var body: some View {
    ZStack {
      // Background Color
      Color("background").ignoresSafeArea(edges: .all)
      // Main View
      VStack {
        Text("Reset Password")
          .foregroundColor(.white).font(.system(size: 32)).fontWeight(.bold).frame(width: UIScreen.main.bounds.size.width, height: 50, alignment: .leading).offset(x: 15, y: 25).padding(.bottom)
        credentials
        resetPasswordButton
        loginButton
      }
    }.alert(resetErrorMessage, isPresented: .constant(showErrorMessage)) {
      Button("OK", role: .cancel) {
        resetErrorMessage = ""
      }
    }
    .onTapGesture {
      self.hideKeyboard()
    }
  }
  
  // MARK: - Reset Password Function
  
  private func sendResetPassword() {
    Auth.auth().sendPasswordReset(withEmail: email) { error in
      if let err = error {
        resetErrorMessage = "Error: \(err.localizedDescription)"
        return
      }
      viewRouter.currentPage = .checkEmailPage
    }
  }
  
}

// MARK: - credentials

private extension ResetPasswordView {
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
    }
    .padding(.top, 15)
  }
}

// MARK: - resetPasswordButton

private extension ResetPasswordView {
  var resetPasswordButton: some View {
    VStack {
      Button(action: {
        sendResetPassword()
      }, label: {
        Text("Reset Password")
          .foregroundColor(Color.white)
          .frame(width: UIScreen.main.bounds.width, height: 50)
          .padding(.horizontal, -18)
          .background(Color("orange"))
          .font(.system(size: 20, weight: .bold))
      })
      .cornerRadius(12)
      Spacer()
    }
  }
}

// MARK: - loginButton

private extension ResetPasswordView {
  var loginButton: some View {
    VStack {
      Button(action: {
        withAnimation {
          viewRouter.currentPage = .signInPage
        }
      }, label: {
        Text("Back to login")
          .foregroundColor(Color("orange"))
          .frame(width:400, height: 50)
          .cornerRadius(8)
      })
    }
  }
}

// MARK: - Preview

struct ResetPasswordView_Previews: PreviewProvider {
  static var previews: some View {
    ResetPasswordView()
      .environmentObject(ViewRouter())
  }
}
