//
//  ContactUs.swift
//  Bayliq
//
//  Created by Bhavesh Patel on 06/06/23.
//

import SwiftUI
import MessageUI

struct ContactUs: View {
    init(isfromNewExchange: Bool) {
        self.isfromNewExchange = isfromNewExchange
        UITextView.appearance().backgroundColor = .clear
    }
    @Environment(\.presentationMode) var presentationMode
    @State private var result: Result<MFMailComposeResult, Error>? = nil
    @State private var showAlertView = false
    @State private var ExchangeName = ""
    @State private var ExchangeWebSite = ""
    @State private var ContactEmail = ""
    @State private var Notes = ""

    @State var subject = ""
    @State var message = ""
    var isfromNewExchange : Bool
    var body: some View {
        NavigationView {
            ScrollView{
                ZStack(alignment: .leading){
                    // Background Color
                    Color("background").ignoresSafeArea(edges: .all)
                    VStack {
                        // Name
                        TextField("", text: $ExchangeName).disableAutocorrection(true).autocapitalization(.none).padding().foregroundColor(.white)
                            .keyboardType(.default)
                            .placeholder(when: ExchangeName.isEmpty) {
                                Text(isfromNewExchange ? "Name Exchanges *": "Full name").foregroundColor(Color.white).offset(x: 15, y: 0)
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 12).stroke(Color("loginFields"), lineWidth: 2)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 5)
                            .padding(.top, 10)
                        
                        // WebSites
                        TextField("", text: $ExchangeWebSite).disableAutocorrection(true).autocapitalization(.none).padding().foregroundColor(.white)
                            .keyboardType(.default)
                            .placeholder(when: ExchangeWebSite.isEmpty) {
                                Text(isfromNewExchange ? "Official website *" : "Email").foregroundColor(Color.white).offset(x: 15, y: 0)
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 12).stroke(Color("loginFields"), lineWidth: 2)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 5)
                        
                        // Email
                        TextField("", text: $ContactEmail).disableAutocorrection(true).autocapitalization(.none).padding().foregroundColor(.white)
                            .keyboardType(.default)
                            .placeholder(when: ContactEmail.isEmpty) {
                                Text(isfromNewExchange ? "Contact name /email" : "Subject").foregroundColor(Color.white).offset(x: 15, y: 0)
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 12).stroke(Color("loginFields"), lineWidth: 2)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 5)
                        
                        // Notes
                        //Place holder
                        HStack{
                            Text(isfromNewExchange ? "   Notes: " : "   Additional Details:")
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                        //Text field
                        ZStack{
                            TextEditor(text: $Notes)
                                .textSelection(.enabled)
                                .disableAutocorrection(true)
                                .autocapitalization(.none).padding()
                                .keyboardType(.default)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12).stroke(Color("loginFields"), lineWidth: 2)
                                }
                            //                            .scrollContentBackground(.hidden)
                                .background(.clear)
                                .padding(.horizontal)
                                .padding(.bottom, 5)
                                .ignoresSafeArea(.keyboard, edges: .bottom)
                                .frame(height: 250)
                        }
                        Button(action: {
                            submitButtonTapped()
                        }, label: {
                            Text("Next")
                                .foregroundColor(Color.white)
                                .frame(width: UIScreen.main.bounds.width, height: 50)
                                .padding(.horizontal, -18)
                            
                                .background(Color("orange"))
                                .font(.system(size: 20, weight: .bold))
                        })
                        .cornerRadius(12)
                    }
                    .padding(.bottom,15)
                    Spacer()
                }
            }
            .background(Color("background"))
            .onAppear{
                UITextView.appearance().backgroundColor = .clear
            }
            .onTapGesture {
              self.hideKeyboard()
            }
            .navigationTitle(isfromNewExchange ? "Request new exchange":"Contact Us")
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
        .alert("Please fill in all fields", isPresented: $showAlertView, actions: {
          Button("Okay") {
            self.showAlertView = false
          }
        }, message: {
          Text("")
        })
    }
    
    func submitButtonTapped(){
        self.subject = ""
        self.message = ""
        if isfromNewExchange {
            
            if self.ExchangeName == "" || self.ExchangeWebSite == "" {
                self.showAlertView = true
                return
            }
            self.subject = "New Exchange Request"
            if self.ContactEmail != ""{
                subject = subject + " from \(self.$ContactEmail.wrappedValue)"
            }
            self.message = "Exchange name: \(self.$ExchangeName.wrappedValue)\n\nOfficail website: \(self.$ExchangeWebSite.wrappedValue)\n\nNotes: \n   \(self.$Notes.wrappedValue)"
        }else{
            
            if self.ExchangeName == "" || self.ExchangeWebSite == "", self.ContactEmail == "" || self.Notes  == "" {
                self.showAlertView = true
                return
            }
            self.subject = "\($ContactEmail.wrappedValue)"
            if self.ExchangeName != ""{
                subject = subject + " from \(self.$ExchangeName.wrappedValue)"
            }
            
            self.message = "Email: \(self.$ExchangeWebSite.wrappedValue)\n \n Details:\n \($Notes.wrappedValue)"
        }
        if MFMailComposeViewController.canSendMail() {
            if subject != "" || message != "" {
                EmailHelper.shared.sendEmail(subject: $subject.wrappedValue, body: $message.wrappedValue, to: "contact@bayliq.com")
                self.subject = ""
                self.message = ""
                self.ExchangeName = ""
                self.ExchangeWebSite = ""
                self.ContactEmail = ""
                self.Notes = ""
            }
        } else {
            print("Can't send emails from this device")
        }
        if result != nil {
            print("Result: \(String(describing: result))")
        }
    }
}

struct ContactUs_Previews: PreviewProvider {
    static var previews: some View {
        ContactUs( isfromNewExchange: false)
    }
}
