//
//  ExchangesView.swift
//  Bayliq
//
//  Created by Nuno Mestre on 9/12/22.
//

import SwiftUI

struct ExchangesView: View {
  
  // MARK: - Variables
  
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var firestore : FirestoreManager
    @State var searchText = ""
    @State var listArr = [CryptoExchange]()
    @State var showContactUs = false
  // MARK: - Body
   
  var body: some View {
    ZStack {
      Color("background").ignoresSafeArea(edges: .all)
      VStack(spacing: 0){
        HStack {
          Button(action: {
            dismiss()
          }, label: {
            Image(systemName: "chevron.down")
              .foregroundColor(.white)
          })
          .padding(20)
          Spacer()
        }
        ScrollView {
          VStack(alignment: .leading, spacing: 16){
              SearchBarView(searchText: $searchText)
              HStack{
                  Text("Best Crypto Exchanges").foregroundColor(.white).fontWeight(.bold).font(.system(size: 20))
                  Spacer()
                   if (firestore.unCheckedexchangesList.count == 0){
                      //all selected
                       Image(systemName: "checkmark.square")
                           .resizable()
                           .frame(width: 20,height: 20,alignment: .trailing)
                           .foregroundColor(.white)
                           .padding(.trailing,80)
                           .onTapGesture {
                               //unselect all
                               firestore.RemoveAllExchanges { error in
                                   if error != nil {
                                       print("ERROR: " + error!.localizedDescription)
                                   }
                               }
                           }
                   } else if firestore.unCheckedexchangesList.count == firestore.exchangesList.count {
                      //all unselected
                      Image(systemName: "square")
                          .resizable()
                          .frame(width: 20,height: 20,alignment: .trailing)
                          .foregroundColor(.white)
                          .padding(.trailing,80)
                          .onTapGesture {
                              //select all
                              firestore.SelectAllExchanges { error in
                                  if error != nil {
                                      print("ERROR: " + error!.localizedDescription)
                                  }
                              }
                          }
                  } else{
                      //some selected
                      Image(systemName: "dot.square")
                          .resizable()
                          .frame(width: 20,height: 20,alignment: .trailing)
                          .foregroundColor(.white)
                          .padding(.trailing,80)
                          .onTapGesture {
                              //select all
                              firestore.SelectAllExchanges { error in
                                  if error != nil {
                                      print("ERROR: " + error!.localizedDescription)
                                  }
                              }
                          }
                  }
              }
              let arr = listArr.count > 0 ? listArr : firestore.exchangesList
              ForEach(arr.indices, id: \.self) { i in
                  if arr.firstIndex(of: arr[i]) == firestore.customTop10.count {
                      Text("All supported exchanges").foregroundColor(.white).fontWeight(.bold).font(.system(size: 20))
                  }
                  if  arr[i].name != "Custom Exchange" {
                      CustomExchangeRowCell(exchanges:  arr[i], willUseAlert: true,manager: self.firestore,rowIndex: i)
                      Divider()
                  }
              }
              HStack{
                  Button {
                      self.showContactUs = true
                  } label: {
                      Text("Request a new exchange")
                          .frame(width: UIScreen.main.bounds.width, height: 50, alignment: .center)
                  }

              }
            .listRowBackground(Color("background"))
          }.padding()
        }
      }
    }
    .fullScreenCover(isPresented: $showContactUs, content: {
        ContactUs( isfromNewExchange: false)
    })
    .onChange(of: self.searchText) { newValue in
        if searchText != "" {
            listArr = firestore.exchangesList.filter{ ($0.name.lowercased().range(of:self.searchText.lowercased()) != nil) }
        }else{
            listArr.removeAll()
        }
    }
  }
}

// MARK: - Preview

struct ExchangesView_Previews: PreviewProvider {
  static var previews: some View {
    ExchangesView()
  }
}
