//
//  MarketDataService.swift
//  Crypto App
//
//  Created by Nuno Mestre on 8/13/22.
//

import Foundation
import Combine

class MarketDataService {
  
  // MARK: - Variables
  
  @Published var marketData: MarketData?
  var marketDataSubscription: AnyCancellable?
  
  // MARK: - Init
  
  init() {
    getData()
  }
  
  // MARK: - Functions
  
  func getData() {
    guard let url = URL(string: "https://pro-api.coingecko.com/api/v3/global?x_cg_pro_api_key=CG-Nm5is1YYnEvKpZSrUAAVZdhs") else { return }
    marketDataSubscription = NetworkingManager.download(url: url)
      .decode(type: GlobalData.self, decoder: JSONDecoder())
      .receive(on: DispatchQueue.main)
      .sink(receiveCompletion: NetworkingManager.handleCompletion, receiveValue: { [weak self] (returnedGlobalData) in
        self?.marketData = returnedGlobalData.data
        self?.marketDataSubscription?.cancel()
      })
  }
}
