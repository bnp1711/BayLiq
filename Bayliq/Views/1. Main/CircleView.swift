//
//  CircleView.swift
//  Bayliq
//
//  Created by David Razmadze on 10/23/22.
//

import SwiftUI
import CachedAsyncImage

// MARK: - Global Variables

let width = UIScreen.main.bounds.width - 40
let speed = 0.7

// MARK: - CircleView

class SortingHelper: ObservableObject {
  @Published var wantToSort = false
}

struct CircleView: View {
  
  // MARK: - Variables
  
  var diameter = width - 80
  
  @Binding var currencies: [Currency]
  @State private var progress = -0.5
  @State private var addon = 0.0
  @State private var lastAddon: CGFloat?
  @State private var sortOption: CircleSortingOption = .descending
  @Binding var isLoading: Bool
  @State var currenciesForCustomOrdering = [CurrencyForCustomOrdering]()
  @Binding var currentPickedIndex: Int
  @Binding var showManualTransactionView: Bool
  @Binding var manuals: [ManualTransaction]
  
  @Binding var showDetailView: Bool
  var getCoin: Coin?
  
  @EnvironmentObject var currencyExchangeService: CurrencyExchangeService
  @EnvironmentObject var sortingHelper: SortingHelper
//  @ObservedObject var firestore = FirestoreManager()
  @ObservedObject var vm: HomeViewModel
//  @AppStorage("pickedCurrencyExchange") var pickedCurrencyExchange = "USD"
    @State var isAPIerr = false
  var noTransactions: Bool {
    currencies.filter({$0.image != "Home"}).isEmpty && currentPickedIndex >= 0 && currencies.filter({$0.image != "Home"}).count+1 > currentPickedIndex
  }
    @Binding var pickedCurrencyExchange : String
  var currentCurrencyExchangeRate: Double
  var currentCurrencyExchangeSymbol: String
    @Binding var isRefreshData : Bool
  // MARK: - Body
    @Binding  var go : Bool
    @EnvironmentObject  var firestore : FirestoreManager

  var body: some View {
    VStack{
      ZStack(alignment: .top){
        HalfCircle()
          .inset(by: 0)
          .fill(Color(hex: 0x314063))
          .aspectRatio(2, contentMode: .fit)
          .frame(width: width, alignment: .top)
          .shadow(radius: 5)
          .overlay(
            Button(action: {
              showManualTransactionView = true
            }, label: {
              ZStack {
                Circle().fill(Color("Color"))
                Image(systemName: "plus.circle")
                  .font(.system(size: UIDevice.isIPad ? 80 : 40))
                  .foregroundColor(.white)
              }.frame(width: UIDevice.isIPad ? 60 : 30)
              
            }).padding(.leading, UIDevice.isIPad ? 30 : 10)
            ,alignment: .leading
          )
        HalfCircle()
          .inset(by: 0)
          .stroke(lineWidth: 0)
          .aspectRatio(2, contentMode: .fit)
          .frame(width: diameter)
          .overlay(
            ZStack{
              if sortOption == .custom {
                ForEach(currenciesForCustomOrdering.indices, id: \.self) { i in
                  ZStack{
                    ZStack {
                      if currenciesForCustomOrdering[i].currency.image == "Home" {
                        Image(systemName: "house.fill")
                          .foregroundColor(currentPickedIndex == i ? .orange : .gray)
                          .frame(width: UIDevice.isIPad ? 50 : 30, height: UIDevice.isIPad ? 50 : 30)
                      } else {
                        CustomAsyncImage(url: abs(currentPickedIndex - i) < 3 ? currenciesForCustomOrdering[i].currency.image : "https://firebasestorage.googleapis.com/v0/b/bayliq-72340.appspot.com/o/coins%2Floading.png?alt=media&token=b6a0683b-2aa1-4b7b-bc7f-5a6277ccf8df", size: UIDevice.isIPad ? CGSize(width: 50, height: 50) : CGSize(width: 30, height: 30))
                      }
                    }
                    .onChange(of: currentPickedIndex, perform: { new in
                      let x = diameter/2 * (1 - cos((progress-(Double(i)/4.5)+Double(new)/4.5) * Double.pi))
                      let y = (i-new) < 5 ? diameter/2 - diameter/2 * sin((progress+(Double(i)/4.5)-Double(new)/4.5) * Double.pi) : -100.0
                      if i > new - 4 {
                        currenciesForCustomOrdering[i].currency.position = CGPoint(x: x, y: currentPickedIndex == i ? (UIDevice.isIPad ? y-200 : y-50) : y+7)
                      } else {
                        currenciesForCustomOrdering[i].currency.position = CGPoint(x: -100, y: -100)
                      }
                    })
                    .position(currenciesForCustomOrdering[i].currency.position)
                    .onTapGesture {
                        self.go = false
                      currentPickedIndex = i
                      if currencies[i].image == "Home" {
                        currencies[i].amount = calculateTotalSum()
                      } else {
                        let crypto = currencies[i].coin?.currentPrice///vm.allCoins.first(where: {$0.symbol.lowercased().replacingOccurrences(of: " ", with: "") == currencies[i].name.lowercased().replacingOccurrences(of: " ", with: "")})?.currentPrice
                          currencies[i].cryptoValue = crypto ?? 1.0
                      }
                    }
                    .scaleEffect(i == currentPickedIndex ? 1.3 : 0.95)
                    .animation(Animation.linear(duration: 0.2))
                  }.onAppear {
                    for i in currencies.indices {
                      let x = i < 5 ? diameter/2 * (1 - cos((progress-(Double(i)/4.5)) * Double.pi)) : -100.0
                      let y = i < 5 ? diameter/2 - diameter/2 * sin((progress+(Double(i)/4.5)) * Double.pi) : -100.0
                      currenciesForCustomOrdering[i].currency.position = CGPoint(x: x, y: i == 0 ? (UIDevice.isIPad ? y-200 : y-50) : y+7)
                    }
                  }
                  
                }
              } else {
                ForEach(currencies.indices, id: \.self) { i in
                  ZStack{
                    ZStack {
                      if currencies[i].image == "Home" {
                        Image(systemName: "house.fill")
                          .foregroundColor(currentPickedIndex == i ? .orange : .gray)
                          .frame(width: UIDevice.isIPad ? 50 : 30, height: UIDevice.isIPad ? 50 : 30)
                      } else {
                        CustomAsyncImage(url: abs(currentPickedIndex - i) < 3 ? currencies[i].image : "https://firebasestorage.googleapis.com/v0/b/bayliq-72340.appspot.com/o/coins%2Floading.png?alt=media&token=b6a0683b-2aa1-4b7b-bc7f-5a6277ccf8df", size: UIDevice.isIPad ? CGSize(width: 50, height: 50) : CGSize(width: 30, height: 30))
                      }
                    }
                    .onChange(of: currentPickedIndex, perform: { new in
                      let x = diameter/2 * (1 - cos((progress-(Double(i)/4.5)+Double(new)/4.5) * Double.pi))
                      let y = (i-new) < 5 ? diameter/2 - diameter/2 * sin((progress+(Double(i)/4.5)-Double(new)/4.5) * Double.pi) : -100.0
                      if i > new - 4 {
                        currencies[i].position = CGPoint(x: x, y: currentPickedIndex == i ? (UIDevice.isIPad ? y-200 : y-50) : y+7)
                      } else {
                        currencies[i].position = CGPoint(x: -100, y: -100)
                      }
                    })
                    .position(currencies[i].position)
                    .onTapGesture {
                        self.go = false
                      currentPickedIndex = i
                      if currencies[i].image == "Home" {
                        currencies[i].amount = calculateTotalSum()
                      } else {
                          let crypto = currencies[currentPickedIndex].coin?.currentPrice//vm.allCoins.first(where: {$0.symbol.lowercased().replacingOccurrences(of: " ", with: "") == currencies[i].name.lowercased().replacingOccurrences(of: " ", with: "")})?.currentPrice
                          currencies[i].cryptoValue = crypto ?? 1.0
                      }
                    }
                    .scaleEffect(i == currentPickedIndex ? 1.3 : 0.95)
                    .animation(Animation.linear(duration: 0.2))
                  }.onAppear {
                    for i in currencies.indices {
                      let x = i < 5 ? diameter/2 * (1 - cos((progress-(Double(i)/4.5)) * Double.pi)) : -100.0
                      let y = i < 5 ? diameter/2 - diameter/2 * sin((progress+(Double(i)/4.5)) * Double.pi) : -100.0
                      currencies[i].position = CGPoint(x: x, y: i == 0 ? (UIDevice.isIPad ? y-200 : y-50) : y+7)
                    }
                  }
                  
                }
              }
            }.offset(y: -width/2+40)
          )
        VStack{
          ZStack {
              if isAPIerr && vm.allCoins.count <= 0 {
                  Text("Try again later...")
                    .frame(alignment:.center)
                    .foregroundColor(.white)
                    .font(.system(size: UIDevice.isIPad ? 70 : 25, weight: .bold))
                    .padding(.top,10)
              }else if !currencies.filter({$0.image != "Home"}).isEmpty && currentPickedIndex >= 0 && currencies.filter({$0.image != "Home"}).count+1 > currentPickedIndex {
                if currencies[currentPickedIndex].image == "Home" {
                    Text("\(currentCurrencyExchangeSymbol)\((NumberHelper.formatPoints(num: (currencies[currentPickedIndex].amount).roundToPlaces(places: 2) )))")
                        .fixedSize()
                        .opacity(go ? 1 : 0)
                       .animation(Animation.easeInOut(duration: 1).repeatCount(2), value: go)
                       .onAppear{self.go.toggle()}
                      .foregroundColor(.white)
                      .font(.system(size: UIDevice.isIPad ? 70 : 25, weight: .bold))
                      .padding(.top,10)
//                      .animation(.easeInOut(duration: 2), value: 1.0)

                      .onAppear {
                          self.go = true
                          DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.go = true
                        }
                      }
                } else {
                    Text("\(currentCurrencyExchangeSymbol)\((NumberHelper.formatPoints(num:(currentPickedIndex == 0 ? currencies[currentPickedIndex].cryptoValue : currencies[currentPickedIndex].amount * currencies[currentPickedIndex].cryptoValue).roundToPlaces(places: 2))))")
                      .foregroundColor(.white)
                      .font(.system(size: UIDevice.isIPad ? 70 : 25, weight: .bold))
                      .padding(.top,10)
                      .onAppear {
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                        }
                      }
                }
            } else if isLoading {
              Text("Loading...")
                .foregroundColor(.white)
                .font(.system(size: UIDevice.isIPad ? 70 : 25, weight: .bold))
                .padding(.top,10)
                .onAppear {
//                  DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                    print(currencies, "currencies <<<<<")
//                  }
                }
              
            } else {
              VStack() {
                Text("No transactions")
                  .frame(alignment:.center)
                  .foregroundColor(.white)
                  .font(.system(size: UIDevice.isIPad ? 70 : 25, weight: .bold))
                  .padding(.top,10)
                  .onAppear {
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                      print(currencies, "currencies <<<<<")
//                    }
                  }
                let widthOfPlus = (UIDevice.isIPad ? (40)+30 : (30)+30)
                
                HStack{
                  Image("ic_Arrow")
                    .padding(.top,5)
                    .padding(.leading, UIDevice.isIPad ? 30 : 10)
                    .frame(width:43,height: 33,alignment: .leading)
                  Text("Get started")
                    .padding(.top,10)
                    .font(.system(size: UIDevice.isIPad ? 52 : 20, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.white)
                }
                .padding(.leading,CGFloat(widthOfPlus))
              }
            }
          }
          
          ZStack {
            if !currencies.isEmpty && currentPickedIndex >= 0 && currencies.count > currentPickedIndex {
              if currencies[currentPickedIndex].image != "Home" {
                Text("= \(!currencies.isEmpty && currentPickedIndex >= 0 && currencies.count > currentPickedIndex ? currencies[currentPickedIndex].amount : 0.0, specifier: "%.2f") \(!currencies.isEmpty && currentPickedIndex >= 0 && currencies.count > currentPickedIndex ? currencies[currentPickedIndex].name : "")")
              }
            }
          }
          .foregroundColor(.orange)
          .font(.system(size: UIDevice.isIPad ? 30 : 15, weight: .bold))
        }.padding(.top)
      }
      .onChange(of: sortingHelper.wantToSort, perform: { newValue in
        if newValue == true {
          sortingFunc()
        }
      })
      .onChange(of: self.isRefreshData, perform: { newValue in
          isLoading = true
          currentPickedIndex = 0
          for i in currencies.indices {
            let x = i < 5 ? diameter/2 * (1 - cos((progress-(Double(i)/4.5)) * Double.pi)) : -100.0
            let y = i < 5 ? diameter/2 - diameter/2 * sin((progress+(Double(i)/4.5)) * Double.pi) : -100.0
            currencies[i].position = CGPoint(x: x, y: i == 0 ? (UIDevice.isIPad ? y-200 : y-50) : y+7)
          }
            manuals = [ManualTransaction]()
         // DispatchQueue.main.async {
          if vm.allCoins.count == 0{
              vm.addSubscribers(completion: { error in
                  isLoading = false
                  if error == nil{
                      if vm.allCoins.count > 0{
                          getAllManualTransactions()
                          self.isAPIerr = false
                      }
                  }else{
                      getAllManualTransactions()
                      self.isAPIerr = true
                  }
              })
          }else{
              isLoading = false
              getAllManualTransactions()
          }
      })
      .onAppear {
        isLoading = true
        currentPickedIndex = 0
        for i in currencies.indices {
          let x = i < 5 ? diameter/2 * (1 - cos((progress-(Double(i)/4.5)) * Double.pi)) : -100.0
          let y = i < 5 ? diameter/2 - diameter/2 * sin((progress+(Double(i)/4.5)) * Double.pi) : -100.0
          currencies[i].position = CGPoint(x: x, y: i == 0 ? (UIDevice.isIPad ? y-200 : y-50) : y+7)
        }
          manuals = [ManualTransaction]()
       // DispatchQueue.main.async {
          if vm.allCoins.count == 0{
              vm.addSubscribers(completion: { error in
                  isLoading = false
                  if error == nil{
                      if vm.allCoins.count > 0{
                          getAllManualTransactions()
                          self.isAPIerr = false
                      }
                  }else{
                      getAllManualTransactions()
                      self.isAPIerr = true
                  }
              })
          }else{
              isLoading = false
              getAllManualTransactions()
          }
      }
      Image(systemName: "arrowtriangle.up.fill")
        .font(.system(size: UIDevice.isIPad ? 60 : 30))
        .foregroundColor(.orange)
        .offset(y: UIDevice.isIPad ? -25 : -10)
      if !currencies.filter({$0.image != "Home"}).isEmpty && currentPickedIndex >= 0 && currencies.filter({$0.image != "Home"}).count+1 > currentPickedIndex {
        HStack {
          Text(self.getFullName(of: currencies[currentPickedIndex].name))
            .foregroundColor(.white)
            .font(.system(size: UIDevice.isIPad ? 32 : 18, weight: .semibold))
          Spacer()
          if getCoin != nil {
            Button(action: {
              showDetailView = true
            }, label: {
              ZStack{
                Circle().fill(Color("Color"))
                Image(systemName: "chart.xyaxis.line")
                  .font(.system(size: UIDevice.isIPad ? 50 : 30))
                  .foregroundColor(.white)
              }.frame(width: UIDevice.isIPad ? 60 : 30)
              
            }).padding(.leading, UIScreen.main.bounds.size.width/30)
          }
        }
        .fullScreenCover(isPresented: $showDetailView) {
          if getCoin != nil {
              DetailView(coin: getCoin!, isFullScreenCover: true, firestore: self.firestore).dynamicTypeSize(.medium)
          }
        }
        .padding(.horizontal, 30)
        .overlay {
          Text(currentPickedIndex == 0 ? "Overall Balance" : currencies[currentPickedIndex].name)
            .foregroundColor(.orange)
            .font(.system(size: UIDevice.isIPad ? 35 : 20, weight: .bold))
        }
      }
    }
  }
  
  // MARK: - Helper Functions
  
  private func getAllManualTransactions() {
      let grp = DispatchGroup()
    firestore.fetchManualTransactions(completion:  {
        isLoading = false
      self.currencies = currencies.filter({$0.image == "Home"})
      manuals = [ManualTransaction]()
      for manual in firestore.allTransactions {
          grp.enter()
        firestore.getCoinIconURL(symbol: manual.symbol) { error, iconURL in
          if let error {
            print("Error getting coins: \(error)")
            return
          }
          guard let iconURL = iconURL else { return }
          
            self.manuals.append(ManualTransaction(id: manual.id, notes: manual.notes, quantity: manual.quantity, marketPrice: vm.allCoins.first(where: {$0.symbol.lowercased().replacingOccurrences(of: " ", with: "") == manual.symbol.lowercased().replacingOccurrences(of: " ", with: "")})?.currentPrice ?? 1.0, symbol: "\(iconURL),\(manual.symbol)", timestamp: manual.timestamp, exchange: manual.exchange ?? "", purchasedAt: "\(manual.marketPrice)", type: manual.type))
          
          if !currencies.contains(where: {$0.image == iconURL}) {
              currencies.append(Currency(name: manual.symbol, image: iconURL, amount: manual.quantity, cryptoValue: vm.allCoins.first(where: {$0.symbol.lowercased().replacingOccurrences(of: " ", with: "") == manual.symbol.lowercased().replacingOccurrences(of: " ", with: "")})?.currentPrice ?? 1.0, coin: vm.allCoins.first{$0.symbol.lowercased().components(separatedBy: ",").last ?? "" == manual.symbol.lowercased()}))
              
          } else {
            for i in currencies.indices {
              if currencies[i].image == iconURL {
                if manual.type == "bought" {
                  currencies[i].amount += manual.quantity
                } else if manual.type == "sold" {
                  currencies[i].amount -= manual.quantity
                }
              }
            }
            
            for (i,j) in currencies.enumerated(){
                if j.amount == 0  && j.image != "Home" {
                currencies.remove(at: i)
              }
            }
          }
            sortingFunc()
            grp.leave()
        }
          grp.notify(queue: DispatchQueue.main) {
              for i in self.currencies.indices{
                if currencies[i].image != "Home" {
                  let crypto = currencies[i].coin?.currentPrice///(vm.allCoins.first(where: {$0.symbol.lowercased().replacingOccurrences(of: " ", with: "") == currencies[i].name.lowercased().replacingOccurrences(of: " ", with: "")})?.currentPrice ?? 1.0)
                    currencies[i].cryptoValue = crypto ?? 1.0
                }
              }
              for i in self.currencies.indices{
                  if currencies[i].image == "Home" {
                      currencies[i].amount = calculateTotalSum()
                  }
              }
          }
      }
    }) {
      isLoading = false
    }
  }
  
  private func getFullName(of curreny: String) -> String {
    return vm.allCoins.first(where: {$0.symbol.lowercased() == curreny.lowercased()})?.name ?? ""
  }
  
  func sortingFunc() {
    sortOption = CircleSortingOption(rawValue: UserDefaults.standard.integer(forKey: "sortOption")) ?? .descending
    
    if let data = UserDefaults.standard.object(forKey: "customSortCurrencies") as? Data,
       let customSortedCurrencies = try? JSONDecoder().decode([CurrencyForCustomOrdering].self, from: data) {
      currenciesForCustomOrdering = customSortedCurrencies
    } else {
      for i in currencies.indices {
        currenciesForCustomOrdering.append(CurrencyForCustomOrdering(idx: i, currency: currencies[i]))
      }
    }
    
    switch sortOption {
    case .descending:
      currencies.sort(by: { ($0.image == "Home" || $1.image == "Home" && $0.image != $1.image) ? $0.image == "Home" : ($0.cryptoValue * $0.amount) > ($1.cryptoValue * $1.amount)})
    case .marketCap:
      currencies.sort(by: { ($0.image == "Home" || $1.image == "Home" && $0.image != $1.image) ? $0.image == "Home" : $0.cryptoValue > $1.cryptoValue})
    case .custom:
      currenciesForCustomOrdering.sort(by: {($0.currency.image == "Home" || $1.currency.image == "Home" && $0.currency.image != $1.currency.image) ? $0.currency.image == "Home" : $0.idx < $1.idx})
    }
    currentPickedIndex = 0
//      self.   .toggle()
      for i in currencies.indices {
          if currencies[i].image == "Home" {
              currencies[i].amount = calculateTotalSum()
          } else {
              let crypto = currencies[i].coin?.currentPrice///vm.allCoins.first(where: {$0.symbol.lowercased().replacingOccurrences(of: " ", with: "") == currencies[i].name.lowercased().replacingOccurrences(of: " ", with: "")})?.currentPrice
              currencies[i].cryptoValue = crypto ?? 1.0
          }
      }
    sortingHelper.wantToSort = false
    isLoading = false
  }
  
  func calculateTotalSum() -> Double {
    var total = 0.0
    for currency in currencies.filter({$0.image != "Home"}) {
        total += (currency.coin?.currentPrice ?? 1.0) * currency.amount //(vm.allCoins.first(where: {$0.symbol.lowercased().replacingOccurrences(of: " ", with: "") == currency.name.lowercased().replacingOccurrences(of: " ", with: "")})?.currentPrice ?? 1.0) * currency.amount
     // print(currency.cryptoValue, "cryptoValue", currency.name, "name", currency.amount, "amount")
    }
    return total
  }
  
}

// MARK: - HalfCircle

struct HalfCircle: InsettableShape {
  
  var _inset: CGFloat = 0
  
  func inset(by amount: CGFloat) -> Self {
    var copy = self
    copy._inset += amount
    return copy
  }
  
  func path(in rect: CGRect) -> Path {
    var path = Path()
    
    // This is a half-circle centered at the origin with radius 1.
    path.addArc(
      center: .zero,
      radius: 1,
      startAngle: .zero,
      endAngle: .radians(.pi),
      clockwise: false
    )
    path.closeSubpath()
    
    // Since it's the bottom half of a circle, we only want
    // to inset the left, right, and bottom edges of rect.
    let rect = rect
      .insetBy(dx: _inset, dy: 0.5 * _inset)
      .offsetBy(dx: 0, dy: -(0.5 * _inset))
    
    // This transforms bounding box of the path to fill rect.
    let transform = CGAffineTransform.identity
      .translatedBy(x: rect.origin.x + 0.5 * rect.size.width, y: 0)
      .scaledBy(x: rect.width / 2, y: rect.height)
    
    return path.applying(transform)
  }
}

// MARK: - CustomAsyncImage

struct CustomAsyncImage: View {
  var url: String
  var size: CGSize
  var body: some View {
    VStack {
        CachedAsyncImage(url: URL(string: url), urlCache: .imageCache) { phase in
        switch phase {
        case .empty:
          ZStack {
              ProgressView()
          }.frame(width: size.width, height: size.height)
        case .success(let image):
          image.resizable()
            .scaledToFill()
            .frame(width: size.width, height: size.height)
            .clipped()
        case .failure:
            CachedAsyncImage(url: URL(string: url)) { phase in
            if let image = phase.image {
              image
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
            } else{
              ZStack{
                Image(systemName: "questionmark")
              }.frame(width: size.width, height: size.height)
            }
          }
        @unknown default:
          Text("no co jest")
        }
      }
    }
  }
}
