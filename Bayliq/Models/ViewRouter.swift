//
//  ViewRouter.swift
//  Bayliq
//
//  Created by Nuno Mestre on 7/27/22.
//

import SwiftUI

/// Uses `Page` enum to display current page.
class ViewRouter: ObservableObject {
  @Published var currentPage: Page = .signInPage
    var isLoggedIn = false
}

// MARK: - Pages

/// Pages used in `ViewRouter`
enum Page {
  case signUpPage
  case signInPage
  case forgotPassowrdPage
  case checkEmailPage
  case homePage
  case deleteAccountPage
}
