//
//  ActivityViewController.swift
//  Bayliq
//
//  Created by David Razmadze on 1/27/23.
//
// https://stackoverflow.com/questions/56533564/showing-uiactivityviewcontroller-in-swiftui

import UIKit
import SwiftUI

struct ActivityViewController: UIViewControllerRepresentable {
  
  var activityItems: [Any]
  var applicationActivities: [UIActivity]?
  
  func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
    let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    return controller
  }
  
  func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
  
}
