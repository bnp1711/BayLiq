//
//  CoinImageViewModel.swift
//  Crypto App
//
//  Created by Nuno Mestre on 8/12/22.
//

import Foundation
import SwiftUI
import Combine

class CoinImageViewModel: ObservableObject {
  
  // MARK: - Variables
  
  @Published var image: UIImage?
  @Published var isLoading: Bool = false
  
  private let coin: Coin
  private let dataService: CoinImageService
  private var cancellables = Set<AnyCancellable>()
  
  // MARK: - Init
  
  init(coin: Coin) {
    self.coin = coin
    self.dataService = CoinImageService(coin: coin)
    self.addSubscribers()
    self.isLoading = true
  }
  
  // MARK: - Functions
  
  private func addSubscribers() {
    dataService.$image
      .receive(on: DispatchQueue.main)
      .sink { [weak self] (_) in
        self?.isLoading = false
      } receiveValue: { [weak self] (returnedImage) in
        self?.image = returnedImage
      }
      .store(in: &cancellables)
  }

}
