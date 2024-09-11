//
//  API.swift
//  Bayliq
//
//  Created by Bhavesh Patel on 31/03/23.
//

import Foundation
import UIKit
class Api{
    
    func loadCoinPrices(coinID: String,days: Int,completion:@escaping (market_chart) -> ()) {
        guard let url = URL(string: "https://pro-api.coingecko.com/api/v3/coins/\(coinID)/market_chart?vs_currency=USD&days=\(days)&x_cg_pro_api_key=CG-Nm5is1YYnEvKpZSrUAAVZdhs") else {
            print("Invalid url...")
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            let data = try! JSONDecoder().decode(market_chart.self, from: data!)
            print(data)
            DispatchQueue.main.async {
                completion(data)
            }
        }.resume()
        
    }
    
    func getCoinPriceForDate(coinID: String,date: String,completion:@escaping (CoinHistory) -> ()) {
        guard let url = URL(string: "https://pro-api.coingecko.com/api/v3/coins/\(coinID)/history?date=\(date)&x_cg_pro_api_key=CG-Nm5is1YYnEvKpZSrUAAVZdhs") else {
            print("Invalid url...")
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            let data = try! JSONDecoder().decode(CoinHistory.self, from: data!)
            print(data)
            DispatchQueue.main.async {
                completion(data)
            }
        }.resume()
        
    }
}
extension Date
{
    func toString( dateFormat format  : String ) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }

}
