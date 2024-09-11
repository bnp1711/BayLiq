//
//  ContentView.swift
//  Bayliq
//
//  Created by David Razmadze on 7/15/22.
//

import SwiftUI

struct ContentView: View {

  // MARK: - Body

  var body: some View {
    Text("Bayliq")
      .font(.system(size: 32))
      .padding()
      .foregroundColor(.blue)
  }

}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
