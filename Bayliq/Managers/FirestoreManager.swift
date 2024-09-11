//
//  FirestoreManager.swift
//  Bayliq
//
//  Created by Nuno Mestre on 7/30/22.
//

import Foundation
import Firebase
import GoogleSignIn
import AuthenticationServices

/// Manages all interactions with the Firebase Firestore Database
class FirestoreManager: ObservableObject {
  
  // MARK: - Variables
  
  let db = Firestore.firestore()
  
  @Published var isloading = false
  @Published var user = BayliqUser(id: "default", username: "default", email: "default", memberSince: 1970)
  @Published var allTransactions = [ManualTransaction]()
  @Published var noTransactions = [NoTransaction]()
    @Published var supports = [Support]()
    @Published var sideMenuImageurl = ""
  @Published var exchangesList = [CryptoExchange]()
    @Published var customTop10 = [String]()
  @Published var unCheckedexchangesList = [CryptoExchange]()
  @Published var currencyExchangeList = [String]()
  @Published var walkthroughURL = ""
    var exchangeListRowdata = [Any]()
    var numberOfCoins : Int = 1000
    var listener : ListenerRegistration!
  // MARK: - User Functions
  
  init() {
    getExchanges()
    getWalkthrough()
    getCurrencyExchanges()
    getUserData()
      getNumberOfCoins()
      deleteUsersCollection()
//      exportUsersCollection()
    self.fetchUncheckedExchanges {
      //Unchecked
    } notFoundCompletion: {
      //No unchecked
    }
  }
    
    
    //delete
    func deleteUsersCollection() {
        let firestore = Firestore.firestore()
        let usersCollection = firestore.collection("users")

        usersCollection.getDocuments { (snapshot, error) in
            guard let snapshot = snapshot else {
                print("Error fetching documents: \(String(describing: error))")
                return
            }

            let batch = firestore.batch()
            snapshot.documents.forEach { batch.deleteDocument($0.reference) }

            batch.commit { (error) in
                if let error = error {
                    print("Error deleting collection: \(error)")
                } else {
                    print("Collection 'users' successfully deleted.")
                }
            }
        }
    }

    
    //Export function
    func exportUsersCollection() {
        let firestore = Firestore.firestore()
        let usersCollection = firestore.collection("users")

        usersCollection.getDocuments { (snapshot, error) in
            guard let snapshot = snapshot else {
                print("Error getting documents: \(String(describing: error))")
                return
            }

            var usersData: [[String: Any]] = []

            for document in snapshot.documents {
                var documentData = document.data()
                documentData["id"] = document.documentID
                usersData.append(documentData)
            }

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: usersData, options: .prettyPrinted)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print(jsonString)
                    self.saveToFile(jsonString: jsonString)
                }
            } catch {
                print("Error serializing JSON: \(error)")
            }
        }
    }
    
    
    func saveToFile(jsonString: String) {
        let fileName = "users-export.json"
        if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentDirectory.appendingPathComponent(fileName)
            do {
                try jsonString.write(to: fileURL, atomically: true, encoding: .utf8)
                print("File saved to: \(fileURL)")
                self.showShareDialog(fileURL: fileURL)
            } catch {
                print("Error saving file: \(error)")
            }
        }
    }
    
    func showShareDialog(fileURL: URL) {
        guard let viewController = UIApplication.shared.windows.first?.rootViewController else {
            print("No root view controller found")
            return
        }

        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        activityViewController.excludedActivityTypes = [
            .assignToContact,
            .saveToCameraRoll,
            .addToReadingList,
            .postToFlickr,
            .postToVimeo,
            .postToTencentWeibo,
            .postToWeibo
        ]

        viewController.present(activityViewController, animated: true, completion: nil)
    }
    func getNumberOfCoins() {
        
      db.collection(FStore.Collections.config)
        .document("NumberOfCoins")
        .getDocument { snap, error in
          if let error = error {
            print("Error: \(error.localizedDescription)")
          } else {
            guard let number = snap?.data()?["Coins"] as? Int else { return }
            self.numberOfCoins = number
          }
        }
    }
  
  func registerUserData(userName: String) {
    let epoch = Int(NSDate().timeIntervalSince1970)
    let date = TimeInterval(epoch)
    
    if let emailAddress = Auth.auth().currentUser?.email {
      db.collection(FStore.Collections.users).addDocument(data: [FStore.DataName.username: userName, FStore.DataName.email: emailAddress, FStore.DataName.memberSince: date]) { error in
        if let e = error {
          print("There was an issue saving data to Firestore. \(e)")
        } else {
          print("Success! Data sent!")
        }
      }
    }
  }
 
    func registerAppleUser(credential: ASAuthorizationAppleIDCredential,displayName: String){
        if let UID = Auth.auth().currentUser?.uid {
        // Check if its sign in or up
            db.collection(FStore.Collections.users).whereField(FStore.DataName.UID, isEqualTo: UID).getDocuments { (querySnapshot, err) in
                if let err = err {
                print("Error getting documents: \(err)")
                } else {
                if  querySnapshot!.documents.isEmpty{
                    // It's sign up
                    let epoch = Int(NSDate().timeIntervalSince1970)
                    let date = TimeInterval(epoch)

                    if let emailAddress = Auth.auth().currentUser?.email {
                        self.db.collection(FStore.Collections.users).addDocument(data: [FStore.DataName.username: displayName, FStore.DataName.email: emailAddress, FStore.DataName.memberSince: date,FStore.DataName.UID:UID]) { error in
                            if let e = error {
                                print("There was an issue saving data to Firestore. \(e)")
                            } else {
                                print("Success! Data sent!")
                            }
                        }
                    }else{
                        self.db.collection(FStore.Collections.users).addDocument(data: [FStore.DataName.username: displayName, FStore.DataName.memberSince: date,FStore.DataName.UID:UID]) { error in
                            if let e = error {
                                print("There was an issue saving data to Firestore. \(e)")
                            } else {
                                print("Success! Data sent!")
                            }
                        }
                    }
                } else {
                    // It's sign in
                    if displayName == "" {return}
                    let docId = querySnapshot!.documents[0].documentID
                    let userData = querySnapshot!.documents[0].data()
                    if let userName = userData[FStore.DataName.username] as? String,
                        let date = userData[FStore.DataName.memberSince] as? Int,
                        let email = userData[FStore.DataName.email] as? String,
                        let UID = userData[FStore.DataName.UID] as? String {
                            if userName == displayName && displayName != ""{
                                self.user = BayliqUser(id: docId, username: userName, email: email, memberSince: date)
                            }else{
                                //Update username
                                self.db.collection(FStore.Collections.users).whereField(FStore.DataName.UID, isEqualTo: UID).getDocuments() { (querySnapshot, err) in
                                    if let err = err {
                                      // Some error occured
                                      print("ERROR: \(err.localizedDescription)")
                                    } else if querySnapshot!.documents.count != 1 {
                                      // Perhaps this is an error for you?
                                    } else {
                                        if let document = querySnapshot!.documents.first{
                                          document.reference.updateData([
                                            FStore.DataName.username: displayName
                                          ])
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    
  func registerGoogleUser(displayName: String,viewRouter:ViewRouter){
    if let emailAddress = Auth.auth().currentUser?.email {
      // Check if its sign in or up
      db.collection(FStore.Collections.users).whereField(FStore.DataName.email, isEqualTo: emailAddress).getDocuments { (querySnapshot, err) in
        if let err = err {
          print("Error getting documents: \(err)")
        } else {
          if  querySnapshot!.documents.isEmpty{
            // It's sign up
            let epoch = Int(NSDate().timeIntervalSince1970)
            let date = TimeInterval(epoch)
            
            if let emailAddress = Auth.auth().currentUser?.email {
              self.db.collection(FStore.Collections.users).addDocument(data: [FStore.DataName.username: displayName, FStore.DataName.email: emailAddress, FStore.DataName.memberSince: date]) { error in
                if let e = error {
                  print("There was an issue saving data to Firestore. \(e)")
                } else {
                  print("Success! Data sent!")
                    viewRouter.currentPage = .homePage
                }
              }
            }
          } else {
            // It's sign in
            let docId = querySnapshot!.documents[0].documentID
            let userData = querySnapshot!.documents[0].data()
            if let userName = userData[FStore.DataName.username] as? String, let date = userData[FStore.DataName.memberSince] as? Int {
              self.user = BayliqUser(id: docId, username: userName, email: emailAddress, memberSince: date)
                viewRouter.currentPage = .homePage
            }
          }
        }
      }
    }
  }
  
  func getUserData() {
    if let providerData = Auth.auth().currentUser?.providerData {
      for userInfo in providerData {
        switch userInfo.providerID {
        case "apple.com":
            print("user has signed in with apple")
        case "google.com":
          if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            // The user has either currently signed in or has previous authentication saved in keychain.
            GIDSignIn.sharedInstance.restorePreviousSignIn()
          } else {
            // Shoud go to sign in
          }
          print("user has signed in with google")
        default:
          print("unknown auth provider")
        }
      }
    }
    if let emailAddress = Auth.auth().currentUser?.email {
      db.collection(FStore.Collections.users).whereField(FStore.DataName.email, isEqualTo: emailAddress).getDocuments { (querySnapshot, err) in
        if let err = err {
          print("Error getting documents: \(err)")
          return
        } else {
          if querySnapshot!.documents.isEmpty{
            print("User is not registered in database yet!")
            return
          }
          let docId = querySnapshot!.documents[0].documentID
          let userData = querySnapshot!.documents[0].data()
          if let userName = userData[FStore.DataName.username] as? String, let date = userData[FStore.DataName.memberSince] as? Int {
            self.user = BayliqUser(id: docId, username: userName, email: emailAddress, memberSince: date)
          }
        }
      }
    }
  }
  
    //MARK: - update user's exchange list
    func SelectAllExchanges(completion: @escaping(Error?) -> Void) {
      guard let emailAddress = Auth.auth().currentUser?.email else { return }
      db.collection(FStore.Collections.users)
        .whereField(FStore.DataName.email, isEqualTo: emailAddress)
        .getDocuments { snapshot, error in
          if let err = error {
            print("error: \(err)")
            return
          }

          guard let document = snapshot?.documents.first else { return }
          document.reference.updateData([
                "unCheckedExchanges": [String]()
          ]) { error in
            if let error {
              completion(error)
              return
            }
            completion(nil)
          }
        }
    }
    
    func RemoveAllExchanges(completion: @escaping(Error?) -> Void) {
        guard let emailAddress = Auth.auth().currentUser?.email else { return }
        
        db.collection(FStore.Collections.users)
          .whereField(FStore.DataName.email, isEqualTo: emailAddress)
          .getDocuments { snapshot, error in
            if let err = error {
              print("error: \(err)")
              return
            }
              var uncheckdata = [Any]()
              for i in self.exchangeListRowdata{
                  if let c = i as? [String:String], c["name"] != "Custom Exchange"{
                      uncheckdata.append(c)
                  }
              }
            guard let document = snapshot?.documents.first else { return }
                  document.reference.updateData([
                    "unCheckedExchanges": uncheckdata
                  ]) { error in
                    if let error {
                      completion(error)
                      return
                    }
                    completion(nil)
                  }
          }
      }
    
    func uploadUncheckedExchange(exchange: CryptoExchange, completion: @escaping(Error?) -> Void) {
      guard let emailAddress = Auth.auth().currentUser?.email else { return }
      
      db.collection(FStore.Collections.users)
        .whereField(FStore.DataName.email, isEqualTo: emailAddress)
        .getDocuments { snapshot, error in
          if let err = error {
            print("error: \(err)")
            return
          }
          
          guard let document = snapshot?.documents.first else { return }
          
          let fields = [
            "iconURL": exchange.iconURL,
            "name": exchange.name,
            "websiteURL": exchange.websiteURL
          ]
          
          document.reference.updateData([
            "unCheckedExchanges": FieldValue.arrayUnion([fields])
          ]) { error in
            if let error {
              completion(error)
              return
            }
            completion(nil)
          }
          
        }
    }
    
    func removeCheckedExchange(exchange: CryptoExchange, completion: @escaping(Error?) -> Void) {
        db.collection(FStore.Collections.users).document(self.user.id).getDocument { snapshot, error in
          if let err = error {
            print("error: \(err)")
            return
          }
          guard let documents = snapshot?["unCheckedExchanges"] as? [[String:Any]] else { return }
          
          for i in documents{
            guard let id = i["name"] as? String else { return }
            if (id == exchange.name){
              snapshot?.reference.updateData([
                "unCheckedExchanges": FieldValue.arrayRemove([i])
              ]) { error in
                if let error {
                  completion(error)
                  return
                }
                completion(nil)
                return
              }
            }
          }
        }
      }
    
  // MARK: - Transaction Functions
  
  /// Uploads to `users/userID/manualTransactions` using a `ManualTransaction`.
  func uploadManualTransaction(transaction: ManualTransaction, completion: @escaping(Error?) -> Void) {
    guard let emailAddress = Auth.auth().currentUser?.email else { return }
    
    db.collection(FStore.Collections.users)
      .whereField(FStore.DataName.email, isEqualTo: emailAddress)
      .getDocuments { snapshot, error in
        if let err = error {
          print("error: \(err)")
          return
        }
        
        guard let document = snapshot?.documents.first else { return }
        
        let fields = [
          "symbol": transaction.symbol,
          "quantity": transaction.quantity,
          "notes": transaction.notes ?? "",
          "timestamp": transaction.timestamp,
          "id": transaction.id,
          "exchange": transaction.exchange ?? "",
          "marketPrice": transaction.marketPrice,
          "type": transaction.type
        ]
        
        document.reference.updateData([
          "manualTransactions": FieldValue.arrayUnion([fields])
        ]) { error in
          if let error {
            completion(error)
            return
          }
          completion(nil)
        }
        
      }
  }
  
  /// Removes a transactions from the user's list of `manualTransactions`
  func removeTransaction(transaction: ManualTransaction, completion: @escaping(Error?) -> Void) {
    db.collection(FStore.Collections.users).document(self.user.id).getDocument { snapshot, error in
      if let err = error {
        print("error: \(err)")
        return
      }
      guard let documents = snapshot?["manualTransactions"] as? [[String:Any]] else { return }
      
      for i in documents{
        guard let id = i["id"] as? String else { return }
        if (id == transaction.id){
          snapshot?.reference.updateData([
            "manualTransactions": FieldValue.arrayRemove([i])
          ]) { error in
            if let error {
              completion(error)
              return
            }
            completion(nil)
            return
          }
        }
      }
    }
  }
        //Get unchecked exchanges which needs to be removed.
    func fetchUncheckedExchanges(completion: @escaping () -> Void, notFoundCompletion: @escaping () -> Void) {
      guard let emailAddress = Auth.auth().currentUser?.email else { return }
        if (listener != nil) {
            listener.remove()
        }
       listener = db.collection(FStore.Collections.users)
        .whereField(FStore.DataName.email, isEqualTo: emailAddress)
        .addSnapshotListener({ snapshot, error in
          if let err = error {
            print("error: \(err)")
            return
          }
          if let snapshot = snapshot {
            snapshot.documentChanges.forEach({ change in
              switch change.type {
              case .added:
                guard let unCheckedExchanges = change.document.data()["unCheckedExchanges"] as? [Any] else {
                  notFoundCompletion()
                  return
                }
                
                self.unCheckedexchangesList = [CryptoExchange]()
                  for exchanges in unCheckedExchanges{
                    let trans = exchanges as? [String: Any] ?? ["" : ""]
                    let model = CryptoExchange(iconURL: trans["iconURL"] as? String ?? "", name: trans["name"] as? String ?? "", websiteURL: trans["websiteURL"] as? String ?? "")
                      self.unCheckedexchangesList.append(model)
                  }
                completion()
              case .modified:
                guard let unCheckedExchanges = change.document.data()["unCheckedExchanges"] as? [Any] else { return }
                
                  self.unCheckedexchangesList = [CryptoExchange]()
                    for exchanges in unCheckedExchanges{
                      let trans = exchanges as? [String: Any] ?? ["" : ""]
                      let model = CryptoExchange(iconURL: trans["iconURL"] as? String ?? "", name: trans["name"] as? String ?? "", websiteURL: trans["websiteURL"] as? String ?? "")
                        self.unCheckedexchangesList.append(model)
                    }
                completion()
              case .removed:
                let trans = change.document.data()
                self.unCheckedexchangesList = self.unCheckedexchangesList.filter({$0.name != trans["name"] as? String ?? ""})
              }
            })
          } else {
            notFoundCompletion()
          }
        })
    }
  
  ///  Gets all of the manual transactions in `user/USERA/manualTransactions` and stores in `self.allTransactions`
  func fetchManualTransactions(completion: @escaping () -> Void, notFoundCompletion: @escaping () -> Void) {
    guard let emailAddress = Auth.auth().currentUser?.email else { return }
      if (listener != nil) {
          listener.remove()
      }
     listener = db.collection(FStore.Collections.users)
      .whereField(FStore.DataName.email, isEqualTo: emailAddress)
      .addSnapshotListener({ snapshot, error in
        if let err = error {
          print("error: \(err)")
          return
        }
        if let snapshot = snapshot {
          snapshot.documentChanges.forEach({ change in
            switch change.type {
            case .added:
              guard let manualTransactions = change.document.data()["manualTransactions"] as? [Any] else {
                notFoundCompletion()
                return
              }
              
              self.allTransactions = [ManualTransaction]()
              for transaction in manualTransactions {
                let trans = transaction as? [String: Any] ?? ["" : ""]
                let finalTransaction = ManualTransaction(id: trans["id"] as? String ?? "", notes: trans["notes"] as? String ?? "", quantity: trans["quantity"] as? Double ?? 0.0, marketPrice: trans["marketPrice"] as? Double ?? 0.0, symbol: trans["symbol"] as? String ?? "", timestamp: trans["timestamp"] as? Int ?? 0, exchange: trans["exchange"] as? String ?? "error", type: trans["type"] as? String ?? "")
                
                self.allTransactions.append(finalTransaction)
              }
              completion()
            case .modified:
              guard let manualTransactions = change.document.data()["manualTransactions"] as? [Any] else { return }
              
              self.allTransactions = [ManualTransaction]()
              for transaction in manualTransactions {
                let trans = transaction as? [String: Any] ?? ["" : ""]
                  let finalTransaction = ManualTransaction(id: trans["id"] as? String ?? "", notes: trans["notes"] as? String ?? "", quantity: trans["quantity"] as? Double ?? 0.0, marketPrice: trans["marketPrice"] as? Double ?? 0.0, symbol: trans["symbol"] as? String ?? "", timestamp: trans["timestamp"] as? Int ?? 0, exchange: trans["exchange"] as? String ?? "", type: trans["type"] as? String ?? "")
                
                self.allTransactions = self.allTransactions.filter({$0.id != trans["id"] as? String ?? ""})
                self.allTransactions.append(finalTransaction)
              }
              completion()
            case .removed:
              let trans = change.document.data()
              self.allTransactions = self.allTransactions.filter({$0.id != trans["id"] as? String ?? ""})
            }
          })
        } else {
          notFoundCompletion()
        }
      })
  }
  
    func fetchSidemenuSupporImageurl(completion: @escaping () -> Void) {
        db.collection(FStore.Collections.config)
            .document("Support")
            .getDocument { snap, error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                } else {
                    guard let url = snap?.data()?["sideMenuImageurl"] as? String else { return }
                    self.sideMenuImageurl = url
                    completion()
                }
            }
    }
    
    func fetchSupport(completion: @escaping () -> Void) {
      db.collection(FStore.Collections.config)
        .document("Support")
        .getDocument { snap, error in
          if let error = error {
            print("Error: \(error.localizedDescription)")
          } else {
            guard let noTransactionList = snap?.data()?["CoinList"] as? [Any] else { return }
            var data = [Support]()
            for transaction in noTransactionList{
              let trans = transaction as? [String: Any] ?? ["" : ""]
              let model = Support(imageUrl: trans["imageUrl"] as? String ?? "", name: trans["name"] as? String ?? "", address: trans["address"] as? String ?? "")
              data.append(model)
            }
            self.supports = data
            completion()
          }
        }
    }
    
  func fetchNoTransactions(completion: @escaping () -> Void) {
    db.collection(FStore.Collections.config)
      .document("noTransactions")
      .getDocument { snap, error in
        if let error = error {
          print("Error: \(error.localizedDescription)")
        } else {
          guard let noTransactionList = snap?.data()?["noTransactionList"] as? [Any] else { return }
          var data = [NoTransaction]()
          for transaction in noTransactionList{
            let trans = transaction as? [String: Any] ?? ["" : ""]
            let model = NoTransaction(iconURL: trans["iconURL"] as? String ?? "", name: trans["name"] as? String ?? "", websiteURL: trans["websiteURL"] as? String ?? "")
            data.append(model)
          }
          self.noTransactions = data
          completion()
        }
      }
  }
  
  // MARK: - Exchanges
  
  /// Gets a list of all Crypto Exchanges from the `config/exchanges` collection
  func getExchanges() {
      db.collection(FStore.Collections.config)
          .document("cryptoExchanges")
          .getDocument { snap, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else {
                guard let exchangesList = snap?.data()?["exchangesList"] as? [Any] else { return }
                self.exchangeListRowdata = exchangesList
                    var data = [CryptoExchange]()
                    for exchanges in exchangesList{
                    let trans = exchanges as? [String: Any] ?? ["" : ""]
                    let model = CryptoExchange(iconURL: trans["iconURL"] as? String ?? "", name: trans["name"] as? String ?? "", websiteURL: trans["websiteURL"] as? String ?? "")
                    data.append(model)
                }
                //arrage alphabatically
                self.exchangesList = data.sorted { $0.name.lowercased().trimmingCharacters(in: .whitespaces) < $1.name.lowercased().trimmingCharacters(in: .whitespaces) }
                
                let filterExchange = self.exchangesList.filter({ $0.name.lowercased() == "Custom Exchange".lowercased() })
                if filterExchange.count > 0{
                    let indexofExhange = self.exchangesList.firstIndex(of: filterExchange.first!)
                    self.exchangesList.remove(at: indexofExhange!)
                    self.exchangesList.insert(filterExchange.first!, at: self.exchangesList.endIndex)
                }
                self.getCustomTop10()
            }
        }
  }
    //get custom top 10
    func getCustomTop10() {
        db.collection(FStore.Collections.config)
          .document("cryptoExchanges")
          .getDocument { snap, error in
            if let error = error {
              print("Error: \(error.localizedDescription)")
            } else {
              guard let currencyExchangesList = snap?.data()?["CustomTop10"] as? [String] else { return }
              self.customTop10 = currencyExchangesList
                //Arrange the exchange list based on the top 10
                for (i,j) in self.customTop10.enumerated() {
                    let filterExchange = self.exchangesList.filter({ $0.name.lowercased() == j.lowercased() })
                    if filterExchange.count > 0{
                        let indexofExhange = self.exchangesList.firstIndex(of: filterExchange.first!)
                        if indexofExhange != i {
                            self.exchangesList.remove(at: indexofExhange!)
                            self.exchangesList.insert(filterExchange.first!, at: i)
                        }
                    }
                }
            }
          }
    }
  
  func getCurrencyExchanges() {
    db.collection(FStore.Collections.config)
      .document("currencyExchangeList")
      .getDocument { snap, error in
        if let error = error {
          print("Error: \(error.localizedDescription)")
        } else {
          guard let currencyExchangesList = snap?.data()?["currencyList"] as? [String] else { return }
          self.currencyExchangeList = currencyExchangesList
        }
      }
  }
  
  // MARK: - Other Function
  
  /// Remove symbol to `/users/userID/coins`
  func removeCoinFromUserWheel(symbol: String) {
    
    if let emailAddress = Auth.auth().currentUser?.email {
      
      db.collection(FStore.Collections.users)
        .whereField(FStore.DataName.email, isEqualTo: emailAddress)
        .getDocuments { snapshot, error in
          if let err = error {
            print("error: \(err)")
            return
          }
          
          guard let document = snapshot?.documents.first else { return }
          
          document.reference.updateData([
            "coins": FieldValue.arrayRemove([symbol.uppercased()])
          ]) { error in
            if let error {
              print("error: \(error)")
              return
            }
            print("Success")
          }
          
        }
    }
  }
  
  /// Get's the coin icon URL for a coin
  func getCoinIconURL(symbol: String, completion: @escaping(Error?, String?) -> Void) {
    db.collection(FStore.Collections.coins)
      .document(symbol)
      .getDocument { snapshot, error in
        if let error {
          print("Error: \(error)")
          completion(error, nil)
        }
        
        guard let url = snapshot?.data()?["iconURL"] as? String else { return }
        completion(nil, url)
      }
  }
  
  func getWalkthrough() {
    db.collection(FStore.Collections.coins)
      .document("walkthroughVideo")
      .getDocument { snap, error in
        if let error = error {
          print("Error: \(error.localizedDescription)")
        } else {
          guard let url = snap?.data()?["videoURL"] as? String else { return }
          self.walkthroughURL = url
        }
      }
  }
  
}
