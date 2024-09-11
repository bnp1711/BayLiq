//
//  SearchBarView.swift
//  Crypto App
//
//  Created by Nuno Mestre on 8/13/22.
//

import SwiftUI

struct SearchBarView: View {
  
  @Binding var searchText: String
  @State var placeHolder = "Search by name or symbol..."
  var body: some View {
    HStack {
      Image(systemName: "magnifyingglass")
        .foregroundColor(
          searchText.isEmpty ?
          Color("secondaryText") : Color("accent")
        )
      TextField(placeHolder, text: $searchText)
        .foregroundColor(Color("accent"))
        .placeholder(when: searchText.isEmpty) {
          Text(placeHolder).foregroundColor(Color.white)
        }
        .disableAutocorrection(true)
        .overlay(
          Image(systemName: "xmark.circle.fill")
            .padding()
            .offset(x: 10)
            .foregroundColor(Color("accent"))
            .opacity(searchText.isEmpty ? 0.0 : 1.0)
            .onTapGesture {
              UIApplication.shared.endEditing()
              searchText = ""
            }
          ,alignment: .trailing
        )
    }
    .font(.headline)
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 25)
        .fill(Color("background"))
        .shadow(
          color: Color("accent").opacity(0.15),
          radius: 10, x: 0, y: 0)
    )
    .padding()
    .onTapGesture {
      self.hideKeyboard()
    }
  }
  
}

struct SearchBarView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      SearchBarView(searchText: .constant(""))
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.light)
      SearchBarView(searchText: .constant(""))
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
  }
}
