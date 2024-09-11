//
//  CustomExchangeView.swift
//  Bayliq
//
//  Created by Irfan on 11/27/22.
//

import SwiftUI
import AVFoundation
import CachedAsyncImage

struct CustomExchangeView: View {
  
  // MARK: - Variables
  @Environment(\.presentationMode) var presentationMode
  @Binding var selection: Int
  @Binding var showOptions:Bool
  @State var options: [CryptoExchange]
  @State private var showTextfield = false
  @Binding var customText: String
    @State var searchText = ""
      @State var listArr = [CryptoExchange]()
  // MARK: - Views
  
  var body: some View {
    ZStack {
        Color("background")
        VStack{
            HStack {
                Button(action: {
                    self.showOptions = false
                }) {
                  Image(systemName: "chevron.down")
                    .foregroundColor(.white)
                }
                .padding()
                SearchBarView(searchText: $searchText)
            }
            
            List{
                let arr = listArr.count > 0 ? listArr : options
                ForEach(arr) { exchange in
                    FinalExchangeRowCell(exchanges: exchange, willUseAlert: false)
                    .onTapGesture {
                        withAnimation(Animation.spring().speed(2)) {
                            if exchange.name  == "Custom Exchange"{
                                showTextfield = true
                            } else {
                                customText = ""
                                selection = options.firstIndex(of: exchange)!
                                showOptions = false
                            }
                        }
                    }
                }
                .listRowBackground(Color("background"))
            }
        }
      .listStyle(.plain)
      
    }
    .onChange(of: self.searchText) { newValue in
        if searchText != "" {
            listArr = options.filter{ ($0.name.lowercased().range(of:self.searchText.lowercased()) != nil) }
        }else{
            listArr.removeAll()
        }
    }
    if showTextfield {
//      Color("background").opacity(0.7)
//        .transition(.opacity)
      textfieldView
        .transition(.scale)
      
    }
    
  }
  
  var textfieldView:some View {
    
    VStack {
      TextField("", text: $customText).disableAutocorrection(true).padding().foregroundColor(.white).keyboardType(.default).cornerRadius(12)
        .placeholder(when: customText.isEmpty) {
          Text("Enter custom Exchange ").foregroundColor(Color.white).offset(x: 15, y: 0)
        }
        .overlay {
          RoundedRectangle(cornerRadius: 12).stroke(Color("loginFields"), lineWidth: 2)
        }
        .padding(.horizontal)
        .padding(.bottom, 5)
      
      HStack(spacing: 25) {
        Button(action: {
          withAnimation(.spring()){
            showTextfield = false
            showOptions = false
            options.insert(CryptoExchange(iconURL: "", name: customText, websiteURL: ""), at: options.count - 1)
            selection = options.count - 2
          }
          
        }) {
          Text("Ok")
            .foregroundColor(.white)
            .padding(10)
            .padding(.horizontal, 10)
            .background(Color("orange"))
            .cornerRadius(10)
        }.customButtonStyle()
        Button(action: {
          withAnimation(.spring()){
            showTextfield = false
            
          }
        }) {
          Text("Cancel")
            .foregroundColor(.white)
            .padding(10)
            .padding(.horizontal, 10)
            .background(Color("orange"))
            .cornerRadius(10)
        }.customButtonStyle()
      }
    }
    .padding(30)
    .background(RoundedRectangle(cornerRadius: 10).fill(Color("background")))
  }
}

// MARK: - Preview

//struct CustomExchangeView_Previews: PreviewProvider {
//  static var previews: some View {
//    CustomExchangeView( selection: .constant(1), showOptions: .constant(true), options: .constant([CryptoExchange()]))
//  }
//}

// MARK: - CustomExchangeRowCell

struct CustomExchangeRowCell: View {
    @ObservedObject var manager: FirestoreManager
  @Environment(\.openURL) var openURL
    @State private var isSelected1: Bool?
  let exchanges: CryptoExchange
  @State private var showingAlert = false
  var willUseAlert = false
    let rowIndex: Int
  
    init(exchanges: CryptoExchange, willUseAlert: Bool, manager:FirestoreManager,rowIndex: Int){
    self.exchanges = exchanges
    self.willUseAlert = willUseAlert
        self.manager = manager
        self.rowIndex = rowIndex
//    self.isSelected1 = !(manager.unCheckedexchangesList.contains(self.exchanges))
    
  }
  
  var body: some View {
      ZStack{
          HStack {
              HStack{
                  Text("\(rowIndex+1)")
                      .foregroundColor(.white)
                      .frame(alignment: .leading)
                  
                  VStack {
                      CachedAsyncImage(url: URL(string: exchanges.iconURL), urlCache: .imageCache) { phase in
                          switch phase {
                          case .empty:
                              ProgressView()
                          case .success(let image):
                              image.resizable()
                                  .aspectRatio(contentMode: .fit)
                                  .frame(maxWidth: 30, maxHeight: 30)
                          case .failure:
                              Image(systemName: "photo")
                          @unknown default:
                              EmptyView()
                          }
                      }
                  }
                  
                  
                  Text(exchanges.name)
                      .foregroundColor(.white)
                      .frame(alignment: .leading)
                  if !((manager.unCheckedexchangesList.filter{$0.name == self.exchanges.name}).count > 0) {
                      Spacer()
                      Image(systemName: "checkmark.square")
                          .resizable()
                          .frame(width: 20,height: 20,alignment: .trailing)
                          .foregroundColor(.white)
                          .padding(.trailing,50)
                          
                  }else{
                      Spacer()
                      Image(systemName: "square")
                          .resizable()
                          .frame(width: 20,height: 20,alignment: .trailing)
                          .foregroundColor(.white)
                          .padding(.trailing,50)
                          
                  }
              }
              
              .onTapGesture {
                  isSelected1 = (manager.unCheckedexchangesList.filter{$0.name == self.exchanges.name}).count > 0
                  if isSelected1 == false{
                      manager.uploadUncheckedExchange(exchange: self.exchanges) { err in
                          if err != nil {
                              print("ERROR: " + err!.localizedDescription)
                          }
                      }
                  }else{
                      manager.removeCheckedExchange(exchange: self.exchanges) { err in
                          if err != nil {
                              print("ERROR: " + err!.localizedDescription)
                          }
                      }
                  }
              }
              Image(systemName: "chevron.forward")
                  .frame(maxWidth: 20, maxHeight: .infinity, alignment: .trailing)
                  .foregroundColor(.white)
                  .onTapGesture {
                      if willUseAlert {
                          self.showingAlert = true
                      }
                  }
          }
      }
      
    .frame(height: 38.0)
    .alert(isPresented:$showingAlert) {
      Alert(
        title: Text("Are you sure you want to leave the app?"),
        message: Text(""),
        primaryButton: .default(Text("Yes")) {
          openURL(URL(string: exchanges.websiteURL)!)
        },
        secondaryButton: .destructive(Text("Cancel"))
      )
    }
  }
  
}

// MARK: - FinalExchangeRowCell

struct FinalExchangeRowCell: View {
  
  @Environment(\.openURL) var openURL
  let exchanges: CryptoExchange
  @State private var showingAlert = false
  var willUseAlert = false
  
init(exchanges: CryptoExchange, willUseAlert: Bool){
    self.exchanges = exchanges
    self.willUseAlert = willUseAlert
  }
  
  var body: some View {
    HStack {
      VStack {
          CachedAsyncImage(url: URL(string: exchanges.iconURL), urlCache: .imageCache) { phase in
          switch phase {
          case .empty:
              ProgressView()
          case .success(let image):
            image.resizable()
              .aspectRatio(contentMode: .fit)
              .frame(maxWidth: 30, maxHeight: 30)
          case .failure:
            Image(systemName: "photo")
          @unknown default:
            EmptyView()
          }
        }
      }
      Text(exchanges.name)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
      Image(systemName: "chevron.forward")
        .frame(maxWidth: 20, maxHeight: .infinity, alignment: .trailing)
        .foregroundColor(.white)
        .onTapGesture {
          if willUseAlert {
            self.showingAlert = true
          }
        }
    }
    
    .frame(height: 38.0)
    .alert(isPresented:$showingAlert) {
      Alert(
        title: Text("Are you sure you want to leave the app?"),
        message: Text(""),
        primaryButton: .default(Text("Yes")) {
          openURL(URL(string: exchanges.websiteURL)!)
        },
        secondaryButton: .destructive(Text("Cancel"))
      )
    }
  }
  
}
