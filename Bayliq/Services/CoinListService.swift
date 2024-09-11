//
//  CoinListService.swift
//  Bayliq
//
//  Created by Dmitry Magadya on 1.07.24.
//

import Foundation
import Combine

class CoinListService {

    // MARK: - Variables
    @Published var allCoinsSymbol: [CoinSymbol] = []
    private var coinListSubscription: AnyCancellable?

    // MARK: - Init
    init() {
        fetchCoinList()
    }

    // MARK: - Functions
    private func fetchCoinList() {
        guard let url = URL(string: "https://pro-api.coingecko.com/api/v3/coins/list?x_cg_pro_api_key=CG-Nm5is1YYnEvKpZSrUAAVZdhs") else {
            print("Invalid URL.")
            return
        }
        
        coinListSubscription = NetworkingManager.download(url: url)
            .decode(type: [CoinSymbol].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: handleCompletion, receiveValue: handleReceivedCoins)
    }
    
    private func handleCompletion(_ completion: Subscribers.Completion<Error>) {
        switch completion {
        case .failure(let error):
            print("Error: \(error)")
        case .finished:
            break
        }
    }
    
    private func handleReceivedCoins(_ returnedCoins: [CoinSymbol]) {
        self.allCoinsSymbol = returnedCoins
        print("Coins count: \(self.allCoinsSymbol.count)")
    }
}

