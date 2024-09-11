//
//  SettingsView.swift
//  Bayliq
//
//  Created by Natanael Jop on 13/11/2022.
//

import SwiftUI
import FirebaseAuth
import Firebase
import GoogleSignIn
import LocalAuthentication

// MARK: - CircleSortingOption

enum CircleSortingOption: Int, CaseIterable {
  case descending
  case marketCap
  case custom
  
  var name: String {
    switch self {
    case .descending: return "Descending"
    case .marketCap: return "Market Cap"
    case .custom: return "Custom"
    }
  }
}

// MARK: - CurrencyForCustomOrdering

struct CurrencyForCustomOrdering: Codable {
  var idx: Int
  var currency: Currency
}

// MARK: - SettingsView

struct SettingsView: View {
  
  // MARK: - Variables
  
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var vm: FirestoreManager
  @EnvironmentObject var viewRouter: ViewRouter
  @EnvironmentObject var sortingHelper: SortingHelper
  @EnvironmentObject var currencyExchangeService: CurrencyExchangeService
  @EnvironmentObject var viewModel: GoogleAuthenticationViewModel
  
  let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
  let date = Date().timeIntervalSince1970
  
  @State var signOutProcessing = false
  @State var sortOption: CircleSortingOption = .descending
  @Binding var currencies: [Currency]
  @State var currenciesForCustomOrdering = [CurrencyForCustomOrdering]()
  @State var showConf = false
    @State var showBioAlert = false
  @State var isAppleuser = false
    @Binding var pickedCurrencyExchange : String
    @AppStorage("BiometricLogin") private var BiometricLogin = false
  
//  var filteredExchanges: [String : Double] {
//    currencyExchangeService.allExchanges
//      .filter({vm.currencyExchangeList.contains($0.key)})
//      //.filter( { $0.key == "USD"}) // for now only keep USD dollars
//  }
    var filteredExchanges: [String] {
        vm.currencyExchangeList.sorted(by: <)
      //currencyExchangeService.allExchanges
      //  .filter({vm.currencyExchangeList.contains($0.key)})
        //.filter( { $0.key == "USD"}) // for now only keep USD dollars
    }
  
  // MARK: - Body
  
  var body: some View {
    NavigationView {
      Form {
        // User Info
        Section(header: Text("User Info")) {
          HStack{
            Text("Email")
            Spacer()
              Text(vm.user.email.contains("privaterelay") ? "Apple Private Relay" : vm.user.email)
          }
          HStack{
            Text("Username")
            Spacer()
            Text(vm.user.username)
          }
          HStack{
            Text("Member since")
            Spacer()
            Text("\(Date(timeIntervalSince1970: TimeInterval(vm.user.memberSince)).formatted())")
          }
        }
        
        // Custom Options
        Section(header: Text("Custom Options")) {
          Picker("Sorting options", selection: $sortOption) {
            ForEach(CircleSortingOption.allCases, id:\.self){ Text($0.name) }
          }.onChange(of: sortOption) { newValue in
            UserDefaults.standard.setValue(newValue.rawValue, forKey: "sortOption")
          }
          if sortOption == .custom {
            List {
              ForEach(currenciesForCustomOrdering.filter({$0.currency.image != "Home"}), id:\.idx) { currency in
                HStack {
                  Text(currency.currency.name)
                  Spacer()
                  Image(systemName: "line.3.horizontal")
                    .foregroundColor(Color(UIColor.systemGray2))
                }.padding(.horizontal)
              }.onMove(perform: moveRow(source:destination:))
            }.environment(\.editMode, Binding.constant(EditMode.active))
          }
            HStack {
                Text("Currency")
                Spacer()
                if pickedCurrencyExchange != "" {
                    if filteredExchanges.contains(pickedCurrencyExchange){
                        Picker("", selection: $pickedCurrencyExchange) {
                            ForEach(filteredExchanges, id: \.self) {
                                if $0 == "XAG" {
                                    Text("\($0) Silver")
                                }else if $0 == "XAU"{
                                    Text("\($0) Gold")
                                }else{
                                    Text($0)
                                }
                            }
                        }.labelsHidden()
                    }else{
                        if filteredExchanges.count > 0 {
                            Picker("", selection: $pickedCurrencyExchange) {
                                ForEach(filteredExchanges, id: \.self) {
                                    if $0 == "XAG" {
                                        Text("\($0) Silver")
                                    }else if $0 == "XAU"{
                                        Text("\($0) Gold")
                                    }else{
                                        Text($0)
                                    }
                                }
                            }.labelsHidden()
                        }
                    }
            }
            
          }
            Toggle("Biometric Authentication (Face ID)", isOn: $BiometricLogin)
                .onAppear{
                    viewRouter.isLoggedIn = true
                }
        }
        
        // About
        Section(header: Text("About")) {
          HStack {
            Text("Version")
            Spacer()
            Text(appVersion ?? "")
          }
          
          HStack {
            Text("API Limit")
            Spacer()
            Text("Exceeding the rate limit may result in temporary delays (500 calls/min). \nAPI by CoinGecko")
              .foregroundColor(.gray)
          }
        }
        
        // Buttons
        Section(header: Text("")) {
          if signOutProcessing {
            ProgressView()
          } else {
            Button(action: {
              signOutUser()
            }, label: {
              Text("Sign Out")
                .foregroundColor(.red)
            })
            
            Button(action: {
              signOutProcessing = true
              self.getProvider()
            }, label: {
              Text("Delete User")
                .foregroundColor(.red)
            })
          }
          
        }
      }
      .background(Color.yellow)
      .navigationBarTitle("Settings")
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button(action: {
            dismiss()
            sortingHelper.wantToSort = true
            
            var finalArray = [CurrencyForCustomOrdering]()
            for i in currenciesForCustomOrdering.indices {
              finalArray.append(CurrencyForCustomOrdering(idx: i, currency: currenciesForCustomOrdering[i].currency))
            }
            if let encoded = try? JSONEncoder().encode(finalArray) {
              UserDefaults.standard.set(encoded, forKey: "customSortCurrencies")
            }
          }) {
            Image(systemName: "chevron.down")
              .foregroundColor(.white)
          }
        }
      }
      .onAppear {
        sortOption = CircleSortingOption(rawValue: UserDefaults.standard.integer(forKey: "sortOption")) ?? .descending
        currenciesForCustomOrdering = [CurrencyForCustomOrdering]()
        
        if let data = UserDefaults.standard.object(forKey: "customSortCurrencies") as? Data,
           let customSortedCurrencies = try? JSONDecoder().decode([CurrencyForCustomOrdering].self, from: data) {
          currenciesForCustomOrdering = customSortedCurrencies
        } else {
          for i in currencies.indices {
            currenciesForCustomOrdering.append(CurrencyForCustomOrdering(idx: i, currency: currencies[i]))
          }
        }
      }
    }
   
    .onChange(of: self.BiometricLogin, perform: { newValue in
//        if newValue == true {
            let context = LAContext()
            var error: NSError?

            // check whether biometric authentication is possible
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            }else{
                showBioAlert = true
            }
      //  }
    })
    .alert("Biometric login not enabled", isPresented: $showBioAlert, actions: {
      Button("No") {
        self.showBioAlert = false
      }
    }, message: {
      Text("Please enable biometric login in settings app.")
    })
    .alert("Delete account", isPresented: $showConf, actions: {
      Button {
        //            self.showConf = false
        if let credential = googleCredential(){
          self.reauthenticate(credential: credential)
        }else if self.isAppleuser{
            //REVOKE TOKEN
            
            let token = KeychainManager.get(service: "apple.com", account: "my_account")
            if let token = token {
              
              let tokenString = String(decoding: token, as: UTF8.self)
              
              let url = URL(string: "https://us-central1-bayliq-72340.cloudfunctions.net/revokeToken?refresh_token=\(tokenString)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "https://apple.com")!
              
              let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                guard data != nil else { return }
              }
              
              task.resume()
              
            }
            
            //DELETE USER
            let user = Auth.auth().currentUser
            
            user?.delete { error in
              if let error {
                print("Error deleting user: \(error.localizedDescription)")
              } else {
                  print("User was successfully deleted.")
                  self.signOutUser()
                do {
                  try KeychainManager.delete(service: "apple.com", account: "my_account")
                } catch {
                  print(error)
                }
              }
            }
        }
      } label: {
        Text("Yes")
          .foregroundColor(.red)
      }
      
      Button("No") {
        self.showConf = false
        signOutProcessing = false
      }
    }, message: {
      Text("Are you sure you want to delete your account?")
    })
  }
  
  // MARK: - Helper Functions
  
  private func moveRow(source: IndexSet, destination: Int){
    currenciesForCustomOrdering.move(fromOffsets: source, toOffset: destination)
  }
  
  func getProvider(){
    if let providerData = Auth.auth().currentUser?.providerData {
      for userInfo in providerData {
        switch userInfo.providerID {
        case "apple.com":
            self.showConf = true
            self.isAppleuser = true
            print("user is signed in with Apple")
        case "google.com":
          self.showConf = true
          print("user is signed in with google")
        case "password":
          withAnimation {
            viewRouter.currentPage = .deleteAccountPage
            signOutProcessing = false
          }
        default:
          print("unknown auth provider")
        }
      }
    }
  }
  
  func reauthenticate(credential:AuthCredential){
    Auth.auth().currentUser?.reauthenticate(with: credential) { _,error  in
      if let error = error {
        print("reauth error \(error.localizedDescription)")
      } else {
        print("no reauth error")
        print("deleting user records")
        Auth.auth().currentUser!.delete { error in
          if let error = error {
            // An error happened.
            print(error.localizedDescription)
          } else {
            // Account deleted.
            withAnimation {
                self.viewRouter.isLoggedIn = false
              viewRouter.currentPage = .signInPage
              signOutProcessing = false
            }
          }
        }
      }
    }
  }
  
  func googleCredential() -> AuthCredential? {
    guard let user = GIDSignIn.sharedInstance.currentUser
    else {
      return nil
    }
    let authentication = user.authentication
    let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken!, accessToken: authentication.accessToken)
    return credential
  }
  
  func signOutUser() {
    signOutProcessing = true
    let firebaseAuth = Auth.auth()
    do {
      try firebaseAuth.signOut()
      GIDSignIn.sharedInstance.signOut()
        self.viewRouter.isLoggedIn = false
    } catch let signOutError as NSError {
      print("Error signing out: %@", signOutError)
      signOutProcessing = false
    }
    withAnimation {
      viewRouter.currentPage = .signInPage
    }
  }
}

// MARK: - Preview

/*
 struct SettingsView_Previews: PreviewProvider {
 static var previews: some View {
 SettingsView().environmentObject(FirestoreManager()).environmentObject(ViewRouter())
 }
 }
 */
