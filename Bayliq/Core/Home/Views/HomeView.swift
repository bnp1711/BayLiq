//
//  HomeView.swift
//  Crypto App
//
//  Created by Nuno Mestre on 8/11/22.
//

import SwiftUI

// MARK: - HomeView

struct HomeView: View {
    
    // MARK: - Variables
    
    @ObservedObject var vm: HomeViewModel
    @State private var selectedCoin: Coin?
    @State private var showDetailView: Bool = false
    @Environment(\.dismiss) var dismiss
    
    @Binding var isFromManualTransaction: Bool
    @Binding var TokenName: String
    @Binding var TokenFullName: String
    @Binding var TokenPrice: Double
    @Binding var TokenImage: Image?
    @Binding var presentedAsModal: Bool
    @EnvironmentObject var firestore: FirestoreManager
    @State var listIdCoin = [String]()
    @State var currentCurrencyExchangeSymbol: String
    @State private var isLoading: Bool = false
    @State private var showPortfolio: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Color("background").ignoresSafeArea()
            
            VStack {
                if !isFromManualTransaction {
                    HomeStatsView(showPortfolio: $showPortfolio).padding(.top, 20)
                }
                HStack {
                    if isFromManualTransaction {
                        Button(action: {
                            self.presentedAsModal = false
                        }) {
                            Image(systemName: "chevron.down").foregroundColor(.white)
                        }.padding()
                    }
                    
                    SearchBarView(searchText: $vm.searchText)
                }
                
                columnTitles
                
                if !showPortfolio {
                    if isLoading {
                        ProgressView().padding()
                    } else {
                        allCoinsList.transition(.move(edge: .leading))
                    }
                }
                Spacer(minLength: 0).navigationTitle("Live Prices").navigationBarTitleDisplayMode(.inline)
            }
        }
        .navigationBarBackButtonHidden(true)
        .background(
            NavigationLink(
                destination: DetailLoadingView(coin: $selectedCoin).environmentObject(self.firestore),
                isActive: $showDetailView,
                label: { EmptyView() }
            )
        )
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button(action: { dismiss() }, label: {
                    Image(systemName: "chevron.left").foregroundColor(.white)
                })
            }
        }
        .onAppear {
            vm.reloadData {
                self.isLoading = false
            }
        }
    }
}

// MARK: - Extensions

extension HomeView {
    
    private var allCoinsList: some View {
        ScrollView {
            let arr = !vm.searchText.isEmpty ? vm.coinDataService.allSearchCoins : vm.allCoins
            LazyVStack {
                ForEach(arr) { coin in
                    CoinRowView(coin: coin, showHoldingsColumn: false, currentCurrencyExchangeSymbol: currentCurrencyExchangeSymbol)
                        .onTapGesture {
                            if self.isFromManualTransaction {
                                self.TokenName = coin.symbol.uppercased()
                                self.TokenFullName = coin.name.lowercased()
                                self.TokenPrice = (coin.currentPrice ?? 0)
                                let dataService = CoinImageService(coin: coin)
                                self.TokenImage = (dataService.image != nil) ? Image(uiImage: dataService.image!) : nil
                                self.presentedAsModal = false
                            } else {
                                segue(coin: coin)
                            }
                        }
                }
                if vm.isLoading {
                    ProgressView().padding()
                } else {
                    GeometryReader { proxy in
                        Color.clear.onAppear {
                            if proxy.frame(in: .global).maxY > UIScreen.main.bounds.height * 0.8 {
                                vm.loadMoreData()
                            }
                        }
                    }.frame(height: 50)
                }
            }
        }
        .onChange(of: vm.searchText) { newValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if vm.searchText == newValue {
                    if vm.searchText != "" && vm.searchText.count >= 3 {
                        searchCoins(for: vm.searchText)
                    } else {
                        vm.coinDataService.resetSearch()
                        listIdCoin.removeAll()
                    }
                }
            }
        }
    }
    
    private func searchCoins(for query: String) {
        let ids = vm.coinListService.allCoinsSymbol
            .filter { $0.name?.lowercased().contains(query.lowercased()) ?? false }
            .compactMap { $0.id }
        vm.coinDataService.search(ids: ids) {
            //self.isLoading = false
        }
    }
    
    private func segue(coin: Coin) {
        selectedCoin = coin
        showDetailView.toggle()
    }
    
    private var columnTitles: some View {
        HStack {
            HStack(spacing: 4) {
                Text("Coin")
                Image(systemName: "chevron.down")
                    .opacity((vm.sortOption == .rank || vm.sortOption == .rankReversed) ? 1.0 : 0.0)
                    .rotationEffect(Angle(degrees: vm.sortOption == .rank ? 0 : 180))
            }
            .onTapGesture {
                withAnimation(.default) {
                    vm.sortOption = vm.sortOption == .rank ? .rankReversed : .rank
                }
            }
            Spacer()
            if showPortfolio {
                HStack(spacing: 4) {
                    Text("Holdings")
                    Image(systemName: "chevron.down")
                        .opacity((vm.sortOption == .holdings || vm.sortOption == .holdingsReversed) ? 1.0 : 0.0)
                        .rotationEffect(Angle(degrees: vm.sortOption == .holdings ? 0 : 180))
                }
                .onTapGesture {
                    withAnimation(.default) {
                        vm.sortOption = vm.sortOption == .holdings ? .holdingsReversed : .holdings
                    }
                }
            }
            HStack(spacing: 4) {
                Text("Price")
                Image(systemName: "chevron.down")
                    .opacity((vm.sortOption == .price || vm.sortOption == .priceReversed) ? 1.0 : 0.0)
                    .rotationEffect(Angle(degrees: vm.sortOption == .price ? 0 : 180))
            }
            .onTapGesture {
                withAnimation(.default) {
                    vm.sortOption = vm.sortOption == .price ? .priceReversed : .price
                }
            }
            Button(action: {
                vm.reloadData {
                    self.isLoading = false
                }
            }, label: {
                Image(systemName: "goforward")
            })
        }
        .font(.caption)
        .foregroundColor(Color.gray)
        .padding(.horizontal)
    }
}
