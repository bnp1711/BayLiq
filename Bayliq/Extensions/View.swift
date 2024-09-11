//
//  View.swift
//  Bayliq
//
//  Created by David Razmadze on 10/23/22.
//

import SwiftUI

extension View {
  
  func placeholder<Content: View>(
    when shouldShow: Bool,
    alignment: Alignment = .leading,
    @ViewBuilder placeholder: () -> Content) -> some View {
      
      ZStack(alignment: alignment) {
        placeholder().opacity(shouldShow ? 1 : 0)
        self
      }
    }
  
  func eraseToAnyView() -> AnyView {
    AnyView(self)
  }
  
  func customButtonStyle() -> some View {
    buttonStyle(CustomButtonStyle())
  }
  
  func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
    background(
      GeometryReader { geometryProxy in
        Color.clear
          .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
      }
    )
    .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
  }
  
}
