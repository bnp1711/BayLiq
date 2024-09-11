//
//  WalkthroughView.swift
//  Bayliq
//
//  Created by Natanael Jop on 24/11/2022.
//

import Combine
import SwiftUI
import AVKit

struct WalkthroughView: View {
  
  // MARK: - Variables
  
  @ObservedObject var manager: FirestoreManager
  @Environment(\.dismiss) var dismiss
    @EnvironmentObject var networkMonitor: NetworkMonitor
  @State var isVideoPlayed = false
    @State var player = AVPlayer(url: Bundle.main.url(forResource: "walkthrough_video1", withExtension: "MOV")!)
    @State private var showNetworkAlert = false
    
  let playerDidFinishNotification = NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
  // MARK: - Body
  
  var body: some View {
      ZStack{
          VideoPlayer(player: player)
              .edgesIgnoringSafeArea(.all)
              .onAppear {
                  player.play()
              }
              .ignoresSafeArea()
              .onReceive(playerDidFinishNotification, perform: { _ in
                  isVideoPlayed = true
                  if isVideoPlayed {
                      dismiss()
                  }
              })
          VStack{
              Spacer()
              HStack{
                  Spacer()
                  Button {
                      isVideoPlayed = true
                      dismiss()
                  } label: {
                      Text("Skip Intro")
                          .bold()
                  }
                  .foregroundColor(.white)
                  .frame(width: 90)
                  .background(Color.clear)
                  .padding()
                  .overlay(
                    RoundedRectangle(cornerRadius: 120)
                        .stroke(Color.white, lineWidth: 2)
                  )
              }
              .padding(.bottom,60)
              .padding(.trailing)
          }
          
      }
  }
        
  
}

struct WalkthroughView_Previews: PreviewProvider {
  static var previews: some View {
      WalkthroughView(manager: FirestoreManager())
  }
}
