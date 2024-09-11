//
//  CurrencyExchangeService.swift
//  Bayliq
//
//  Created by Natanael Jop on 24/11/2022.
//

import SwiftUI

class CurrencyExchangeService: ObservableObject {
  @Published var allExchanges = [String : Double]()
  @Published var allSymbols = [String : String]()
  
  init() {
    self.getAllExchanges()
    self.getAllSymbols()
  }
  
  func getAllExchanges() {
    let url = "https://api.exchangerate.host/latest?base=USD"
    let session = URLSession(configuration: .default)
    session.dataTask(with: URLRequest(url: URL(string: url)!)) { data, response, error in
      if let error = error {
        print("Error: \(error.localizedDescription)")
      } else if let data = data {
        do {
          let conversion = try JSONDecoder().decode(ExchangeResponse.self, from: data)
          DispatchQueue.main.async {
            self.allExchanges = conversion.rates
          }
        } catch let error {
          print(error.localizedDescription)
        }
      }
    }.resume()
  }
  
  func getAllSymbols() {
    let url = "https://gist.githubusercontent.com/stevekinney/8334552/raw/28d6e58f99ba242b7f798a27877e2afce75a5dca/currency-symbols.json"
    let session = URLSession(configuration: .default)
    session.dataTask(with: URLRequest(url: URL(string: url)!)) { data, _, error in
      if let error = error {
        print("Error: \(error.localizedDescription)")
      } else if let data = data {
        do {
          let conversion = try JSONDecoder().decode([Symbol].self, from: data)
          print(conversion, "conversion")
          for sym in conversion {
            DispatchQueue.main.async {
              self.allSymbols[sym.abbreviation ?? ""] = sym.symbol ?? ""
            }
          }
        } catch let error {
          print("Error: \(error.localizedDescription)")
        }
      }
    }.resume()
  }
}
