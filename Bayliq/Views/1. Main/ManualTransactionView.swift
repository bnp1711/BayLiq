//
//  ManualTransactionView.swift
//  Bayliq
//
//  Created by David Razmadze on 10/23/22.
//

import SwiftUI
import FirebaseFirestore
import Firebase
import CachedAsyncImage

// MARK: - ManualTransactionView

struct ManualTransactionView: View {
    
    // MARK: - Variables
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var firestore : FirestoreManager
    @State private var date = Date()
    @State private var quantity = ""
    @State private var notes = ""
    @State private var exchange = 0
    @State private var customExchange = ""
    @State private var marketPrice = ""
    @State private var wantToExit = false
    @State private var pickedType = 0
    @State private var showOptions = false
    var currentCurrencyExchangeSymbol: String
    let typeOptions = ["Bought", "Sold"]
    
    let db = Firestore.firestore()
    
    @EnvironmentObject private var vm : HomeViewModel
    @State var currencies = [Currency(name: "Home", image: "Home", amount: 0.0, cryptoValue: 1.0, coin: nil)]
    @State var currentPickedIndex = 0
    @State var exchangeView = false
    @State var showDetailView = false
    
    @State var isFromManualTransaction = true
    @State var TokenName  = "BTC"
    @State var TokenFullName  = "bitcoin"
    @State var tokenPrice = 0.0
    @State var presentingModal = false
    @State var TokenImage : Image?
    @State private var isDatePickerVisible = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Background Color
                Color("background").ignoresSafeArea(edges: .all)
                
                VStack {
                    
                    // Bought or sold picker
                    SegmentedPicker(items: typeOptions, selection: $pickedType)
                        .padding(.horizontal)
                        .padding(.bottom)
                    
                    // Token Name
                    VStack {
                        Button {
                            hideKeyboard()
                            self.isFromManualTransaction = true
                            self.presentingModal = true
                        } label: {
                            HStack {
                                if TokenImage != nil {
                                    TokenImage?
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 30, height: 30)
                                        .padding(.leading,10)
                                    
                                }else{
                                    Image("bitcoin")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 30, height: 30)
                                        .padding(.leading,10)
                                }
                                TextField("", text: $TokenName).disableAutocorrection(true).padding().padding(.leading,-10).foregroundColor(.white).keyboardType(.emailAddress).cornerRadius(12)
                                    .placeholder(when: TokenName.isEmpty) {
                                        Text("Enter token name").foregroundColor(Color.white).offset(x: 15, y: 0)
                                    }
                                    .multilineTextAlignment(.leading)
                                    .allowsHitTesting(false)
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 12).stroke(Color("loginFields"), lineWidth: 2)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 5)
                        }
                        
                        // Quantity
                        TextField("", text: $quantity).disableAutocorrection(true).autocapitalization(.none).padding().foregroundColor(.white)
                            .keyboardType(.decimalPad)
                            .placeholder(when: quantity.isEmpty) {
                                Text("Enter quantity").foregroundColor(Color.white).offset(x: 15, y: 0)
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 12).stroke(Color("loginFields"), lineWidth: 2)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 5)
                        
                        // Market Price
                        HStack{
                            Text(self.currentCurrencyExchangeSymbol)
                                .foregroundColor(.white)
                                .padding(.leading)
                                .padding(.top)
                                .padding(.bottom)
                            TextField("", text: Binding(get: { marketPrice }, set: { newValue in
                                // Prepend $
                                if marketPrice.starts(with: self.currentCurrencyExchangeSymbol) {
                                    marketPrice = newValue
                                } else {
                                    marketPrice = newValue
                                }
                            }))
                            .onTapGesture {
                                if self.tokenPrice != 0.0 && Calendar.current.isDateInToday(self.date) {
                                    if self.date.toString(dateFormat: "dd-MM-yyyy") == Date().toString(dateFormat: "dd-MM-yyyy") {
                                        self.marketPrice = "\(self.tokenPrice)"
                                    }
                                }
                            }.disableAutocorrection(true).autocapitalization(.none).foregroundColor(.white)
                                .placeholder(when: marketPrice == "") {
                                    Text("Market Price").foregroundColor(Color.white).offset(x: 10, y: 1)
                                }
                                .keyboardType(.decimalPad)
                            
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 12).stroke(Color("loginFields"), lineWidth: 2)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                        // Notes - user can add anything here
                        TextField("", text: $notes).disableAutocorrection(true).autocapitalization(.none).padding().foregroundColor(.white)
                            .placeholder(when: notes.isEmpty) {
                                Text("Enter Notes (Optional)").foregroundColor(Color.white).offset(x: 15, y: 0)
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 12).stroke(Color("loginFields"), lineWidth: 2)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 5)
                    }
                    
                    let excluded = firestore.exchangesList.filter { item in
                        !firestore.unCheckedexchangesList.contains{item.name == $0.name}
                    }
                    // Exchange
                    DropdownExchangePicker(title: "Exchange:", selection: $exchange, customText: $customExchange, options: excluded,showOptions: $showOptions)
                    
                    // Date
                    VStack {
                        HStack {
                            Text("Transaction Date")
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: {
                                isDatePickerVisible.toggle()
                            }) {
                                Text(date.toString(dateFormat: "MMM dd, HH:mm"))
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                    .padding(.bottom, 16)
                            }
                        }
                        .padding(.leading)
                    }
                    .sheet(isPresented: $isDatePickerVisible) {
                        DatePickerDialog(date: $date, isPresented: $isDatePickerVisible, onDateChange: fetchCoinPrice)
                    }
                    .onChange(of: date) { newValue in
                        fetchCoinPrice(for: newValue)
                    }
                    
                    
                    Button(action: {
                        submitButtonTapped()
                    }, label: {
                        Text("Submit")
                            .foregroundColor(Color.white)
                            .frame(width: UIScreen.main.bounds.width, height: 50)
                            .padding(.horizontal, -18)
                            .background(Color("orange"))
                            .font(.system(size: 20, weight: .bold))
                    })
                    .cornerRadius(12)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            wantToExit = true
                        }
                    }, label: {
                        Text("Exit")
                            .foregroundColor(Color.white)
                            .frame(width: UIScreen.main.bounds.width, height: 50)
                            .padding(.horizontal, -18)
                            .font(.system(size: 20, weight: .regular))
                    })
                    .cornerRadius(12)
                }
                .sheet(isPresented: $showOptions) {
                    let excluded = firestore.exchangesList.filter { item in
                        !firestore.unCheckedexchangesList.contains{item.name == $0.name}
                    }
                    CustomExchangeView(selection:$exchange, showOptions: $showOptions, options:excluded,customText:$customExchange)
                        .background(Color("background"))
                }
                
                if wantToExit {
                    Color.black.opacity(0.7)
                        .transition(.opacity)
                    confirmationView()
                        .transition(.scale)
                }
            }
            .onAppear{
                if self.tokenPrice == 0.0 {
                    let coins = self.vm.allCoins.filter{ $0.symbol.lowercased() == "btc"}
                    if coins.count > 0 {
                        self.tokenPrice = (coins[0].currentPrice ?? 0)
                    }
                    
                    
                }
            }
            .sheet(isPresented: $presentingModal) {
                HomeView(vm: vm,isFromManualTransaction: $isFromManualTransaction,TokenName: $TokenName,TokenFullName: $TokenFullName, TokenPrice: $tokenPrice, TokenImage: $TokenImage, presentedAsModal: $presentingModal, currentCurrencyExchangeSymbol: currentCurrencyExchangeSymbol)
                    .environmentObject(self.firestore)
            }
            .onTapGesture {
                self.hideKeyboard()
            }
            .navigationTitle("Record Transaction")
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
    }
    struct DatePickerDialog: View {
        @Binding var date: Date
        @Binding var isPresented: Bool
        var onDateChange: (Date) -> Void
        @Environment(\.colorScheme) var colorScheme
        
        var body: some View {
            ZStack {
                Color("darkBlue").edgesIgnoringSafeArea(.all)
                VStack {
                    DatePicker(
                        "Select Date and Time",
                        selection: $date,
                        //in: Date(timeIntervalSince1970: 0)...,
                        in:Date(timeIntervalSince1970: 0)...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                        
                    )
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .labelsHidden()
                    .padding()
                    .background(Color("background"))
                    .font(.system(size: 20, weight: .bold))
                    .colorMultiply(.white)
                    .preferredColorScheme(.dark)
                    .accentColor(Color("orange"))
                    .onChange(of: date) { newValue in
                        onDateChange(newValue)
                    }
                    Button("Done") {
                        isPresented = false
                    }
                    .padding()
                    .frame(width: UIScreen.main.bounds.width, height: 50)
                    .padding(.horizontal, -18)
                    .background(Color("orange"))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.white)
                }
                
                .background(Color("background"))
                .cornerRadius(10)
                .padding()
            }
        }
    }
    
    
    
    
    private func fetchCoinPrice(for date: Date) {
        let strDate = date.toString(dateFormat: "dd-MM-yyyy")
        Api().getCoinPriceForDate(coinID: TokenFullName, date: strDate) { coin in
            var symbol = currentCurrencyExchangeSymbol.lowercased()
            if symbol == "$" {
                symbol = "usd"
            } else if symbol == "₽" {
                symbol = "rub"
            } else if symbol == "Silver" {
                symbol = "xag"
            } else if symbol == "Gold" {
                symbol = "xau"
            }
            if let price = coin.market_data?.current_price[symbol] {
                self.marketPrice = String(format: "%.2f", price)
            } else {
                self.marketPrice = ""
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func submitButtonTapped() {
        guard !TokenName.isEmpty, !quantity.isEmpty, !marketPrice.isEmpty, marketPrice != "$" else { return }
        guard Double(marketPrice)! > 0.0 else { return }
        let quantity = replaceComma(str: quantity)
        guard !TokenName.isNumeric, quantity > 0.0 else { return }
        let transactionType = typeOptions[pickedType].lowercased()
        var purchasedAt = ""
        let coins = self.vm.allCoins.filter{$0.symbol.lowercased() == TokenName.lowercased()}
        if coins.count > 0 {
            purchasedAt = "\(currentCurrencyExchangeSymbol)\(coins[0].currentPrice)"
        }
        let excluded = firestore.exchangesList.filter { item in
            !firestore.unCheckedexchangesList.contains{item.name == $0.name}
        }
        let transaction = ManualTransaction(id: UUID().uuidString, notes: notes, quantity: quantity, marketPrice: Double(marketPrice) ?? 1.0, symbol: TokenName, timestamp: Int(date.timeIntervalSince1970), exchange: (exchange != excluded.count - 1) ? excluded[exchange].name : customExchange , purchasedAt: purchasedAt, type: transactionType)
        
        firestore.uploadManualTransaction(transaction: transaction) { error in
            if let error {
                print("Error uploading manual transaction: \(error)")
                return
            }
            
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    func getMindate() -> Date{
        let expiryDate = "2013-01-01"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: expiryDate)!
    }
    
    private func replaceComma(str: String) -> Double {
        if let range = str.range(of: ",") {
            let testStr = str.replacingCharacters(in: range, with: ".")
            return Double(testStr) ?? 0
        } else {
            return Double(str) ?? 0
        }
    }
    
    @ViewBuilder
    func confirmationView() -> some View {
        VStack {
            Text("Are you sure, you want to exit?")
                .foregroundColor(.white)
                .font(.system(size: 18, weight: .semibold))
                .padding(.bottom)
            HStack(spacing: 25) {
                Button(action: {
                    withAnimation(.spring()){
                        wantToExit = false
                    }
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Yes")
                        .foregroundColor(.white)
                        .padding(10)
                        .padding(.horizontal, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.green))
                }.customButtonStyle()
                Button(action: {
                    withAnimation(.spring()){
                        wantToExit = false
                    }
                }) {
                    Text("No")
                        .foregroundColor(.white)
                        .padding(10)
                        .padding(.horizontal, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.red))
                }.customButtonStyle()
            }
        }.padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("background"))
            )
            .padding(20)
    }
    
}

extension Date {
    func formatToString(dateFormat format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}
// MARK: - Preview

struct ManualTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        ManualTransactionView(firestore: FirestoreManager(), currentCurrencyExchangeSymbol: "")
    }
}

// MARK: - DropdownPicker
struct DropdownExchangePicker: View {
    var title:String
    @Binding var selection:Int
    @Binding var customText:String
    var options:[CryptoExchange]
    @Binding  var showOptions: Bool
    var body: some View {
        ZStack {
            // Static row which shows user's current selection
            HStack {
                Text(title)
                    .foregroundColor(.white)
                Spacer()
                
                //        if  customText == ""{
                //          Text(customText)
                //            .foregroundColor(Color.white)
                //        } else {
                if options.count>0 {
                    CachedAsyncImage(url: URL(string: options[selection].iconURL), urlCache: .imageCache) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image.resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 20, maxHeight: 20)
                        case .failure:
                            Image(systemName: "photo")
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                if selection == options.count - 1 {
                    Text(customText == "" ? "Custom Exchange" : customText)
                        .foregroundColor(Color.white)
                }else{
                    Text(!options.isEmpty ? options[selection].name : "is loading")
                        .foregroundColor(Color.white)
                }
                
                //        }
                
                Image(systemName: "chevron.right")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 10, height: 10)
                    .foregroundColor(.white)
            }
            .font(.system(size: 16))
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color("background"))
            .onTapGesture {
                // show the dropdown options
                withAnimation(Animation.spring().speed(2)) {
                    
                    showOptions = true
                }
            }
        }
    }
}
struct DropdownPicker: View {
    
    var title: String
    @Binding var selection: Int
    var options: [String]
    
    @State private var showOptions: Bool = false
    
    var body: some View {
        ZStack {
            // Static row which shows user's current selection
            HStack {
                Text(title)
                    .foregroundColor(.white)
                Spacer()
                Text(!options.isEmpty ? options[selection] : "error")
                    .foregroundColor(Color.white)
                Image(systemName: "chevron.right")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 10, height: 10)
                    .foregroundColor(.white)
            }
            .font(.system(size: 16))
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color("background"))
            .onTapGesture {
                // show the dropdown options
                withAnimation(Animation.spring().speed(2)) {
                    showOptions = true
                }
            }
            
            // Drop down options
            if showOptions {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                    HStack {
                        Spacer()
                        ForEach(options.indices, id: \.self) { i in
                            if i == selection {
                                Text(options[i])
                                    .font(.system(size: 16))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(4)
                                    .onTapGesture {
                                        
                                        withAnimation(Animation.spring().speed(2)) {
                                            showOptions = false
                                        }
                                    }
                            } else {
                                Text(options[i])
                                    .font(.system(size: 16))
                                    .onTapGesture {
                                        // update user selection and close options dropdown
                                        withAnimation(Animation.spring().speed(2)) {
                                            selection = i
                                            showOptions = false
                                        }
                                    }
                            }
                            Spacer()
                        }
                    }
                    .padding(.vertical, 2)
                    .transition(AnyTransition.move(edge: .top).combined(with: .opacity))
                    
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color("background"))
                .foregroundColor(.white)
                .transition(.opacity)
                
            }
            
        }
    }
}

// MARK: - SizeAwareViewModifier

struct SizeAwareViewModifier: ViewModifier {
    
    @Binding private var viewSize: CGSize
    
    init(viewSize: Binding<CGSize>) {
        self._viewSize = viewSize
    }
    
    func body(content: Content) -> some View {
        content
            .background(BackgroundGeometryReader())
            .onPreferenceChange(SizePreferenceKey.self, perform: { if self.viewSize != $0 { self.viewSize = $0 }})
    }
}

// MARK: - SizePreferenceKey

struct SizePreferenceKey: PreferenceKey {
    typealias Value = CGSize
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - BackgroundGeometryReader

struct BackgroundGeometryReader: View {
    var body: some View {
        GeometryReader { geometry in
            return Color
                .clear
                .preference(key: SizePreferenceKey.self, value: geometry.size)
        }
    }
}

// MARK: - SegmentedPicker

struct SegmentedPicker: View {
    
    // MARK: - Variables
    
    private static let BackgroundColor: Color = Color("darkBlue")
    private static let ShadowColor: Color = Color.black.opacity(0.2)
    private static let TextColor: Color = Color(.white)
    private static let SelectedTextColor: Color = Color(.white)
    
    private static let TextFont: Font = .system(size: 12)
    
    private static let SegmentCornerRadius: CGFloat = 12
    private static let ShadowRadius: CGFloat = 4
    private static let SegmentXPadding: CGFloat = 16
    private static let SegmentYPadding: CGFloat = 8
    private static let PickerPadding: CGFloat = 4
    
    private static let AnimationDuration: Double = 0.25
    
    @State private var segmentSize: CGSize = .zero
    private var activeSegmentView: AnyView {
        let isInitialized: Bool = segmentSize != .zero
        if !isInitialized { return EmptyView().eraseToAnyView() }
        return RoundedRectangle(cornerRadius: SegmentedPicker.SegmentCornerRadius)
            .foregroundColor(
                items.count > 2 ? selection == 2 ? .red : .green  : selection == 0 ? .green : .red
            )
            .shadow(color: SegmentedPicker.ShadowColor, radius: SegmentedPicker.ShadowRadius)
            .frame(width: self.segmentSize.width, height: self.segmentSize.height)
            .offset(x: self.computeActiveSegmentHorizontalOffset(), y: 0)
            .animation(Animation.linear(duration: SegmentedPicker.AnimationDuration))
            .eraseToAnyView()
    }
    
    @Binding private var selection: Int
    private let items: [String]
    
    // MARK: - Init
    
    init(items: [String], selection: Binding<Int>) {
        self._selection = selection
        self.items = items
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .leading) {
            self.activeSegmentView
            HStack {
                ForEach(0..<self.items.count, id: \.self) { index in
                    self.getSegmentView(for: index)
                }
            }
        }
        .padding(SegmentedPicker.PickerPadding)
        .background(SegmentedPicker.BackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: SegmentedPicker.SegmentCornerRadius))
    }
    
    // MARK: - Helper Functions
    
    private func computeActiveSegmentHorizontalOffset() -> CGFloat {
        CGFloat(self.selection) * (self.segmentSize.width + SegmentedPicker.SegmentXPadding / 2)
    }
    
    private func getSegmentView(for index: Int) -> some View {
        guard index < self.items.count else {
            return EmptyView().eraseToAnyView()
        }
        let isSelected = self.selection == index
        return Text(self.items[index])
            .foregroundColor(isSelected ? SegmentedPicker.SelectedTextColor: SegmentedPicker.TextColor)
            .lineLimit(1)
            .padding(.vertical, SegmentedPicker.SegmentYPadding)
            .padding(.horizontal, SegmentedPicker.SegmentXPadding)
            .frame(minWidth: 0, maxWidth: .infinity)
            .modifier(SizeAwareViewModifier(viewSize: self.$segmentSize))
            .onTapGesture { self.onItemTap(index: index) }
            .eraseToAnyView()
    }
    
    private func onItemTap(index: Int) {
        guard index < self.items.count else {
            return
        }
        self.selection = index
    }
    
}

// MARK: - CustomButtonStyle

struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
extension ManualTransactionView {
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
    var optionButtons: some View {
        VStack { HStack {
            if let coin = getCoin() {
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
            Spacer()
            Image(systemName: "wrench.and.screwdriver").foregroundColor(.white).overlay(
                Circle().stroke(Color.white, lineWidth: 2).frame(width: 50, height: 50))
        }.padding(UIScreen.main.bounds.size.width/20).padding(.trailing, UIScreen.main.bounds.size.width/20).padding(.bottom, UIScreen.main.bounds.size.height/12)
            HStack {
                Text("Wallets").foregroundColor(Color.white)
                    .font(.system(size: 25, weight: .bold))
                Spacer()
                Button(action: {
                    exchangeView = true
                }, label: {
                    Image(systemName: "plus").foregroundColor(.white).overlay(
                        Circle().stroke(Color.white, lineWidth: 2).frame(width: 50, height: 50))
                })
            }.padding(UIScreen.main.bounds.size.width/20).padding(.trailing, UIScreen.main.bounds.size.width/20).padding(.top, -UIScreen.main.bounds.size.height/12)
        }
        .fullScreenCover(isPresented: $exchangeView, content: {
            ExchangesView().environmentObject(self.firestore).dynamicTypeSize(.medium)
        })
        .fullScreenCover(isPresented: $showDetailView) {
            if getCoin() != nil {
                DetailView(coin: getCoin()!, isFullScreenCover: true, firestore: self.firestore).dynamicTypeSize(.medium)
            }
        }
        
    }
}
