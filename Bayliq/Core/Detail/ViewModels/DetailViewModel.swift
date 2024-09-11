//
//  DetailViewModel.swift
//  Crypto App
//
//  Created by Nuno Mestre on 8/20/22.
//

import Foundation
import Combine

class DetailViewModel: ObservableObject {
  
  // MARK: - Variables
  
  @Published var overviewStatistics: [Statistic] = []
  @Published var additionalStatistics: [Statistic] = []
  @Published var coinDescription: String?
  @Published var websiteURL: String?
  @Published var redditURL: String?
  
  @Published var coin: Coin
  
  private let coinDetailService: CoinDetailDataService
  private var cancellables = Set<AnyCancellable>()
  
  // MARK: - Init
  
  init(coin: Coin) {
    self.coin = coin
    self.coinDetailService = CoinDetailDataService(coin: coin)
    self.addSubscribers()
  }
  
  // MARK: - Functions
  
  private func addSubscribers() {
    coinDetailService.$coinDetails
      .combineLatest($coin)
      .map(mapDataToStatistics)
      .sink { [weak self] (returnedArrays) in
        self?.overviewStatistics = returnedArrays.overview
        self?.additionalStatistics = returnedArrays.additional
      }
      .store(in: &cancellables)
    coinDetailService.$coinDetails
      .sink { [weak self] (returnedCoinDetails) in
        self?.coinDescription = returnedCoinDetails?.readableDescription
        self?.websiteURL = returnedCoinDetails?.links?.homepage?.first
        self?.redditURL = returnedCoinDetails?.links?.subredditURL
      }
      .store(in: &cancellables)
  }
  
  private func mapDataToStatistics(coinDetailModel: CoinDetail?, coinModel: Coin) -> (overview: [Statistic], additional: [Statistic]) {
    let overviewArray = createOverviewArray(coinModel: coinModel)
    let additionalArray = createAdditionalArray(coinDetailModel: coinDetailModel, coinModel: coinModel)
    return (overviewArray, additionalArray)
  }
  
  private func createOverviewArray(coinModel: Coin) -> [Statistic] {
      let price = coinModel.currentPrice?.asCurrencyWith6Decimals() ?? "0.000000"
    let pricePercentChange = coinModel.priceChangePercentage24H
    let priceStat = Statistic(title: "Current Price", value: price, percentageChange: pricePercentChange)
    let marketCap = "$" + (coinModel.marketCap?.formattedWithAbbreviations() ?? "")
    let marketCapPercentChange = coinModel.marketCapChangePercentage24H
    let marketCapStat = Statistic(title: "Market Capitalization", value: marketCap, percentageChange: marketCapPercentChange)
    let rank = "\(coinModel.rank)"
    let rankStat = Statistic(title: "Rank", value: rank)
    let volume = "$" + (coinModel.totalVolume?.formattedWithAbbreviations() ?? "")
    let volumeStat = Statistic(title: "Volume", value: volume)
    let overviewArray: [Statistic] = [
      priceStat, marketCapStat, rankStat, volumeStat
    ]
    return overviewArray
  }
  
  private func createAdditionalArray(coinDetailModel: CoinDetail?, coinModel: Coin) -> [Statistic] {
    let high = coinModel.high24H?.asCurrencyWith6Decimals() ?? "n/a"
    let highStat = Statistic(title: "24h High", value: high)
    let low = coinModel.low24H?.asCurrencyWith6Decimals() ?? "n/a"
    let lowStat = Statistic(title: "24h Low", value: low)
    let priceChange = coinModel.priceChange24H?.asCurrencyWith6Decimals() ?? "n/a"
    let pricePercentChange = coinModel.priceChangePercentage24H
    let priceChangeStat = Statistic(title: "24h Price Change", value: priceChange, percentageChange: pricePercentChange)
    let marketCapChange = "$" + (coinModel.marketCapChange24H?.formattedWithAbbreviations() ?? "")
    let marketCapPercentChange = coinModel.marketCapChangePercentage24H
    let marketCapChangeStat = Statistic(title: "24h Market Cap Change", value: marketCapChange, percentageChange: marketCapPercentChange)
    let blockTime = coinDetailModel?.blockTimeInMinutes ?? 0
    let blockTimeString = blockTime == 0 ? "n/a" : "\(blockTime)"
    let blockStat = Statistic(title: "Block Time", value: blockTimeString)
    let hashing = coinDetailModel?.hashingAlgorithm ?? "n/a"
    let hashingStat = Statistic(title: "Hashing Algorithm", value: hashing)
    let additionalArray: [Statistic] = [
      highStat, lowStat, priceChangeStat, marketCapChangeStat, blockStat, hashingStat
    ]
    return additionalArray
  }
  
}
