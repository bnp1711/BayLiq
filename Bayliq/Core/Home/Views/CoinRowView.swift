//
//  CoinRowView.swift
//  Crypto App
//
//  Created by Nuno Mestre on 8/11/22.
//

import SwiftUI

// MARK: - CoinRowView

struct coinCharts: View {
    let coin: Coin
    var body: some View {
        ChartView(coin: coin, startingAt: nil,50,false)
    }
}

struct CoinRowView: View {
  let coin: Coin
  let showHoldingsColumn: Bool
    @State var currentCurrencyExchangeSymbol: String
  var body: some View { HStack(spacing: 0) {
    leftColumn
    Spacer()
      coinCharts(coin: coin)
          .padding(.leading,10)
    if showHoldingsColumn {
      centerColumn
    }
    rightColumn
  }
  .font(.subheadline)
  }
}

// MARK: - Preview

struct CoinRowView_Previews: PreviewProvider {
  static var previews: some View { Group {
      CoinRowView(coin: dev.coin, showHoldingsColumn: true, currentCurrencyExchangeSymbol: "$")
      .previewLayout(.sizeThatFits)
      CoinRowView(coin: dev.coin, showHoldingsColumn: true, currentCurrencyExchangeSymbol: "$")
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
  }
  }
}

// MARK: - Extension

extension CoinRowView {
  
  private var leftColumn: some View {
    HStack(spacing: 0) {
      Text("\(coin.rank)")
        .font(.caption)
        .foregroundColor(Color("secondaryText"))
        .frame(minWidth: 30)
      CoinImageView(coin: coin)
        .frame(width: 30, height: 30)
      Text(coin.symbol.uppercased())
        .font(.headline)
        .padding(.leading, 6)
        .foregroundColor(Color("accent"))
    }}
  
  private var centerColumn: some View { HStack(spacing: 0) {
    VStack(alignment: .trailing) {
      Text(coin.currentHoldingsValue.asCurrencyWith2Decimals())
        .bold()
      Text((coin.currentHoldings ?? 0).asNumberString())
      
    }
    .foregroundColor(Color("accent"))
  }}
  
  private var rightColumn: some View {
    HStack(spacing: 0) { VStack(alignment: .trailing) {
        Text("\(currentCurrencyExchangeSymbol)\(coin.currentPrice?.asCurrencyWith6Decimals() ?? "0.000000")")
        .bold()
        .foregroundColor((Color("accent")))
      Text(coin.priceChangePercentage24H?.asPercentString() ?? "")
        .foregroundColor(coin.priceChangePercentage24H ?? 0 >= 0 ? Color("green") : Color("red"))
    }
    .padding(.trailing, 8)
    .frame(width: UIScreen.main.bounds.width / 3.5, alignment: .trailing)
    }}
  
}
