//
//  SideMenuView.swift
//  Bayliq
//
//  Created by David Razmadze on 10/23/22.
//

import SwiftUI
import Firebase
import CachedAsyncImage

// MARK: - MenuItem

struct MenuItem: Identifiable {
  var id = UUID()
  var name: String
  var imageName: String
}

// MARK: - SideMenu

struct SideMenuView: View {
  
  // MARK: - Variables
  @Binding var showSettingsView: Bool
  @Binding var showTransactionView: Bool
    
    @EnvironmentObject var firestore : FirestoreManager
  let width: CGFloat
  
  // MARK: - Body
  
  var body: some View {
    ZStack(alignment: .leading){
      Color("background").ignoresSafeArea()
      VStack {
          MenuContent(showSettingsView: $showSettingsView, showTransactionView: $showTransactionView).environmentObject(firestore)
      }
    }.transition(.asymmetric(insertion: .slide, removal: .move(edge: .leading)))
      .frame(width: width)
  }
  
}

// MARK: - MenuContent

struct MenuContent: View {
  
  // MARK: - Variables
    @EnvironmentObject var firestore : FirestoreManager
  @EnvironmentObject var viewRouter: ViewRouter
  @Binding var showSettingsView: Bool
  @Binding var showTransactionView: Bool
  @State var signOutProcessing = false
  @State var showWalkthrough = false
    @State var showContactUs = false
    @State var showSupportUs = false
    @State var showInviteUser = false
    @State var supportImageUrl = ""
  @State private var isSharePresented: Bool = false
  let link = URL(string: "https://www.hackingwithswift.com")!
  
  let items: [MenuItem] = [
    MenuItem(name: "Settings", imageName: "gearshape"),
    MenuItem(name: "Transactions", imageName: "list.bullet.rectangle.portrait"),
    MenuItem(name: "Website", imageName: "questionmark.circle"),
    MenuItem(name: "Walkthrough", imageName: "play.rectangle.fill"),
    MenuItem(name: "YouTube", imageName: "video"),
    MenuItem(name: "Share", imageName: "square.and.arrow.up"),
    MenuItem(name: "Invite friends", imageName: "person.crop.circle.badge.plus"),
    MenuItem(name: "Contact", imageName: "envelope"),
    MenuItem(name: "Coinbase", imageName: "bitcoinsign.circle")
  ]
  
  // MARK: - Body
  
  var body: some View {
    ZStack {
      Color("background")
        VStack{
            VStack(alignment: .leading, spacing: 0){
                ForEach(items) { item in
                    Button {
                        if item.name == "Settings" {
                            showSettingsView = true
                            showTransactionView = false
                        } else if item.name == "Transactions" {
                            showTransactionView = true
                            showSettingsView = false
                        } else if item.name == "Walkthrough" {
                            showWalkthrough = true
                        } else if item.name == "Website" {
                            if let url = URL(string: "https://bayliq.com") {
                                UIApplication.shared.open(url)
                            }
                        } else if item.name == "Share" {
                            isSharePresented = true
                        } else if item.name == "YouTube" {
                            if let url = URL(string: "https://www.youtube.com/@bayliq") {
                                UIApplication.shared.open(url)
                            }
                        } else if item.name == "Coinbase" {
                            if let url = URL(string: "https://commerce.coinbase.com/checkout/2ca7684c-ec7b-4864-95d5-8ff587f93b7a") {
                                UIApplication.shared.open(url)
                            }
                        } else if item.name == "Contact" {
                            showContactUs = true
                        }else if item.name == "Invite friends" {
                            showInviteUser = true
                        }
                    } label: {
                        HStack{
                            Image(systemName: item.imageName).foregroundColor(Color.white)
                            Text(item.name)
                                .bold()
                                .font(.system(size: 20))
                                .foregroundColor(Color.white)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }.padding()
                    }.buttonStyle(.plain)
                    Divider()
                }
            }
        Spacer()
        VStack(alignment: .center, content: {
            if supportImageUrl != "" {
                CachedAsyncImage(url: URL(string: supportImageUrl), urlCache: .imageCache) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image.resizable()
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100,height: 100)
                    case .failure:
                        Image(systemName: "BTCAddress")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100,height: 100)
                    @unknown default:
                        EmptyView()
                    }
                }
            }else{
                ProgressView()
            }
//            Image("BTCAddress")
//              .resizable()
//              .scaledToFill()
//              .frame(width: 100,height: 100)
          
            Text("Support us")
                .bold()
                .font(.system(size: 20))
                .foregroundColor(Color.white)
                .multilineTextAlignment(.leading)
                .padding(.bottom,5)
        })
        .onTapGesture {
            showSupportUs = true
        }
      }
    }
    .onAppear{
        self.firestore.fetchSidemenuSupporImageurl {
            supportImageUrl = self.firestore.sideMenuImageurl
        }
    }
    .fullScreenCover(isPresented: $showWalkthrough) {
        WalkthroughView(manager: self.firestore)
    }
    .sheet(isPresented: $isSharePresented, onDismiss: {
      print("Dismiss")
    }, content: {
      ActivityViewController(activityItems: [URL(string: "https://apps.apple.com/us/app/bayliq/id6443639629?uo=2")!])
    })
    .fullScreenCover(isPresented: $showContactUs, content: {
        ContactUs( isfromNewExchange: false)
    })
    .fullScreenCover(isPresented: $showSupportUs, content: {
        SupportUs(manager: self.firestore)
    })
    .fullScreenCover(isPresented: $showInviteUser, content: {
        InviteUser(manager: self.firestore)
    })
  }
  
  // MARK: - Helper Functions
  
  func signOutUser() {
    signOutProcessing = true
    let firebaseAuth = Auth.auth()
    do {
      try firebaseAuth.signOut()
    } catch let signOutError as NSError {
      print("Error signing out: %@", signOutError)
      signOutProcessing = false
    }
    withAnimation {
      viewRouter.currentPage = .signInPage
    }
  }
  
}
