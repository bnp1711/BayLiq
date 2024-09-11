//
//  ViewManager.swift
//  Bayliq
//
//  Created by Nuno Mestre on 7/27/22.
//

import SwiftUI

/// Displays the Auth Pages and Main View
struct ViewManager: View {
  
  // MARK: - Variables
    @EnvironmentObject var vm: HomeViewModel
  @EnvironmentObject var viewRouter: ViewRouter
  // MARK: - Body
  
  var body: some View {
    switch viewRouter.currentPage {
    case .signUpPage:
      SignUpView()
    case .signInPage:
      SignInView()
    case .forgotPassowrdPage:
      ResetPasswordView()
    case .checkEmailPage:
      CheckEmailView()
    case .homePage:
        HomeView(vm: vm,isFromManualTransaction: .constant(false), TokenName: .constant(""), TokenFullName: .constant(""), TokenPrice: .constant(Double(0.0)), TokenImage: .constant(Image(uiImage: UIImage())), presentedAsModal: .constant(true), currentCurrencyExchangeSymbol: "$").environmentObject(FirestoreManager())
    case .deleteAccountPage:
      DeleteAccountView()
    }
  }
  
}

// MARK: - Preview

struct ViewManager_Previews: PreviewProvider {
  static var previews: some View {
      ViewManager().environmentObject(ViewRouter()).environmentObject(HomeViewModel())
  }
}
