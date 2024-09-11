//
//  CoinDataService.swift
//  Crypto App
//
//  Created by Nuno Mestre on 8/12/22.
//

import Foundation
import Combine
import UIKit
import SwiftUI
import Firebase

class CoinDataService:ObservableObject {
    
    // MARK: - Variables
    
    @Published var allCoins: [Coin] = []
    @Published var allSearchCoins: [Coin] = []
    //@AppStorage("pickedCurrencyExchange") var pickedCurrencyExchange = "USD"
    @Binding var pickedCurrencyExchange : String
    var coinSubscription: AnyCancellable?
    var pageNumber: Int = 1
    var pageNumberSearch: Int = 1
    var count = 0
    let db = Firestore.firestore()
    @Published var numberOfCoins : Int = 100
    var isAPIcompleted = false
    var isLoading = false
    var listIds:[String] = []
    // MARK: - Init
    
    init(pickedCurrencyExchange : Binding<String>) {
        self._pickedCurrencyExchange = pickedCurrencyExchange
        isAPIcompleted = false
        getNumberOfCoins()
        getCoins{}
    }
    
    // MARK: - Functions
    func getNumberOfCoins() {
        
        db.collection(FStore.Collections.config)
            .document("NumberOfCoins")
            .getDocument { snap, error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                } else {
                    guard let number = snap?.data()?["Coins"] as? Int else { return }
                    self.numberOfCoins = number
                }
            }
    }
    
    func resetSearch() {
        listIds.removeAll()
        allSearchCoins.removeAll()
        isAPIcompleted = false;
        pageNumberSearch = 1
    }
    
    func search(ids: [String], completion: @escaping () -> Void) {
        pageNumberSearch = 1
        isAPIcompleted = false
        listIds = ids
        getCoins(completion: completion)
    }
    
    
    func reset() {
        pageNumber = 1
        allCoins.removeAll()
        isAPIcompleted = false
    }
    
    func getCoins(completion: @escaping () -> Void) {
        guard !isAPIcompleted, !isLoading, let url = URL(string: "https://pro-api.coingecko.com/api/v3/coins/markets?vs_currency=\(pickedCurrencyExchange.lowercased())&order=market_cap_desc&per_page=100&page=\(!listIds.isEmpty ? pageNumberSearch : pageNumber)&sparkline=true&ids=\(listIds.joined(separator: ","))&price_change_percentage=24h&x_cg_pro_api_key=CG-Nm5is1YYnEvKpZSrUAAVZdhs") else { return }
        
        print("API CALLED \(url)")
        isLoading = true
        
        coinSubscription = NetworkingManager.download(url: url)
            .decode(type: [Coin].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion2 in
                switch completion2 {
                case .failure(let error):
                    print("Error \(error)")
                    self?.isAPIcompleted = false
                case .finished:
                    print("Publisher is finished")
                }
                self?.isLoading = false
                completion()
            }, receiveValue: { [weak self] (returnedCoins) in
                if !(self?.listIds.isEmpty ?? true) {
                    self?.pageNumberSearch += 1
                    self?.allSearchCoins.append(contentsOf: returnedCoins)
                } else {
                    self?.allCoins.append(contentsOf: returnedCoins)
                    self?.pageNumber += 1
                }
                if returnedCoins.count < 100 {
                    self?.isAPIcompleted = true
                }
            })
    }
}


// MARK: - Hashable

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
extension Publisher {
    func stopAfter(_ interval: TimeInterval) -> AnyPublisher<Output, Failure> {
        self
            .timeout(.seconds(interval), scheduler: DispatchQueue.main)
            .scan((Date()+interval, nil)) { ($0.0, $1) }
            .prefix(while: { Date() < $0.0 })
            .map { $0.1! }
            .eraseToAnyPublisher()
    }
}
