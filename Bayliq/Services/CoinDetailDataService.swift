//
//  CoinDetailDataService.swift
//  Crypto App
//
//  Created by Nuno Mestre on 8/20/22.
//

import Foundation
import Combine

class CoinDetailDataService {
  
  // MARK: - Variables
  
  @Published var coinDetails: CoinDetail?
  var coinDetailSubscription: AnyCancellable?
  let coin: Coin
  
  // MARK: - Init
  
  init(coin: Coin) {
    self.coin = coin
    getCoinDetails()
  }
  
  // MARK: - Functions
  
  func getCoinDetails() {
    guard let url = URL(string: "https://pro-api.coingecko.com/api/v3/coins/\(coin.id)?localization=false&tickers=false&market_data=false&community_data=false&developer_data=false&sparkline=false&x_cg_pro_api_key=CG-Nm5is1YYnEvKpZSrUAAVZdhs") else { return }
    coinDetailSubscription = NetworkingManager.download(url: url)
      .decode(type: CoinDetail.self, decoder: JSONDecoder())
      .receive(on: DispatchQueue.main)
      .sink(receiveCompletion: NetworkingManager.handleCompletion, receiveValue: { [weak self] (returnedCoinDetails) in
        self?.coinDetails = returnedCoinDetails
        self?.coinDetailSubscription?.cancel()
      })
  }
}
