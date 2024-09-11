//
//  SupportUs.swift
//  Bayliq
//
//  Created by Bhavesh Patel on 08/06/23.
//

import SwiftUI
import CachedAsyncImage
import UniformTypeIdentifiers

struct SupportUs: View {
    @ObservedObject var manager: FirestoreManager
    @Environment(\.presentationMode) var presentationMode
    @State var supports = [Support]()
    @State var isAddressCopied = false
    @State var copiedAddress = ""
    var body: some View {
        NavigationView {
            ZStack(alignment: .leading){
                // Background Color
                Color("background").ignoresSafeArea(edges: .all)
                ScrollView(){
                    VStack{
                        Text("Our vision is to make cryptocurrency accessible to anyone and everyone.")
                            .padding(.leading,10)
                            .padding(.top,10)
                            .foregroundColor(Color.white)
                    }
                    
                    if supports.count == 0 {
                        VStack{
                            ProgressView()
                                .padding()
                            Text("Loading...")
                                .bold()
                                .font(.system(size: 14))
                                .foregroundColor(Color.white)
                                .multilineTextAlignment(.leading)
                        }
                    }else{
                        ForEach(supports) { support in
                            HStack{
                                VStack(alignment: .leading){
                                    CachedAsyncImage(url: URL(string: support.imageUrl), urlCache: .imageCache) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                        case .success(let image):
                                            image.resizable()
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 200,height: 200)
                                        case .failure:
                                            Image(systemName: "photo")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 200,height: 200)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    HStack{
                                        VStack{
                                            HStack {
                                                Text(support.name)
                                                    .bold()
                                                    .font(.system(size: 14))
                                                    .foregroundColor(Color.white)
                                                    .multilineTextAlignment(.leading)
                                                Text("address")
                                                    .bold()
                                                    .font(.system(size: 14))
                                                    .foregroundColor(Color.white)
                                                    .multilineTextAlignment(.leading)
                                                Spacer()
                                            }
                                            HStack{
                                                Text(support.address)
                                                    .bold()
                                                    .font(.system(size: 14))
                                                    .foregroundColor(Color.white)
                                                    .multilineTextAlignment(.leading)
                                                    .padding(.bottom,1)
                                                    .padding(.bottom,5)
                                                Spacer()
                                            }
                                            Spacer()
                                        }
                                        
                                        Button {
                                            UIPasteboard.general.setValue(support.address,
                                                    forPasteboardType: UTType.plainText.identifier)
                                            copiedAddress = support.address
                                            isAddressCopied = true
                                        } label: {
                                            VStack{
                                                Image(systemName: "doc.on.doc")
                                                    .foregroundColor(Color.white)
                                                if isAddressCopied == true && copiedAddress == support.address {
                                                    Text("Copied ✅")
                                                        .foregroundColor(.white)
                                                        .font(.system(size: 15))
                                                        .onAppear{
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                                self.isAddressCopied.toggle()
                                                            }
                                                        }
                                                }
                                            }
                                            .frame(width: 80, height: 50)
                                        }
                                    }
                                    
                                }
                                .padding(.leading,25)
                                Spacer()
                            }
                            .onTapGesture(count: 2) {
                                UIPasteboard.general.setValue(support.address,
                                        forPasteboardType: UTType.plainText.identifier)
                                copiedAddress = support.address
                                isAddressCopied = true
                            }
                            Divider()
                                .foregroundColor(.white)

                        }
                    }
                }
            }
            .background(Color("background"))
            .navigationTitle("Support Bayliq")
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
        .onAppear{
            self.manager.fetchSupport {
                self.supports = self.manager.supports
            }
        }
    }
}

struct SupportUs_Previews: PreviewProvider {
    static var previews: some View {
        SupportUs(manager: FirestoreManager())
    }
}
