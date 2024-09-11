//
//  TransactionDetailView.swift
//  Bayliq
//
//  Created by Bhavesh Patel on 03/03/23.
//

import SwiftUI
import CachedAsyncImage

struct TransactionDetailView: View {

    @Environment(\.presentationMode) var presentationMode
    @Binding var showOptions:Bool
    
    @EnvironmentObject private var vm : HomeViewModel
    @EnvironmentObject var firebase: FirestoreManager
    let transaction: ManualTransaction
    @State var currentCurrencyExchangeSymbol: String = ""
    @State private var isSharePresented: Bool = false
    @State var screenShotimage : UIImage?
    @State var isImageDownloaded : Bool = false
    private let columns: [GridItem] = [
      GridItem(.flexible()),
      GridItem(.flexible())
    ]
    private let spacing: CGFloat = 30
    
    var body: some View {
        let scrollContent =
        ZStack {
            // Background Color
            Color("background").ignoresSafeArea(edges: .all)
            VStack{
                HStack {
                    let imageUrl = self.getImageFromlist(name: transaction.exchange!)
                    if imageUrl != ""{
                        CachedAsyncImage(url: URL(string: self.getImageFromlist(name: transaction.exchange!)), urlCache: .imageCache) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image.resizable()
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30,height: 30)
                                    .onAppear{
                                        self.isImageDownloaded = true
                                    }
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30,height: 30)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    Text(transaction.exchange ?? "???").foregroundColor(.white)
                }
                
                topView
                Divider()
                    .padding(.top,10)
                transactionInfo
                    .foregroundColor(.white)
                Spacer()
                Divider()
                    .padding(.top,0)
                    .padding()
            }
        }
       
        return GeometryReader { geometry in
            NavigationView {
                ZStack{
                    ScrollView{
                        scrollContent
                    }
                   // if self.screenShotimage != nil {
                        VStack{
                            Spacer()
                            HStack{
                                Spacer()
                                Button {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0,execute: {
                                        self.screenShotimage = scrollContent.takeScreenshot(origin: geometry.frame(in: .global).origin, size: geometry.size)
                                        if self.screenShotimage != nil {
                                            self.isSharePresented = true
                                        }
                                    })
                                  
                                } label: {
                                    Image(systemName: "square.and.arrow.up").foregroundColor(Color.white)
                                    Text("Share")
                                        .bold()
                                        .font(.system(size: 20))
                                        .foregroundColor(Color.white)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding()
                            }
                        }
                   // }
                }
                .background(Color("background"))
                // .navigationTitle("Transaction details")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.down")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .onChange(of: self.isImageDownloaded) { newValue in
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5,execute: {
//                    self.screenShotimage = scrollContent.takeScreenshot(origin: geometry.frame(in: .global).origin, size: geometry.size)
//                })
            }
            .onTapGesture {
                self.hideKeyboard()
            }
            .sheet(isPresented: $isSharePresented, onDismiss: {
              print("Dismiss")
            }, content: {
                if self.screenShotimage != nil {
                    ActivityViewController(activityItems: [self.screenShotimage!,"https://apps.apple.com/us/app/bayliq/id6443639629"])
                }
            })
        }
    }
    func getImageFromlist(name: String) -> String {
      let exchange = firebase.exchangesList.filter({$0.name == name})
      if exchange.count > 0 {
        return exchange[0].iconURL
      } else {
        let exchange = firebase.exchangesList.filter({$0.name == "Custom Exchange"})
        if exchange.count > 0{
          return exchange[0].iconURL
        } else {
          return ""
        }
      }
    }
    
    func convertTimestamp(serverTimestamp: Double) -> String {
      let x = serverTimestamp /// 1000
      let date = NSDate(timeIntervalSince1970: x)
      let formatter = DateFormatter()
      formatter.dateFormat = "MMM d, yyyy"
      formatter.timeZone = .current
      return formatter.string(from: date as Date)
    }
    
    func convertTimestamp2(serverTimestamp: Double) -> String {
      let x = serverTimestamp /// 1000
      let date = NSDate(timeIntervalSince1970: x)
      let formatter = DateFormatter()
      formatter.dateFormat = "h:mm a"
      formatter.timeZone = .current
      return formatter.string(from: date as Date)
    }
}

struct TransactionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionDetailView( showOptions: .constant(true), transaction: ManualTransaction(id: UUID().uuidString, notes: "NOtes", quantity: 2, marketPrice: 1.0, symbol: "BTC", timestamp: Int(Date.now.timeIntervalSince1970), exchange: "Coinbase", purchasedAt: "USD 1566.0", type: "bought"))
    }
}
extension TransactionDetailView {
    private var transactionInfo : some View {
        HStack{
            VStack(alignment: .leading, spacing: 4){
                VStack(alignment: .leading, spacing: 4){
                    Text("Date transaction: ")
                        .font(.caption)
                        .foregroundColor(Color("secondaryText"))
                    Text(self.convertTimestamp(serverTimestamp: Double(self.transaction.timestamp)))
                        .font(.headline)
                        .foregroundColor(Color("accent"))
                }
                .padding()
                
                VStack(alignment: .leading, spacing: 4){
                    Text("Coin Price at time of purchase: ")
                        .font(.caption)
                        .foregroundColor(Color("secondaryText"))
                    Text(((self.transaction.purchasedAt == "" ? "N/A" : "\(currentCurrencyExchangeSymbol)\(self.formatCurrency(self.transaction.purchasedAt.replacingOccurrences(of: "\(currentCurrencyExchangeSymbol)", with: "")))")))
                        .font(.headline)
                        .foregroundColor(Color("accent"))
                }
                .padding()
                
                if transaction.notes != nil && transaction.notes != "" {
                    VStack(alignment: .leading, spacing: 4){
                        Text("Notes:")
                            .font(.caption)
                            .foregroundColor(Color("secondaryText"))
                        Text(transaction.notes ?? "")
                            .font(.headline)
                            .foregroundColor(Color("accent"))
                    }
                    .padding()
                }
                Spacer()
                
            }
            
            VStack(alignment: .leading, spacing: 4){
                VStack(alignment: .leading, spacing: 4){
                    Text("Purchase Time: ")
                        .font(.caption)
                        .foregroundColor(Color("secondaryText"))
                    Text(self.convertTimestamp2(serverTimestamp: Double(self.transaction.timestamp)))
                        .font(.headline)
                        .foregroundColor(Color("accent"))
                }
                .padding()
                
                VStack(alignment: .leading, spacing: 4){
                    Text("Coin Price in real time now: ")
                        .font(.caption)
                        .foregroundColor(Color("secondaryText"))
                    let coins = self.vm.allCoins.filter{ $0.symbol.lowercased() == self.transaction.symbol.lowercased().components(separatedBy: ",").last ?? ""}
                    if coins.count > 0 {
                        Text("\(self.currentCurrencyExchangeSymbol) \((coins[0].currentPrice ?? 0), specifier: "%0.2f")")
                            .font(.headline)
                            .foregroundColor(Color("accent"))
                    }else{
                        Text("N/A")
                            .font(.headline)
                            .foregroundColor(Color("accent"))
                    }
                    
                }
                .padding()
                Spacer()
            }
        }
    }
    private var topView : some View {
        VStack(spacing: 5){
            let totalNow = (transaction.marketPrice * transaction.quantity)
            Text("\(transaction.quantity.removeZerosFromEnd()) \(transaction.symbol.components(separatedBy: ",").last ?? "")")
                .foregroundColor(.white)
                .font(.system(.title))
                .frame(alignment: .center)
            HStack(alignment: .center){
                Text(currentCurrencyExchangeSymbol)
                    .opacity(0.5)
                    .foregroundColor(.white)
                    .font(.system(size: 25, weight: .medium))
                Text("\(totalNow, specifier: "%0.2f")")
                    .foregroundColor(.white)
                    .font(.system(.largeTitle))
            }
            let purchasedAT = self.transaction.purchasedAt
            let purchaseAmount = (purchasedAT.replacingOccurrences(of: "\(currentCurrencyExchangeSymbol)", with: ""))

            if Double(purchaseAmount) != nil {
                let totalThen = ((Double(purchaseAmount)!)*transaction.quantity)
                
                if totalNow < totalThen {
                    //loss
                    let price = (totalThen - (totalNow))
                    HStack(spacing: 0){
                        Text("-")
                        Text("\(currentCurrencyExchangeSymbol)\(price, specifier: "%0.2f")")
                       
                        let percentage = ((totalNow*100)/totalThen)
                        Text(" (\(percentage-100, specifier: "%0.2f")%)")
                    }
                    .font(.system(size: 14,weight: .medium))
                    .frame(height: 14)
                    .foregroundColor(.white)
                    .padding(.leading,12)
                    .padding(.trailing,12)
                    .padding(.top,10)
                    .padding(.bottom,10)
                    .background(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }else{
                    //profit
                    HStack(spacing: 0){
                        Text("\(currentCurrencyExchangeSymbol)\(((totalNow) - totalThen), specifier: "%0.2f")")
                        let percentage = ((totalNow*100)/totalThen)
                        Text(" (\(percentage-100, specifier: "%0.2f")%)")
                    }
                    .font(.system(size: 14,weight: .medium))
                    .frame(height: 14)
                    .foregroundColor(.white)
                    .padding(.leading,12)
                    .padding(.trailing,12)
                    .padding(.top,10)
                    .padding(.bottom,10)
                    .background(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }
            
            let coin =  vm.allCoins.filter{$0.symbol.lowercased() == self.transaction.symbol.lowercased().components(separatedBy: ",").last ?? ""}
            if coin.count > 0 {
                let x = Double(self.transaction.timestamp) /// 1000
                let date = NSDate(timeIntervalSince1970: x)
               // var days =  Calendar.current.dateComponents([.day], from: date as Date, to: Date.now).day!
                
                //https://api.coingecko.com/api/v3/coins/bitcoin/market_chart?vs_currency=USD&days=1000

                ChartView(coin:coin[0], startingAt: date as Date, nil, true)
                  .padding(.vertical)
            }
        }
    }
    func formatCurrency(_ number: String) -> String{
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.currencySymbol = ""
        if let int = Double(number) {
            guard let formattedNumber = numberFormatter.string(from: NSNumber(value:int)) else { return "\(number)"}
            return formattedNumber
        }else {
            return number
        }
    }
}

extension View {
    func takeScreenshot(origin: CGPoint, size: CGSize) -> UIImage {
        let controller = UIHostingController(rootView: self)
               let view = controller.view

               let targetSize = controller.view.intrinsicContentSize
               view?.bounds = CGRect(origin: .zero, size: targetSize)
               view?.backgroundColor = .clear

               let renderer = UIGraphicsImageRenderer(size: targetSize)

               return renderer.image { _ in
                   view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
               }
    }
}

class AppState: ObservableObject {
    static let shared = AppState()    // << here !!
}
extension Double {
    func removeZerosFromEnd() -> String {
        let formatter = NumberFormatter()
        let number = NSNumber(value: self)
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 16 //maximum digits in Double after dot (maximum precision)
        return String(formatter.string(from: number) ?? "")
    }
}
