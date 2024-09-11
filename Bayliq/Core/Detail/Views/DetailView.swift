//
//  DetailView.swift
//  Crypto App
//
//  Created by Nuno Mestre on 8/20/22.
//

import SwiftUI
import Firebase

// MARK: - DetailLoadingView

struct DetailLoadingView: View {
  @Binding var coin: Coin?
    @EnvironmentObject var firebase : FirestoreManager
  var body: some View {
    ZStack {
      if let coin = coin {
          DetailView(coin: coin, firestore: firebase)
      }
    }
  }
}

// MARK: - DetailView

struct DetailView: View {
  
  // MARK: - Variables
  
  let db = Firestore.firestore()
    @ObservedObject var firestore: FirestoreManager
//  @ObservedObject var firestore = FirestoreManager()
  @StateObject private var vm: DetailViewModel
  @Environment(\.dismiss) var dismiss
  @State private var showFullDescription: Bool = false
  @State private var addCoin: Bool = false
  
  private let columns: [GridItem] = [
    GridItem(.flexible()),
    GridItem(.flexible())
  ]
  
  private let spacing: CGFloat = 30
  var isFullScreenCover: Bool
  // MARK: - Init
  
    init(coin: Coin, isFullScreenCover: Bool = false,firestore: FirestoreManager) {
        self.firestore = firestore
    _vm = StateObject(wrappedValue: DetailViewModel(coin: coin))
    self.isFullScreenCover = isFullScreenCover
        
//    firestore.getUserData()
        
  }
  
  // MARK: - Body
  
  var body: some View {
    VStack {
      if isFullScreenCover {
        HStack{
          Button(action: {
            dismiss()
          }, label: {
            Image(systemName: "xmark")
              .font(.system(size: 18, weight: .semibold))
              .foregroundColor(.white)
          })
          Spacer()
          HStack {
            Text(vm.coin.symbol.uppercased())
              .font(.system(size: 18, weight: .bold))
              .foregroundColor(Color("secondaryText"))
            CoinImageView(coin: vm.coin)
              .frame(width: 20, height: 20)
          }
        }.overlay(
          Text(vm.coin.name)
            .foregroundColor(.white)
            .font(.system(size: 18, weight: .semibold))
        )
        .padding()
      }
      ScrollView {
        VStack {
            ChartView(coin: vm.coin,startingAt: nil, nil, true)
            .padding(.vertical)
          
          VStack(spacing: 20) {
            overviewTitle
            Divider()
            descriptionSection
            overviewGrid
            additionalTitle
            Divider()
            additionalGrid
            websiteSection
          }
          .padding()
        }
      }
    }
    .background(
      Color("background")
        .ignoresSafeArea()
    )
    .navigationBarTitleDisplayMode(.inline)
    .navigationBarBackButtonHidden(true)
    .navigationTitle(vm.coin.name)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        navigationBarTrailingItems
      }
        
    }
    .toolbar{
        ToolbarItemGroup(placement: .navigationBarLeading) {
          Button(action: {
            dismiss()
          }, label: {
            Image(systemName: "chevron.left")
              .foregroundColor(.white)
          })
        }
    }
  }
  
}

// MARK: - Preview

struct DetailView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
        DetailView(coin: dev.coin, firestore: FirestoreManager())
    }
  }
}

// MARK: - Components

extension DetailView {
  
  private var navigationBarTrailingItems: some View {
    HStack {
      Text(vm.coin.symbol.uppercased())
        .font(.headline)
        .foregroundColor(Color("secondaryText"))
      CoinImageView(coin: vm.coin)
        .frame(width: 25, height: 25)
    }
  }
  
  private var overviewTitle: some View {
    Text("Overview")
      .font(.title)
      .bold()
      .foregroundColor(Color("accent"))
      .frame(maxWidth: .infinity, alignment: .leading)
  }
  
  private var additionalTitle: some View {
    Text("Additional Details")
      .font(.title)
      .bold()
      .foregroundColor(Color("accent"))
      .frame(maxWidth: .infinity, alignment: .leading)
  }
  
  private var descriptionSection: some View {
    ZStack {
      if let coinDescription = vm.coinDescription,
         !coinDescription.isEmpty {
        VStack(alignment: .leading) {
          Text(coinDescription)
            .lineLimit(showFullDescription ? nil : 3)
            .font(.callout)
            .foregroundColor(Color("secondaryText"))
          
          Button(action: {
            withAnimation(.easeInOut) {
              showFullDescription.toggle()
            }
          }, label: {
            Text(showFullDescription ? "Less" : "Read more..")
              .font(.caption)
              .fontWeight(.bold)
              .padding(.vertical, 4)
          })
          .accentColor(.blue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }
  
  private var overviewGrid: some View {
    LazyVGrid(
      columns: columns,
      alignment: .leading,
      spacing: spacing,
      pinnedViews: [],
      content: {
        ForEach(vm.overviewStatistics) { stat in
          StatisticView(stat: stat)
        }
      })
  }
  
  private var additionalGrid: some View {
    LazyVGrid(
      columns: columns,
      alignment: .leading,
      spacing: spacing,
      pinnedViews: [],
      content: {
        ForEach(vm.additionalStatistics) { stat in
          StatisticView(stat: stat)
        }
      })
  }
  
  private var websiteSection: some View {
    VStack(alignment: .leading, spacing: 20) {
      if let websiteString = vm.websiteURL,
         let url = URL(string: websiteString) {
        Link("Website", destination: url)
      }
    }
    .accentColor(.blue)
    .frame(maxWidth: .infinity, alignment: .leading)
    .font(.headline)
  }
  
}
