//
//  CheckEmailView.swift
//  Bayliq
//
//  Created by Nuno Mestre on 7/27/22.
//

import SwiftUI
import Firebase

struct CheckEmailView: View {
  
  // MARK: - Variables
  
  @EnvironmentObject var viewRouter: ViewRouter
  
  // MARK: - Body
  
  var body: some View {
    ZStack {
      // Background Color
      Color("background").ignoresSafeArea(edges: .all)
      // Main View
      VStack {
        emailText
        loginButton
      }
    }
  }
}

// MARK: - loginButton

private extension CheckEmailView {
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

// MARK: - emailText

private extension CheckEmailView {
  var emailText: some View {
    VStack {
      Text("An email was sent")
        .foregroundColor(.white)
        .font(.system(size: 32))
        .fontWeight(.bold)
        .frame(width: UIScreen.main.bounds.size.width, height: 50, alignment: .leading)
        .offset(x: 15, y: 0)
      Text("Please check your email to complete the next steps. You may need to check your spam folder.")
        .foregroundColor(.white)
        .font(.system(size: 20))
        .fontWeight(.light)
        .fixedSize(horizontal: false, vertical: true)
        .frame(width: UIScreen.main.bounds.size.width, height: 50, alignment: .leading)
        .offset(x: 15, y: 0)
        .padding(12)
    }
  }
}

// MARK: - Preview

struct CheckEmailView_Previews: PreviewProvider {
  static var previews: some View {
    CheckEmailView()
      .environmentObject(ViewRouter())
  }
}
