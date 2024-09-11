//
//  CoinImageService.swift
//  Crypto App
//
//  Created by Nuno Mestre on 8/12/22.
//

import Foundation
import SwiftUI
import Combine

class CoinImageService {
  
  // MARK: - Variables
  
  @Published var image: UIImage?
  private var imageSubscription: AnyCancellable?
  private let coin: Coin
  private let fileManager = LocalFileManager.instance
  private let folderName = "coin_images"
  private let imageName: String
  
  // MARK: - Init
  
  init(coin: Coin) {
    self.coin = coin
    self.imageName = coin.id
    getCoinImage()
  }
  
  // MARK: - Functions
  
  private func getCoinImage() {
    if let savedImage = fileManager.getImage(imageName: coin.id, folderName: folderName) {
      image = savedImage
    } else {
      downloadCoinImage()
    }
  }
  
  private func downloadCoinImage() {
    guard let url = URL(string: coin.image) else { return }
    imageSubscription = NetworkingManager.download(url: url)
      .tryMap({ (data) -> UIImage? in
        return UIImage(data: data)
      })
      .receive(on: DispatchQueue.main)
      .sink(receiveCompletion: NetworkingManager.handleCompletion, receiveValue: { [weak self] (returnedImage) in
        guard let self = self, let downloadedImage = returnedImage else { return }
        self.image = downloadedImage
        self.imageSubscription?.cancel()
        self.fileManager.saveImage(image: downloadedImage, imageName: self.imageName, folderName: self.folderName)
      })
  }

}
