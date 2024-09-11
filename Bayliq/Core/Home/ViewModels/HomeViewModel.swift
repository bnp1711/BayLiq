//
//  HomeViewModel.swift
//  Crypto App
//
//  Created by Nuno Mestre on 8/12/22.
//

import Foundation
import Combine
import SwiftUI

class HomeViewModel: ObservableObject {
    
    // MARK: - SortOption
    
    enum SortOption {
        case rank, rankReversed, holdings, holdingsReversed, price, priceReversed
    }
    
    // MARK: - Variables
    
    @Published var statistics: [Statistic] = []
    @Published var allCoins: [Coin] = []
    @Published var portfolioCoins: [Coin] = []
    @Published var isLoading: Bool = false
    @Published var searchText: String = ""
    @Published var sortOption: SortOption = .holdings
    @AppStorage("pickedCurrencyExchange") var pickedCurrencyExchange = "USD"
    var coinDataService : CoinDataService! = nil
    var marketDataService = MarketDataService()
    var coinListService = CoinListService()
    private var cancellables = Set<AnyCancellable>()
    let pub = Future<Result<Void, Error>, Never> {
        promise in
        // Do something asynchronous
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            promise(.success(.success(())))
            //or
            //promise(.success(.failure(error)))
        }
    }.eraseToAnyPublisher()
    
    
    // MARK: - Init
    
    init() {
        coinDataService =  CoinDataService(pickedCurrencyExchange: $pickedCurrencyExchange)
        //    addSubscribers{}
        cancellables.insert(
            coinDataService.objectWillChange.sink { complition in
                
            } receiveValue: {[weak self] _ in
                self?.objectWillChange.send()
            }
        )
        
        
    }
    
    
    // MARK: - Functions
    
    
    func addSubscribers(completion: @escaping (_ err: String?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 20, execute: {
            if  self.coinDataService.isAPIcompleted  == false {
                completion("Error: No Data found")
            }
        })
        
        // updates allCoins
        $searchText
            .combineLatest(coinDataService.$allCoins, $sortOption)
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .map(filterAndSortCoins)
        //      .timeout(.seconds(20), scheduler: DispatchQueue.main)
            .sink {[weak self] (returnedCoins) in
                self?.allCoins =  ((self?.allCoins ?? []) + returnedCoins).uniqued()
                print("ALLCOINTs: \(String(describing: self?.allCoins.count))")
                //UNCOMMENT AFTER TEST
                if (self?.allCoins.count)!  > 0{
                    completion(nil)
                }else if self?.allCoins.count == 0, self?.coinDataService.isAPIcompleted == true {
                    completion("Error: No Data found")
                }
            }
            .store(in: &cancellables)
        // updates marketData
        marketDataService.$marketData
            .combineLatest($portfolioCoins)
            .map(mapGlobalMarketData)
            .sink { [weak self] (returnedStats) in
                self?.statistics = returnedStats
                self?.isLoading = false
                
            }
            .store(in: &cancellables)
    }
    
    func reloadData(completion: @escaping () -> Void) {
        isLoading = true
        coinDataService.reset()
        coinDataService.getCoins {
            self.isLoading = false
            completion()
        }
        marketDataService.getData()
        HapticManager.notification(type: .success)
    }
    
    func loadMoreData() {
        guard !isLoading else { return }
        isLoading = true
        coinDataService.getCoins {
            DispatchQueue.main.async {
                self.isLoading = false
                self.allCoins = self.coinDataService.allCoins
            }
        }
    }
    
    
    func getCoinData(completion: @escaping () -> Void){
        isLoading = true
        coinDataService.allCoins.removeAll()
        coinDataService.getCoins{
            self.isLoading = false
            completion()
        }
    }
    
    
    private func filterAndSortCoins(text: String, coins: [Coin], sort: SortOption) -> [Coin] {
        var updatedCoins = filterCoins(text: text, coins: coins)
        sortCoins(sort: sort, coins: &updatedCoins)
        return updatedCoins
    }
    
    private func filterCoins(text: String, coins: [Coin]) -> [Coin] {
        guard !text.isEmpty else {
            return coins
        }
        let lowercasedText = text.lowercased()
        return coins.filter { (coin) -> Bool in
            return coin.name.lowercased().contains(lowercasedText) ||
            coin.symbol.lowercased().contains(lowercasedText) ||
            coin.id.lowercased().contains(lowercasedText)
        }
    }
    
    private func sortCoins(sort: SortOption, coins: inout [Coin]) {
        switch sort {
        case .rank, .holdings:
            coins.sort(by: { $0.rank < $1.rank })
        case .rankReversed, .holdingsReversed:
            coins.sort(by: { $0.rank > $1.rank })
        case .price:
            coins.sort(by: { ($0.currentPrice ?? 0) > ($1.currentPrice ?? 0) })
        case .priceReversed:
            coins.sort(by: { ($0.currentPrice ?? 0) < ($1.currentPrice ?? 0) })
        }
    }
    
    private func mapGlobalMarketData(marketDataModel: MarketData?, portfolioCoins: [Coin]) -> [Statistic] {
        var stats: [Statistic] = []
        guard let data = marketDataModel else {
            return stats
        }
        let marketCap = Statistic(title: "Market Cap", value: data.marketCap, percentageChange: data.marketCapChangePercentage24HUsd)
        let volume = Statistic(title: "24h Volume", value: data.volume)
        let btcDominance = Statistic(title: "BTC Dominance", value: data.btcDominance)
        let portfolioValue =
        portfolioCoins
            .map({ $0.currentHoldingsValue })
            .reduce(0, +)
        let previousValue =
        portfolioCoins
            .map { (coin) -> Double in
                let currentValue = coin.currentHoldingsValue
                let percentChange = coin.priceChangePercentage24H ?? 0 / 100
                let previousValue = currentValue / (1 + percentChange)
                return previousValue
            }
            .reduce(0, +)
        let percentageChange = ((portfolioValue - previousValue) / previousValue)
        let portfolio = Statistic(
            title: "Portfolio Value",
            value: portfolioValue.asCurrencyWith2Decimals(),
            percentageChange: percentageChange)
        stats.append(contentsOf: [
            marketCap,
            volume,
            btcDominance,
            portfolio
        ])
        return stats
    }
    
}
extension CurrentValueSubject where Output == Void {
    
    func sink(receiveCompletion: @escaping ((Subscribers.Completion<Failure>) -> Void)) -> AnyCancellable {
        sink(receiveCompletion: receiveCompletion, receiveValue: {})
    }
}
