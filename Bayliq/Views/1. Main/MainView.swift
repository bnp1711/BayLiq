//
//  HomeView.swift
//  Bayliq
//
//  Created by Nuno Mestre on 7/27/22.
//

import SwiftUI
import Firebase
import AVFoundation
import Combine
import CachedAsyncImage
import StoreKit

struct MainView: View {
  
    // MARK: - Variables
    let db = Firestore.firestore()
    @Environment(\.requestReview) var requestReview
    @EnvironmentObject var currencyExchangeService: CurrencyExchangeService
    @StateObject private var sortingHelper = SortingHelper()
    @EnvironmentObject private var vm : HomeViewModel
    @EnvironmentObject var viewRouter: ViewRouter
    @ObservedObject var firestore = FirestoreManager()

    @State var isLoading = false
    @State var searchView = false
    @State var sideMenu = false
    @State var exchangeView = false
    @State var showManualTransactionView = false
    @State var currentPickedIndex = 0
    @State var showSettingsView = false
    @State var showTransactionView = false
    @State var showExchangeView = false
    @State var selectedExchangeTransactions = [ManualTransaction]()
    @State var indicatorOffset: CGFloat = -3000
    @State var showExtendedCircleView = false
    @State var showInviteFriends = false

    @State var draggedItem: ManualTransaction?
    @State var mannualTransactionsOrder = [ManualTransactionForSorting]()
    @State var noTransactions = [NoTransaction]()
    @State var manualTransactions = [ManualTransaction]()
    @State var sortedTransactions = [ManualTransaction]()
    @State var arrSorted = [String]()
    @State var sortedHomeManualTransactions = [ManualTransaction]()

    @State var currencies = [Currency(name: "Home", image: "Home", amount: 0.0, cryptoValue: 1.0, coin: nil)]
    @State var showDetailView = false
    @State var currentCurrencyExchangeSymbol: String = ""
    @State var isRefreshData = false
    @State  var now: Date = Date()
    @State  var timer: Timer?
    @State var go : Bool = false
    var currentCurrencyExchangeRate: Double {
        return vm.allCoins.first(where: {$0.symbol.lowercased().replacingOccurrences(of: " ", with: "") == vm.pickedCurrencyExchange.lowercased().replacingOccurrences(of: " ", with: "")})?.currentPrice ?? 1.0
    }
    @State var showCharts: Bool = false

    // MARK: - Init
    init() {
        UINavigationBar.appearance().backgroundColor = UIColor(Color("background"))

        // Set top Nav Bar behavior for ALL of app
        let standardAppearance = UINavigationBarAppearance()

        // Title font color
        standardAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        standardAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        // prevent Nav Bar color change on scroll view push behind NavBar
        standardAppearance.configureWithOpaqueBackground()
        standardAppearance.backgroundColor = UIColor(Color("background"))

        UINavigationBar.appearance().standardAppearance = standardAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = standardAppearance
        // firestore.getUserData()
    }
    
    func refresh(pickedCurrencyExchange: String) {
        vm.pickedCurrencyExchange = pickedCurrencyExchange
        now = Date()
        //self.vm.reloadData {
        self.vm.allCoins.removeAll()
        self.vm.coinDataService =  CoinDataService(pickedCurrencyExchange: $vm.pickedCurrencyExchange)
        self.manualTransactions.removeAll()
        self.currencies = [Currency(name: "Home", image: "Home", amount: 0.0, cryptoValue: 1.0, coin: nil)]
        self.isRefreshData.toggle()
        //}
    }
  
  // MARK: - Body

  var body: some View {
    NavigationView {
      ZStack(alignment: .leading){
        // Background Color
        Color("background").ignoresSafeArea(edges: .all)
        VStack{
            CircleView(currencies: $currencies, isLoading: $isLoading, currentPickedIndex: $currentPickedIndex, showManualTransactionView: $showManualTransactionView, manuals: $manualTransactions, showDetailView: $showDetailView, getCoin: getCoin(),  vm: vm, pickedCurrencyExchange: $vm.pickedCurrencyExchange, currentCurrencyExchangeRate: currentCurrencyExchangeRate, currentCurrencyExchangeSymbol: currentCurrencyExchangeSymbol,isRefreshData:$isRefreshData, go: $go)
                .environmentObject(self.firestore)
            .gesture(
              DragGesture(minimumDistance: 2)
                .onChanged({ value in
                  if indicatorOffset/50 < 40 {
                    indicatorOffset += value.translation.height
                  } else {
                    indicatorOffset = 2000
                  }
                })
                .onEnded({ value in
                    self.go = false
                  if indicatorOffset/50 < 40 {
                    indicatorOffset = -3000
                    if value.translation.width < 200 {
                      if !currencies.filter({$0.image != "Home"}).isEmpty {
                        showExtendedCircleView = true
                      }
                    }
                    if value.translation.width > 200 {
                      if !currencies.filter({$0.image != "Home"}).isEmpty {
                        showExtendedCircleView = true
                      }

                    }
                  } else {
                      //vm.reloadData{
                      self.vm.allCoins.removeAll()
                      self.vm.coinDataService =  CoinDataService(pickedCurrencyExchange: $vm.pickedCurrencyExchange)
                      self.manualTransactions.removeAll()
                      self.currencies = [Currency(name: "Home", image: "Home", amount: 0.0, cryptoValue: 1.0, coin: nil)]
                      self.isRefreshData.toggle()
                      //}
                    indicatorOffset = -3000
                  }

                })
            )
          optionButtons
          if currentPickedIndex == 0 {
            let data = sortedHomeManualTransactions.filter({!currencies.filter({$0.image != "Home"}).isEmpty && currentPickedIndex >= 0 && currencies.filter({$0.image != "Home"}).count+1 > currentPickedIndex ? currencies[currentPickedIndex].name != "Home" ? currencies[currentPickedIndex].name == $0.symbol.components(separatedBy: ",").last ?? "" : $0.id != "" : $0.id != ""}).sorted(by: {$0.index ?? 0 > $1.index ?? 1}).reorder(by: arrSorted)
            if data.count != 0 {
              ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 15) {
                  ForEach(data) { trans in
                    ExchangeRowCell(isHome: true, transaction: trans, currentCurrencyExchangeSymbol: currentCurrencyExchangeSymbol, currentCurrencyExchangeRate: currentCurrencyExchangeRate, manager: self.firestore, vm: vm)
                          .onTapGesture(perform: {
                              self.selectedExchangeTransactions = self.manualTransactions.filter({ $0.exchange == trans.exchange })
                              self.showExchangeView = true

                          })
                      .onDrag {
                        draggedItem = trans
                        return NSItemProvider(item: nil, typeIdentifier: trans.id)
                      }
                      .onDrop(of: [UTType.text], delegate: DragAndDropService(currentItem: trans, mannualTransactionsOrder: $mannualTransactionsOrder, items: $sortedHomeManualTransactions, draggedItem: $draggedItem, arrSorted: $arrSorted))
                  }
                }
              }.padding(.horizontal)
                .onAppear{

                  DispatchQueue.main.async {
                    self.organizeManuals()
                  }
                }
            } else {
                if self.noTransactions.count > 0 {
                    List{
                        ForEach(self.noTransactions) { transaction in
                            NoTransactionCell(transaction: transaction)
                                .environmentObject(firestore)
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: 12)
                                        .background(.clear)
                                        .foregroundColor(Color("darkBlue"))
                                        .padding(
                                            EdgeInsets(
                                                top: 2,
                                                leading: 10,
                                                bottom: 8,
                                                trailing: 10
                                            )
                                        )
                                )
                                .listRowSeparator(.hidden)
                        }
                    }
                    .background(Color.clear)
                    .listRowBackground(Color.clear)
                    .listStyle(.plain)
                    .padding(.horizontal, 12)
                }else{
                    Spacer()
                }
            }
          } else {
            let data = sortedTransactions.filter({!currencies.filter({$0.image != "Home"}).isEmpty && currentPickedIndex >= 0 && currencies.filter({$0.image != "Home"}).count+1 > currentPickedIndex ? currencies[currentPickedIndex].name != "Home" ? currencies[currentPickedIndex].name == $0.symbol.components(separatedBy: ",").last ?? "" : $0.id != "" : $0.id != ""}).sorted(by: {$0.index ?? 0 > $1.index ?? 1})
            if data.count != 0 {
                ZStack{
                    VStack{
                        if currentPickedIndex < currencies.count {
                            let coins =  vm.allCoins.filter{$0.symbol.lowercased().components(separatedBy: ",").last ?? "" == currencies[self.currentPickedIndex].name.lowercased()}
                            if coins.count > 0 {
                                let info = coins[0].sparklineIn7D?.price ?? []
                                let data = info
                                let maxY = info.max() ?? 0
                                let minY = info.min() ?? 0
                                let priceChange = (info.last ?? 0) - (info.first ?? 0)
                                let lineColor = priceChange > 0 ? Color("green") : Color("red")
                                ChartViewHome(data: data, maxY: maxY, minY: minY, lineColor: lineColor, showCharts: self.$showCharts)
                                    .padding(.leading,20)
                                    .padding(.trailing,20)
                                    .onAppear{
                                        //self.showCharts.toggle()
                                    }
                            }
                            Spacer()
                        }
                    }

                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 15) {
                            ForEach(data) { transaction in
                                ExchangeRowCell(isHome: false, transaction: transaction, currentCurrencyExchangeSymbol: currentCurrencyExchangeSymbol, currentCurrencyExchangeRate: currentCurrencyExchangeRate, manager: self.firestore, vm: vm)
                                    .onTapGesture(perform: {
//                                        print(transaction)
                                        self.selectedExchangeTransactions = self.manualTransactions.filter({ $0.exchange == transaction.exchange && $0.symbol == transaction.symbol})
                                        self.showExchangeView = true

                                    })
                                    .onDrag {
                                        draggedItem = transaction
                                        return NSItemProvider(item: nil, typeIdentifier: transaction.id)
                                    }
                                    .onDrop(of: [UTType.text], delegate: DragAndDropService(currentItem: transaction, mannualTransactionsOrder: $mannualTransactionsOrder, items: $sortedTransactions, draggedItem: $draggedItem,arrSorted: $arrSorted))
                            }

                        }
                    }.padding(.horizontal)

                }
            } else {
              List{
                ForEach(self.noTransactions) { transaction in
                  NoTransactionCell(transaction: transaction)
                    .listRowBackground(
                      RoundedRectangle(cornerRadius: 12)
                        .background(.clear)
                        .foregroundColor(Color("darkBlue"))
                        .padding(
                          EdgeInsets(
                            top: 2,
                            leading: 10,
                            bottom: 8,
                            trailing: 10
                          )
                        )
                    )
                    .listRowSeparator(.hidden)

                }
              }
              .background(Color.clear)
              .listRowBackground(Color.clear)
              .listStyle(.plain)
            }
          }

        }
        .fullScreenCover(isPresented: $showExchangeView, content: {
            exchangeTransactions(manualTransactions: $selectedExchangeTransactions,currentCurrencyExchangeSymbol: self.currentCurrencyExchangeSymbol).dynamicTypeSize(.medium)
                .environmentObject(vm)
            .environmentObject(firestore)
            .environmentObject(sortingHelper)
            .onAppear {
              sideMenu = false
            }
        })

        .onChange(of: vm.pickedCurrencyExchange, perform: { newValue in
            self.vm.allCoins.removeAll()
            self.vm.coinDataService =  CoinDataService(pickedCurrencyExchange: $vm.pickedCurrencyExchange)
            self.manualTransactions.removeAll()
            self.currencies = [Currency(name: "Home", image: "Home", amount: 0.0, cryptoValue: 1.0, coin: nil)]

//            vm.reloadData{
                self.isRefreshData.toggle()
//            }
        })
        .overlay {
          ZStack {
            if sideMenu {
              Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                  withAnimation {
                    sideMenu = false
                  }
                }
            }
          }
        }
        .overlay(
          ZStack {
            Circle().fill(Color.white)
            Image(systemName: "arrow.clockwise")
              .rotationEffect(Angle(degrees: indicatorOffset/50))
              .foregroundColor(Color("loginFields"))
          }.frame(width: 50, height: 50)
            .offset(y: indicatorOffset/50)
          , alignment: .top
        )
        if sideMenu {
            SideMenuView(showSettingsView: $showSettingsView, showTransactionView: $showTransactionView, width: UIScreen.main.bounds.size.width/2).environmentObject(firestore)
        }
      }.disabled(self.isLoading)
      .environmentObject(sortingHelper)
        .fullScreenCover(isPresented: $showManualTransactionView, onDismiss: {
          currentPickedIndex = 0
        }, content: {
            ManualTransactionView(firestore: self.firestore, currentCurrencyExchangeSymbol: currentCurrencyExchangeSymbol).dynamicTypeSize(.medium).environmentObject(vm)
        })
        .sheet(isPresented: $showExtendedCircleView, content: {
          ExtendedCircleView
        })
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
              withAnimation {
                self.sideMenu.toggle()
              }
            }, label: {
              Image(systemName: "line.3.horizontal").foregroundColor(.white)
            })
          }
          ToolbarItem(placement: .principal) {
            HStack(spacing: 0) {
              Text("**bay**")
                .foregroundColor(Color.white)
                .font(.system(size: 30))
              Text("liq")
                .foregroundColor(Color.white)
                .font(.system(size: 30, weight: .ultraLight))
            }
            .onTapGesture {
              withAnimation {
                currentPickedIndex = 0
              }
            }

          }
          ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
              searchView = true
            }, label: {
              Image(systemName: "magnifyingglass").foregroundColor(.white)
            })
          }
        }
        .background(
          NavigationLink(
            destination: HomeView(vm: vm,isFromManualTransaction: .constant(false),TokenName: .constant(""), TokenFullName: .constant(""), TokenPrice: .constant(Double(0.0)), TokenImage: .constant(Image(uiImage: UIImage())), presentedAsModal: .constant(true), currentCurrencyExchangeSymbol: currentCurrencyExchangeSymbol).environmentObject(vm).environmentObject(firestore),
            isActive: $searchView,
            label: { EmptyView() })
        )
    }.fullScreenCover(isPresented: $showInviteFriends, content: {
        InviteUser(manager: self.firestore)
    })
    .fullScreenCover(isPresented: $showSettingsView, onDismiss: {
      getCurrencySymbol()
    }, content: {
        SettingsView(currencies: $currencies, pickedCurrencyExchange: $vm.pickedCurrencyExchange).dynamicTypeSize(.medium)
        .environmentObject(firestore)
        .environmentObject(sortingHelper)
        .onAppear {
          sideMenu = false
        }
    })
    .fullScreenCover(isPresented: $showTransactionView, content: {
        TransactionListView(manualTransactions: $manualTransactions,currentCurrencyExchangeSymbol: self.currentCurrencyExchangeSymbol).dynamicTypeSize(.medium)
            .environmentObject(vm)
        .environmentObject(firestore)
        .environmentObject(sortingHelper)
        .onAppear {
          sideMenu = false
        }
    })
    .onChange(of: manualTransactions.count, perform: { newValue in
        self.go = false
      DispatchQueue.main.async {
        self.organizeManuals()
      }
    })
    .onAppear {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            
            if let showInviteFriends = UserDefaults.standard.value(forKey: "ShowInviteFriends") as? Bool {
                if showInviteFriends {
                    self.showInviteFriends = true
                    UserDefaults.standard.setValue(true, forKey: "isInviteFriendShowed")
                }
            }
        }

        if let ShowReviewAlert = UserDefaults.standard.value(forKey: "ShowReviewAlert") as? Bool {
            if ShowReviewAlert == true {
                requestReview()
                UserDefaults.standard.setValue(true, forKey: "isReviewed")
                UserDefaults.standard.setValue(false, forKey: "ShowReviewAlert")
            }
        }
        
        self.go = false
        self.timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true,block: { timer in
            self.refresh(pickedCurrencyExchange: vm.pickedCurrencyExchange)
        })
      self.organizeManuals()
      if let sorted = UserDefaults.standard.value(forKey: "ManualTransactionForSorting") as? [String] {
        self.arrSorted = sorted
      }
      fetchNoTransactionCellData()
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
        getCurrencySymbol()
      }
    }
    .navigationViewStyle(StackNavigationViewStyle())
    .padding(.top, 6)
    .background(Color("background").ignoresSafeArea(edges: .all))
    .accentColor(.white)
    .onAppear {
      // self.sorting()
    }
    .blur(radius: isLoading ? 3 : 0)
    .overlay(
      ZStack {
        if isLoading {
          VStack {
            Text("Loading...")
              .foregroundColor(.white)
              .font(.system(size: 17, weight: .semibold))
            ProgressView()
              .tint(.white)
          }.padding(30)
            .padding(.horizontal)
            .background(
              RoundedRectangle(cornerRadius: 20).fill(Color("loginFields")).shadow(radius: 8)
            )
        }
      }
    )
  }
  
  // MARK: - Helper Functions
  
  func toggleMenu() {
    sideMenu.toggle()
  }
  
  func fetchNoTransactionCellData(){
    firestore.fetchNoTransactions {
      noTransactions = firestore.noTransactions
    }
  }
  
  func organizeManuals() {
    var array = manualTransactions
    sortedTransactions = [ManualTransaction]()
    sortedHomeManualTransactions = [ManualTransaction]()
    
    for manual in manualTransactions {
      if array.contains(where: {$0.exchange == manual.exchange && $0.symbol == manual.symbol}) {
        var sameManQuant = 0.0
        let filteredSameMan = array.filter({$0.symbol == manual.symbol && $0.exchange == manual.exchange})
        for sameMan in filteredSameMan {
          if sameMan.type == "bought" {
            sameManQuant += sameMan.quantity
          } else if sameMan.type == "sold" {
            sameManQuant -= sameMan.quantity
          }
        }
        let newMan = ManualTransaction(id: manual.id, notes: manual.notes, quantity: sameManQuant, marketPrice: manual.marketPrice, symbol: manual.symbol, timestamp: manual.timestamp, exchange: manual.exchange, type: "bought")
        array = array.filter({!($0.exchange == manual.exchange && $0.symbol == manual.symbol)})
        array.append(newMan)
      } else {
        array.append(manual)
      }
    }
    
    for (i,j) in array.enumerated(){
      if j.quantity == 0{
        array.remove(at: i)
      }
    }
    
    sortedTransactions = array
    
    for (i,trans) in sortedTransactions.enumerated() {
      let symobl = (trans.symbol.components(separatedBy: ",").last ?? "" )
      let marketPrice = vm.allCoins.first(where: {$0.symbol.lowercased().replacingOccurrences(of: " ", with: "") == symobl.lowercased().replacingOccurrences(of: " ", with: "")})?.currentPrice ?? 1.0
      
      let newTranc = ManualTransaction(id: trans.id, notes: trans.notes, quantity: trans.quantity, marketPrice: marketPrice, symbol: trans.symbol, timestamp: trans.timestamp, exchange: trans.exchange, type: trans.type, finalTotal: trans.finalTotal)
      
      sortedTransactions.remove(at: i)
      sortedTransactions.insert(newTranc, at: i)
    }
    
    var homeArray = sortedTransactions
    
    for man in sortedTransactions {
      if homeArray.contains(where: {$0.exchange == man.exchange}) {
        var sameManTotal = 0.0
        let filteredSameMan = homeArray.filter({$0.exchange == man.exchange})
        for sameMan in filteredSameMan {
          if man.type == "bought"{
            sameManTotal = (sameMan.total + (sameMan.finalTotal ?? 0))
          } else if man.type == "sold" {
            sameManTotal = (sameMan.total - (sameMan.finalTotal ?? 0))
          }
        }
        let newMan = ManualTransaction(id: man.id, notes: man.notes, quantity: man.quantity, marketPrice: man.marketPrice, symbol: man.symbol, timestamp: man.timestamp, exchange: man.exchange, type: man.type, finalTotal: sameManTotal)
        homeArray = homeArray.filter({($0.exchange != man.exchange)})
        homeArray.append(newMan)
      } else {
        let newManModified = ManualTransaction(id: man.id, notes: man.notes, quantity: man.quantity, marketPrice: man.marketPrice, symbol: man.symbol, timestamp: man.timestamp, exchange: man.exchange, type: man.type, finalTotal: man.total)
        homeArray.append(newManModified)
      }
    }
    
    sortedHomeManualTransactions = homeArray
    
  }
  
  private func getCurrencySymbol() {
        if vm.pickedCurrencyExchange == "RUB" {
          currentCurrencyExchangeSymbol = "₽"
        } else if vm.pickedCurrencyExchange == "XAG"{
            currentCurrencyExchangeSymbol = "Silver "
        }  else if vm.pickedCurrencyExchange == "XAU"{
            currentCurrencyExchangeSymbol = "Gold "
        }else {
            currentCurrencyExchangeSymbol = (currencyExchangeService.allSymbols.first(where: {$0.key == vm.pickedCurrencyExchange})?.value ?? "").htmlDecoded
        }
      
      if currentCurrencyExchangeSymbol == ""{
          currentCurrencyExchangeSymbol = vm.pickedCurrencyExchange
      }
  }
  
  private func getCoin() -> Coin? {
    var currentCrypto = ""
    if !currencies.filter({$0.image != "Home"}).isEmpty && currentPickedIndex >= 0 && currencies.filter({$0.image != "Home"}).count+1 > currentPickedIndex {
      currentCrypto = currencies[currentPickedIndex].name
    } else {
      currentCrypto = "Home"
    }
    guard let coin = vm.allCoins.first(where: {$0.symbol.lowercased() == currentCrypto.lowercased()}) else { return nil }
    return coin
  }
  
}

// MARK: - optionButtons

extension MainView {
  
  var optionButtons: some View {
    VStack {
      HStack {
        Text(sortedTransactions.count>0 ? "Wallets" : "Wallets").foregroundColor(Color.white)
          .font(.system(size: 25, weight: .bold))
        Spacer()
        Button(action: {
          exchangeView = true
        }, label: {
          Image(systemName: "list.star")
            .scaleEffect(1.2)
            .foregroundColor(.white)
            .overlay(
              Circle()
                .stroke(Color.white, lineWidth: 3.5)
                .frame(width: 40, height: 40)
            )
        })
      }.padding(UIScreen.main.bounds.size.width/20).padding(.trailing, UIScreen.main.bounds.size.width/20)
    }
    .fullScreenCover(isPresented: $exchangeView, content: {
        ExchangesView().environmentObject(self.firestore).dynamicTypeSize(.medium)
    })
    
  }
}

// MARK: - exchangesList

struct ExchangeRowCell: View {
  let isHome: Bool
  let transaction: ManualTransaction
  var currentCurrencyExchangeSymbol: String
  var currentCurrencyExchangeRate: Double
  @ObservedObject var manager: FirestoreManager
  @ObservedObject var vm: HomeViewModel
  var body: some View {
    HStack {
      let imageUrl = self.getImageFromlist(name: transaction.exchange!)
      if imageUrl != ""{
          CachedAsyncImage(url: URL(string: imageUrl), urlCache: .imageCache) { phase in
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
        if isHome {
          Text("\(currentCurrencyExchangeSymbol)\(NumberHelper.formatPoints(num: (transaction.finalTotal ?? 0).roundToPlaces(places: 2)))")
        } else {
          VStack {
            HStack {
              Text("\(transaction.quantity.clean)")
                .foregroundColor(Color("orange"))
              Text(transaction.symbol.components(separatedBy: ",").last ?? "" )
                .foregroundColor(Color("orange"))
            }
            Text("\(currentCurrencyExchangeSymbol)\(NumberHelper.formatPoints(num: ((vm.allCoins.first(where: {$0.symbol.lowercased().replacingOccurrences(of: " ", with: "") == (self.transaction.symbol.components(separatedBy: ",").last ?? "").lowercased().replacingOccurrences(of: " ", with: "")})?.currentPrice ?? 0) * transaction.quantity).roundToPlaces(places: 2)))")
              .foregroundColor(Color(hex: 0x94A3D3))
          }
        }
      }.foregroundColor(.white)
        .font(.system(size: 18, weight: .bold))
      VStack(spacing: 4){
        RoundedRectangle(cornerRadius: 5).fill(Color(hex: 0x445076))
          .frame(width: 20, height: 2)
        RoundedRectangle(cornerRadius: 5).fill(Color(hex: 0x445076))
          .frame(width: 20, height: 2)
      }.padding(.horizontal, 7)
        .padding(.leading, 3)
    }
    .frame(height:58.0)
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 20)
        .fill(Color(hex: 0x2C3656))
    )
  }
  
  func getImageFromlist(name: String) -> String {
    let exchange = manager.exchangesList.filter({$0.name == name})
    if exchange.count > 0{
      return exchange[0].iconURL
    } else {
      let exchange = manager.exchangesList.filter({$0.name == "Custom Exchange"})
      if exchange.count > 0 {
        return exchange[0].iconURL
      } else {
        return ""
      }
    }
  }
  
}
// MARK: - Preview

/*
 struct MainView_Previews: PreviewProvider {
 static var previews: some View {
 HomeView()
 .environmentObject(ViewRouter())
 .environmentObject(HomeViewModel())
 }
 }
 */

// MARK: - DragAndDropService

struct DragAndDropService: DropDelegate {
  let currentItem: ManualTransaction
  @Binding var mannualTransactionsOrder: [ManualTransactionForSorting]
  @Binding var items: [ManualTransaction]
  @Binding var draggedItem: ManualTransaction?
  @Binding var arrSorted: [String]
  func performDrop(info: DropInfo) -> Bool {
    return true
  }
  
  func dropEntered(info: DropInfo) {
    guard let draggedItem = draggedItem,
          draggedItem != currentItem,
          let from = items.firstIndex(of: draggedItem),
          let to = items.firstIndex(of: currentItem)
    else {
      return
    }
    
    withAnimation {
      items.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
      
      /*
       mannualTransactionsOrder[from].index = to > from ? to + 1 : to
       mannualTransactionsOrder[to > from ? to + 1 : to].index = from
       */
      
      var arrSorted = [String]()
      for i in items {
        arrSorted.append(i.exchange!)
      }
      self.arrSorted = arrSorted
      UserDefaults.standard.set(arrSorted, forKey: "ManualTransactionForSorting")
      UserDefaults.standard.synchronize()
    }
  }
  
}

extension MainView {
  private var ExtendedCircleView: some View {
    ScrollView(showsIndicators: false) {
      VStack(spacing: 15) {
        ForEach(currencies) { currency in
          HStack {
            ZStack {
              if currency.name == "Home" {
                Image(systemName: "house.fill")
                  .foregroundColor(.gray)
                  .frame(width: UIDevice.isIPad ? 50 : 30, height: UIDevice.isIPad ? 50 : 30)
              } else {
                CustomAsyncImage(url: currency.image, size: UIDevice.isIPad ? CGSize(width: 50, height: 50) : CGSize(width: 30, height: 30))
              }
            }
            Text(currency.name)
              .foregroundColor(.white)
              .font(.system(size: 20, weight: .bold))
            Spacer()
              cellCharts(currency: currency)
            VStack{
              ZStack {
                Text("\(currentCurrencyExchangeSymbol)\((NumberHelper.formatPoints(num:(currency.amount * currency.cryptoValue).roundToPlaces(places: 2))))")
              }
              .foregroundColor(.white)
              .font(.system(size: UIDevice.isIPad ? 70 : 18, weight: .bold))
              .padding(.top,10)
              ZStack {
                if currency.image != "Home" {
                  Text("\(currency.amount, specifier: "%.2f") \(currency.name)")
                }
              }
              .foregroundColor(.orange)
              .font(.system(size: UIDevice.isIPad ? 30 : 15, weight: .bold))
            }
          }
          .padding()
          .padding(.vertical, 10)
          .background(
            RoundedRectangle(cornerRadius: 20)
              .fill(Color("darkBlue"))
          )
          .onTapGesture {
            showExtendedCircleView = false
            currentPickedIndex = currencies.firstIndex(where: {$0.name == currency.name}) ?? 0
          }
          
        }
      }.padding()
    }.background(Color("background"))
    
  }
}

struct cellCharts: View {
    let currency: Currency
    var body: some View {
        if let _coin =  currency.coin {
            ChartView(coin: _coin, startingAt: nil,50,false)
        }
    }
}

struct exchangeTransactions: View {
    
    // MARK: - Variables
      
      @EnvironmentObject private var vm : HomeViewModel
      @Environment(\.dismiss) var dismiss
      @EnvironmentObject var firestore: FirestoreManager
    
      @Binding var manualTransactions : [ManualTransaction]
      @State private var pickedType = 0
      @State var currentCurrencyExchangeSymbol: String = ""
      
      // MARK: - Body
    
    var body: some View {
      NavigationView {
        ZStack {
          // Background Color
          Color("background").ignoresSafeArea(edges: .all)
          
          VStack{
            GeometryReader { geometry in
              List{
                  ForEach(manualTransactions) { transaction in
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
                            bottom: 8,
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


// MARK: - NoTransactionCell

struct NoTransactionCell: View {
  
  @Environment(\.openURL) var openURL
  let transaction: NoTransaction
  @State private var showingAlert = false
    @EnvironmentObject var firestore: FirestoreManager
  
  init(transaction: NoTransaction){
    self.transaction = transaction
  }
  var body: some View {
    HStack {
      VStack {
          CachedAsyncImage(url: URL(string: transaction.iconURL), urlCache: .imageCache) { phase in
          switch phase {
          case .empty:
              ProgressView()
            //ProgressView()
          case .success(let image):
            image.resizable()
              .aspectRatio(contentMode: .fit)
              .frame(maxWidth: 48, maxHeight: 48)
          case .failure:
            Image(systemName: "photo")
          @unknown default:
            EmptyView()
          }
        }
      }
      Text(transaction.name)
        .foregroundColor(.white)
      Image(systemName: "chevron.forward")
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .foregroundColor(.white)
    }
    .frame(height:58.0)
    .onTapGesture(perform: {
      self.showingAlert = true
    })
    .fullScreenCover(isPresented: $showingAlert, content: {
        ExchangesView().environmentObject(self.firestore).dynamicTypeSize(.medium)
    })
//    .alert(isPresented:$showingAlert) {
//      Alert(
//        title: Text("Are you sure you want to leave the app?"),
//        message: Text(""),
//        primaryButton: .default(Text("Yes")) {
//          openURL(URL(string: transaction.websiteURL)!)
//        },
//        secondaryButton: .destructive(Text("Cancel"))
//      )
//    }
  }
}
extension Array where Element: Reorderable {
  
  func reorder(by preferredOrder: [Element.OrderElement]) -> [Element] {
    sorted {
      guard let first = preferredOrder.firstIndex(of: $0.orderElement) else {
        return false
      }
      
      guard let second = preferredOrder.firstIndex(of: $1.orderElement) else {
        return true
      }
      
      return first < second
    }
  }
}
protocol Reorderable {
  associatedtype OrderElement: Equatable
  var orderElement: OrderElement { get }
}
extension Color {
    init(hex: Int, opacity: Double = 1.0) {
        let red = Double((hex & 0xff0000) >> 16) / 255.0
        let green = Double((hex & 0xff00) >> 8) / 255.0
        let blue = Double((hex & 0xff) >> 0) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
