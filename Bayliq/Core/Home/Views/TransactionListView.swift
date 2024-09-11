//
//  TransactionListView.swift
//  Bayliq
//
//  Created by Bhavesh Patel on 11/22/22.
//

import SwiftUI
import CachedAsyncImage

/// Contains a list of all transactions from `manualTransactions`
/// Sort by All, Bought, and Sold
struct TransactionListView: View {
  
  // MARK: - Variables
    
    @EnvironmentObject private var vm : HomeViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var firestore: FirestoreManager
  
    @Binding var manualTransactions : [ManualTransaction]
//    @ObservedObject var firestore = FirestoreManager()
  
    let typeOptions = ["All","Bought", "Sold"]
    @State private var pickedType = 0
    @State var currentCurrencyExchangeSymbol: String = ""
    
    // MARK: - Body
  
  var body: some View {
    NavigationView {
      ZStack {
        // Background Color
        Color("background").ignoresSafeArea(edges: .all)
        
        VStack{
          SegmentedPicker(items: typeOptions, selection: $pickedType)
            .padding(.horizontal)
          GeometryReader { geometry in
            List{
              ForEach(manualTransactions.filter({
                // Check the selection and filter
                if pickedType == 1 {
                  return  $0.type == "bought"
                } else if pickedType == 2 {
                  return $0.type == "sold"
                } else {
                  return true
                }
              }).sorted(by: {$0.index ?? 0 > $1.index ?? 1})) { transaction in
                  TransactionCell(transaction: transaction,currentCurrencyExchangeSymbol: self.currentCurrencyExchangeSymbol)
                      .environmentObject(vm)
                      .environmentObject(firestore)
                  .listRowBackground(
                    RoundedRectangle(cornerRadius: 5)
                      .background(.clear)
                      .foregroundColor(Color("darkBlue"))
                      .padding(
                        EdgeInsets(
                          top: 2,
                          leading: 10,
                          bottom: 4,
                          trailing: 10
                        )
                      )
                  )
                  .listRowSeparator(.hidden)
                
              }
              .onDelete(perform: deleteItems)
              .padding(0)
            }
            .overlay(Group {
              if (manualTransactions.filter({
                // Check the selection and filter
                if pickedType == 1 {
                  return  $0.type == "bought"
                } else if pickedType == 2 {
                  return $0.type == "sold"
                } else {
                  return true
                }
              }).isEmpty) {
                VStack {
                  Text("No transactions")
                    .font(.system(size: 24.0))
                    .bold()
                    .foregroundColor(.white)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color("background"))
              }
            })
            .background(Color("background"))
            .listStyle(.plain)
          }
        }
      }
      .onAppear{
        DispatchQueue.main.asyncAfter(deadline: .now()) {
          // getAllManualTransactions()
        }
      }
      .background(Color.clear)
      .navigationTitle("Transactions")
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button(action: {
            dismiss()
          }) {
            Image(systemName: "chevron.down")
              .foregroundColor(.white)
          }
        }
      }
    }
  }
  
  // MARK: - Helper Functions
  
  private func deleteItems(at offsets: IndexSet) {
    let transaction = manualTransactions[offsets.first!]
    manualTransactions.remove(at: offsets.first!)
      firestore.removeTransaction(transaction: transaction) { error in
      if (error != nil) {
        print(error?.localizedDescription ?? "")
      }
    }
  }
}

// MARK: - Preview


// struct TransactionCell_Previews: PreviewProvider {
//     static var previews: some View {
//         TransactionCell(transaction: ManualTransaction(id: UUID().uuidString, notes: "NOtes", quantity: 2, marketPrice: 1.0, symbol: "BTC", timestamp: Int(Date.now.timeIntervalSince1970), exchange: "Coinbase", purchasedAt: "USD 1566.0", type: "bought"))
//             .environmentObject(ViewRouter())
//             .environmentObject(HomeViewModel())
//     }
// }
 
// MARK: - Transaction Cell

struct TransactionCell: View {
    @EnvironmentObject private var vm : HomeViewModel
    //@ObservedObject var firestore = FirestoreManager()
    @EnvironmentObject var firestore: FirestoreManager
    let transaction: ManualTransaction
    @State var currentCurrencyExchangeSymbol: String = ""
    @State private var showOptions = false
  var body: some View {
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
                .frame(width: 48)
            case .failure:
              Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .frame(width: 48)
            @unknown default:
              EmptyView()
            }
          }
        }
        
        Text(transaction.exchange ?? "???").foregroundColor(.white)
        Spacer()
        HStack(spacing: 0) {
          Text("\(transaction.quantity, specifier: "%.6f") ")
          Text(transaction.symbol.components(separatedBy: ",").last ?? "" )
        }.foregroundColor(.white)
          .font(.system(size: 18, weight: .bold))
      }
      
      HStack{
          VStack(alignment: .leading){
              Text("Date: " + self.convertTimestamp(serverTimestamp: Double(transaction.timestamp)))
                  .multilineTextAlignment(.leading)
                  .font(.headline)
                  .foregroundColor(Color("accent"))
              if (self.transaction.purchasedAt != ""){
                  Text("Price: \((self.transaction.purchasedAt == "" ? "N/A" : "\(self.currentCurrencyExchangeSymbol)\(self.formatCurrency(self.transaction.purchasedAt.replacingOccurrences(of: "\(currentCurrencyExchangeSymbol)", with: "")))"))")
                      .multilineTextAlignment(.leading)
                      .font(.headline)
                      .foregroundColor(Color("accent"))
              }
              let coins = self.vm.allCoins.filter{ $0.symbol.lowercased() == self.transaction.symbol.lowercased().components(separatedBy: ",").last ?? ""}
              if coins.count > 0 {
                  Text("Price now: " + "\(self.currentCurrencyExchangeSymbol)\( self.formatCurrency("\(coins[0].currentPrice)"))")
                      .multilineTextAlignment(.leading)
                      .font(.headline)
                      .foregroundColor(Color("accent"))
              }
          }
          .frame(alignment: .leading)
        Spacer()
          VStack{
              Text("\(currentCurrencyExchangeSymbol) \(transaction.marketPrice * transaction.quantity, specifier: "%0.2f") ")
                  .font(.headline)
                  .foregroundColor(Color("accent"))
              if (self.transaction.purchasedAt != "") && transaction.type == "bought"{
                  HStack {
                      let purchasedAT = self.transaction.purchasedAt
                      if Double(purchasedAT.replacingOccurrences(of: "\(currentCurrencyExchangeSymbol)", with: "")) != nil {
                          if (transaction.marketPrice * transaction.quantity) < ((Double(purchasedAT.replacingOccurrences(of: "\(currentCurrencyExchangeSymbol)", with: ""))!)*transaction.quantity) {
                              //loss
                              HStack(spacing: 0) {
                                  Image(systemName: "triangle.fill")
                                      .font(.caption2)
                                      .rotationEffect(
                                        Angle(degrees:180))
                                  let price = (((Double(purchasedAT.replacingOccurrences(of: "\(currentCurrencyExchangeSymbol)", with: ""))!)*transaction.quantity) - ((transaction.marketPrice * transaction.quantity)))
                                  Text("-")
                                  Text("\(currentCurrencyExchangeSymbol)\(price, specifier: "%0.2f")")
                                      .font(.caption)
                                      .bold()
                              }
                              .foregroundColor(.red)
                          }else{
                              //profit
                              HStack(spacing: 4) {
                                  Image(systemName: "triangle.fill")
                                      .font(.caption2)
                                      .rotationEffect(
                                        Angle(degrees:0))
                                  Text("\(currentCurrencyExchangeSymbol)\((((transaction.marketPrice * transaction.quantity)) - ((Double(purchasedAT.replacingOccurrences(of: "\(currentCurrencyExchangeSymbol)", with: ""))!)*transaction.quantity)), specifier: "%0.2f")")
                                      .font(.caption)
                                      .bold()
                              }
                              .foregroundColor(.green)
                          }
                      }
                  }
              }
          }
      }
      .foregroundColor(.white)
    }
    .onTapGesture {
        self.showOptions = true
    }
    .frame(height: 84)
    .fullScreenCover(isPresented: $showOptions) {
        TransactionDetailView(showOptions: $showOptions, transaction: self.transaction, currentCurrencyExchangeSymbol: self.currentCurrencyExchangeSymbol)
            .environmentObject(firestore)
            .environmentObject(vm)
    }
  }
  
  // MARK: - Helper Functions
  
  func getImageFromlist(name: String) -> String {
    let exchange = firestore.exchangesList.filter({$0.name == name})
    if exchange.count > 0 {
      return exchange[0].iconURL
    } else {
      let exchange = firestore.exchangesList.filter({$0.name == "Custom Exchange"})
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
