//
//  InviteUser.swift
//  Bayliq
//
//  Created by Bhavesh Patel on 10/06/23.
//

import SwiftUI
import Contacts
import MessageUI

struct InviteUser: View {
    @State private var contacts: [CNContact] = []
    @State private var FilteredContacts: [CNContact] = []
    @State private var selectedContact: [CNContact] = []
    @ObservedObject var manager: FirestoreManager
    @Environment(\.presentationMode) var presentationMode
    @State var searchText = ""
    @State var recipients = [String]()
    @State private var isShowingMessageView = false
    
    @StateObject private var messageComposer = MessageComposer()
    var body: some View {
        NavigationView {
            ZStack(alignment: .leading){
                // Background Color
                Color("background").ignoresSafeArea(edges: .all)
                ScrollView{
                    VStack{
                        Text("Invite friends on Bayliq tracker, you can create the first investment portfolio.")
                            .padding(.leading,10)
                            .padding(.top,10)
                            .foregroundColor(Color.white)
                        
                        HStack{
                            SearchBarView(searchText: $searchText,placeHolder: "Search by name...")
                            Spacer()
                            Text(selectedContact.count != contacts.count ? "Select All" : "Unselect all")
                                .padding(.leading,10)
                                .padding(.top,10)
                                .bold()
                                .foregroundColor(Color.white)
                                .padding()
                                .onTapGesture {
                                    if self.selectedContact.count == contacts.count {
                                        self.selectedContact.removeAll()
                                    }else{
                                        self.selectedContact = contacts
                                    }
                                }
                        }
                    }
                    VStack(alignment:.leading){
                        ForEach(FilteredContacts.count > 0 ? FilteredContacts : contacts, id: \.self, content: { contact in
                            HStack{
                                VStack(alignment: .leading) {
                                    Text("\(contact.givenName) \(contact.familyName)")
                                        .font(.headline)
                                        .foregroundColor(Color.white)
                                    if let phoneNumber = contact.phoneNumbers.first?.value {
                                        Text(phoneNumber.stringValue)
                                            .font(.subheadline)
                                            .foregroundColor(Color.white)
                                    }
                                }
                                .padding(.leading, 10)
                                .padding(.top, 5)
                                .padding(.bottom, 5)
                                //.background(Color("background"))
                               
                                Spacer()
                                Button(action: {
                                    // Action when the button is tapped
                                    sendInvitation(number: (contact.phoneNumbers[0].value).value(forKey: "digits") as! String)
                                }) {
                                    Text("Invite")
                                        .frame(width: 100,height: 40)
                                        .foregroundColor(.white)
                                        .background(Color.blue)
                                        .cornerRadius(20)
                                }
                                .padding()
                                
                            }
                            .onTapGesture(perform: {
                                if (selectedContact.contains(contact)){
                                    selectedContact.removeAll { fltercontact in
                                        if ((contact.phoneNumbers[0].value).value(forKey: "digits") as! String) == ((fltercontact.phoneNumbers[0].value).value(forKey: "digits") as! String) {
                                            return true
                                        }else{
                                            return false
                                        }
                                    }
                                }else{
                                    selectedContact.append(contact)
                                }
                            })
                            .background((selectedContact.contains(contact)) ? Color.gray.opacity(0.2) : Color.clear)
                            Divider()
                                .foregroundColor(.white)
                        })
                    }
                    .padding(.top,10)
                    .padding(.bottom,100)
                }
                VStack{
                    Spacer()
                    HStack{
                        Spacer()
                        if selectedContact.count > 0 {
                            FloatingButton {
                                recipients.removeAll()
                                for i in selectedContact {
                                    recipients.append((i.phoneNumbers[0].value).value(forKey: "digits") as! String)
                                }
                                //isShowingMessageView = true
                                messageComposer.recipients = recipients
                                messageComposer.send {
                                    // Completion handler called when message view is dismissed
                                    print("Message view dismissed")
                                }
                            } content: {
                                Image(systemName: "paperplane.circle")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $messageComposer.isShowingMessageView) {
                if recipients.count > 0 {
                    MessageView(messageComposer: messageComposer)
                        .onDisappear {
                            messageComposer.isShowingMessageView = false
                        }
                }
            }
            .onAppear {
                fetchContacts()
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    if let isInviteFriendShowed = UserDefaults.standard.value(forKey: "isInviteFriendShowed") as? Bool{
                        if let ShowInviteFriends = UserDefaults.standard.value(forKey: "ShowInviteFriends") as? Bool{
                            if ShowInviteFriends == false {
                                if isInviteFriendShowed == true {
                                    UserDefaults.standard.setValue(false, forKey: "ShowInviteFriends")
                                }
                            }
                        }
                    }
                }
            }
            .onChange(of: self.searchText) { newValue in
                if searchText != "" {
                    FilteredContacts = contacts.filter{ ($0.givenName.lowercased().range(of:self.searchText.lowercased()) != nil) || ($0.familyName.lowercased().range(of:self.searchText.lowercased()) != nil)  }
                }else{
                    FilteredContacts.removeAll()
                }
            }
            
            .navigationTitle("Invite friends")
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
    
    func sendInvitation(number:String) {
          let sms = "sms:\(number)&body=All-in-One crypto investment private tracker\nBayliq integrates your holdings from crypto exchanges ‘cold wallets’ and cash in a single safe and secure mobile application without collecting your personal data\n✅ No Risk\n✅ Real-Time Data\n✅ Free to Download\n✅ No Account Needed\n✅ Cryptocurrency 2000+\n✅ Crypto-exchanges 100+\n\nhttps://apps.apple.com/us/app/bayliq/id6443639629"
        if  let strurl = sms.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            UIApplication.shared.open(URL.init(string: strurl)!,options: [:],completionHandler: nil)
        }
      }
    
    func fetchContacts() {
        let store = CNContactStore()
        
        store.requestAccess(for: .contacts) { granted, error in
            if granted {
                let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
                let request = CNContactFetchRequest(keysToFetch: keys)
              //  DispatchQueue.main.async {
                    do {
                        try store.enumerateContacts(with: request) { contact, _ in
                            if contact.phoneNumbers.count != 0 && (contact.givenName != "" || contact.familyName != ""){
                                contacts.append(contact)
                            }
                        }
                    } catch {
                        print("Error fetching contacts: \(error)")
                    }
               // }
            } else {
                print("Access to contacts denied")
            }
        }
    }
}

struct InviteUser_Previews: PreviewProvider {
    static var previews: some View {
        InviteUser(manager: FirestoreManager())
    }
}

struct MessagesUnavailableView: View {
    var body: some View {
        VStack {
            Image(systemName: "xmark.octagon")
                .font(.system(size: 64))
                .foregroundColor(.red)
            Text("Messages is unavailable")
                .font(.system(size: 24))
        }
    }
}
struct FloatingButton<Content: View>: View {
    let action: () -> Void
    let content: Content
    
    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: action) {
            content
        }
        .frame(width: 60, height: 60)
        .background(Color.blue)
        .foregroundColor(.white)
        .clipShape(Circle())
        .shadow(color: .gray, radius: 3, x: 0, y: 2)
        .padding()
    }
}

struct MessageView: UIViewControllerRepresentable {
    let messageComposer: MessageComposer
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let messageComposeVC = MFMessageComposeViewController()
        messageComposeVC.recipients = messageComposer.recipients
        messageComposeVC.messageComposeDelegate = messageComposer
        messageComposeVC.body = "All-in-One crypto investment private tracker\nBayliq integrates your holdings from crypto exchanges ‘cold wallets’ and cash in a single safe and secure mobile application without collecting your personal data\n✅ No Risk\n✅ Real-Time Data\n✅ Free to Download\n✅ No Account Needed\n✅ Cryptocurrency 2000+\n✅ Crypto-exchanges 100+\n\nhttps://apps.apple.com/us/app/bayliq/id6443639629"
        return messageComposeVC
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {
        // No need to update the view controller
    }
}

class MessageComposer: NSObject, ObservableObject, MFMessageComposeViewControllerDelegate {
    @Published var isShowingMessageView = false
    var recipients: [String] = []
    private var didFinishMessageComposer: (() -> Void)?
    
    func send(completion: @escaping () -> Void) {
        guard MFMessageComposeViewController.canSendText() else {
            // Handle the case where the device cannot send messages
            return
        }
        
        let messageComposeVC = MFMessageComposeViewController()
        messageComposeVC.recipients = recipients
        messageComposeVC.messageComposeDelegate = self
        messageComposeVC.body = "All-in-One crypto investment private tracker\nBayliq integrates your holdings from crypto exchanges ‘cold wallets’ and cash in a single safe and secure mobile application without collecting your personal data\n✅ No Risk\n✅ Real-Time Data\n✅ Free to Download\n✅ No Account Needed\n✅ Cryptocurrency 2000+\n✅ Crypto-exchanges 100+\n\nhttps://apps.apple.com/us/app/bayliq/id6443639629"
        
        didFinishMessageComposer = completion
        DispatchQueue.main.async {
            self.isShowingMessageView = true
        }
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        DispatchQueue.main.async {
            self.isShowingMessageView = false
            self.didFinishMessageComposer?()
        }
    }
}
