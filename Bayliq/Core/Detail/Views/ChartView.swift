//
//  ChartView.swift
//  Crypto App
//
//  Created by Nuno Mestre on 8/20/22.
//

import SwiftUI

struct ChartView: View {
  
  // MARK: - Variables
  
 @State private var data: [Double]
    @State private var maxY: Double
    @State private var minY: Double
    @State private var lineColor: Color
  private let startingDate: Date
  private let endingDate: Date
  @State private var percentage: CGFloat = 0
    private var chartHeight : CGFloat = 200
    var showLabel : Bool
    var coinID = ""
  // MARK: - Init
  
    init(coin: Coin,startingAt:Date?,_ chartHeight: CGFloat?, _ showlabel: Bool) {
        coinID = coin.id
    endingDate = Date(coinGeckoString: coin.lastUpdated ?? "")
        self.showLabel = showlabel
        if let _chartHeight = chartHeight {
            self.chartHeight = _chartHeight
        }
    if let _startingAt = startingAt{
        startingDate = _startingAt
        var days =  Calendar.current.dateComponents([.day], from: startingDate, to: endingDate).day!
        if days < 2 {
            days = 3
        }else if (days > 168) {
            days = 0
        }
        let arraySlice = coin.sparklineIn7D?.price?.suffix(days)
        _data =  State(initialValue: Array(arraySlice!))
        _maxY = State(initialValue: Array(arraySlice!).max() ?? 0)
        _minY = State(initialValue: Array(arraySlice!).min() ?? 0)
        let priceChange = (Array(arraySlice!).last ?? 0) - (Array(arraySlice!).first ?? 0)
        _lineColor = State(initialValue: priceChange > 0 ? Color("green") : Color("red"))
    }else{
        startingDate = endingDate.addingTimeInterval(-7*24*60*60)
        let info = coin.sparklineIn7D?.price ?? []
        _data = State(initialValue: info)
        _maxY = State(initialValue: info.max() ?? 0)
        _minY = State(initialValue: info.min() ?? 0)
        let priceChange = (info.last ?? 0) - (info.first ?? 0)
        _lineColor = State(initialValue: priceChange > 0 ? Color("green") : Color("red"))
    }
        
  }
  
  // MARK: - Body
  
  var body: some View {
    VStack {
      chartView
        .frame(height: chartHeight)
        .background(chartBackground)
        .overlay(chartYAxis.padding(.horizontal, 4), alignment: .leading )
        if showLabel {
            chartDateLabels
                .padding(.horizontal, 4)
        }
    }
    .font(.caption)
    .foregroundColor(Color("secondaryText"))
    .onAppear {
        var days =  Calendar.current.dateComponents([.day], from: startingDate, to: endingDate).day!
        if days > 168 {
            Api().loadCoinPrices(coinID: coinID, days: days) { chart in
                let prices = chart.prices
                var arrPrice = [Double]()
                for i in prices! {
                    arrPrice.append(i[1])
                }
                data =  arrPrice
                maxY = data.max() ?? 0
                minY = data.min() ?? 0
                let priceChange = (data.last ?? 0) - (data.first ?? 0)
                lineColor = priceChange > 0 ? Color("green") : Color("red")
            }
        }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        withAnimation(.linear(duration: 2.0)) {
          percentage = 1.0
        }
      }
    }
  }
}

// MARK: - Preview

struct ChartView_Previews: PreviewProvider {
  static var previews: some View {
      ChartView(coin: dev.coin, startingAt: nil, nil, false)
  }
}

// MARK: - Extension

extension ChartView {
  
  private var chartView: some View {
    GeometryReader { geometry in
      Path { path in
        for index in data.indices {
          let xPosition = geometry.size.width / CGFloat(data.count) * CGFloat(index + 1)
          let yAxis = maxY - minY
          let yPosition = (1 - CGFloat((data[index] - minY) / yAxis)) * geometry.size.height
          if index == 0 {
            path.move(to: CGPoint(x: xPosition, y: yPosition))
          }
          path.addLine(to: CGPoint(x: xPosition, y: yPosition))
        }
      }
      .trim(from: 0, to: percentage)
      .stroke(lineColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
//      .shadow(color: showLabel ? lineColor : Color.clear, radius: 10, x: 0.0, y: 10)
//      .shadow(color: showLabel ? lineColor.opacity(0.5) : Color.clear, radius: 10, x: 0.0, y: 20)
//      .shadow(color: showLabel ? lineColor.opacity(0.2) : Color.clear, radius: 10, x: 0.0, y: 30)
//      .shadow(color: showLabel ? lineColor.opacity(0.1) : Color.clear, radius: 10, x: 0.0, y: 40)
    }
  }
  
  private var chartBackground: some View {
    VStack {
        if showLabel{
            Divider()
        }
      Spacer()
        if showLabel{
            Divider()
        }
      Spacer()
        if showLabel{
            Divider()
        }
    }
  }
  
  private var chartYAxis: some View {
    VStack {
        if showLabel {
            Text(maxY.formattedWithAbbreviations())
            Spacer()
            Text(((maxY + minY) / 2).formattedWithAbbreviations())
            Spacer()
            Text(minY.formattedWithAbbreviations())
        }
    }
  }
  
  private var chartDateLabels: some View {
    HStack {
      Text(startingDate.asShortDateString())
      Spacer()
      Text(endingDate.asShortDateString())
    }
  }  
}

struct ChartViewHome: View {
  
    // MARK: - Variables
    var data: [Double]
    var maxY: Double
    var minY: Double
    var lineColor: Color
    var percentage: CGFloat = 1.0
    var chartHeight : CGFloat = 80
    @Binding var showCharts: Bool

  // MARK: - Body
  
    var body: some View {
        VStack {
            chartView
            .frame(height: chartHeight)
        }
        .font(.caption)
        .foregroundColor(Color("secondaryText"))
    }
}
// MARK: - Extension

extension ChartViewHome {
    private var chartView: some View {
        GeometryReader { geometry in
            Path { path in
                print(data)
                for index in data.indices {
                    let xPosition = geometry.size.width / CGFloat(data.count) * CGFloat(index + 1)
                    let yAxis = maxY - minY
                    let yPosition = (1 - CGFloat((data[index] - minY) / yAxis)) * geometry.size.height
                    if index == 0 {
                    path.move(to: CGPoint(x: xPosition, y: yPosition))
                }
                    path.addLine(to: CGPoint(x: xPosition, y: yPosition))
                }
            }
          .trim(from: 0, to: percentage)
          .stroke(lineColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}
