//
//  CircleButtonAnimationView.swift
//  Crypto App
//
//  Created by Nuno Mestre on 8/11/22.
//

import SwiftUI

struct CircleButtonAnimationView: View {
  @Binding var animate: Bool
  
  var body: some View {
    Circle()
      .stroke(lineWidth: 5.0)
      .scale(animate ? 1.0 : 0.0)
      .opacity(animate ? 0.0 : 1.0)
  }
  
}

struct CircleButtonAnimationView_Previews: PreviewProvider {
  static var previews: some View {
    CircleButtonAnimationView(animate: .constant(false))
      .foregroundColor(.red)
      .frame(width: 100, height: 100)
  }
}
