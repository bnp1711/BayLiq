//
//  CircleButtonView.swift
//  Crypto App
//
//  Created by Nuno Mestre on 8/11/22.
//

import SwiftUI

struct CircleButtonView: View {
  let iconName: String
  
  var body: some View {
    Image(systemName: iconName)
      .font(.headline)
      .foregroundColor(Color("accent"))
      .frame(width: 50, height: 50)
      .background( Circle().foregroundColor(Color("background")))
      .shadow(color: Color("accent").opacity(0.25), radius: 10, x: 0, y: 0)
      .padding()
  }
  
}

struct CircleButtonView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      CircleButtonView(iconName: "chart.bar.xaxis")
        .previewLayout(.sizeThatFits)
      CircleButtonView(iconName: "info")
        .previewLayout(.sizeThatFits)
        .colorScheme(.dark)
    }
  }
}
