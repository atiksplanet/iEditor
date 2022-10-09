//
//  PhotoMergerView.swift
//  VideoEditor
//
//  Created by Atikul Gazi on 6/10/22.
//

import AVKit
import SwiftUI

struct PhotoMergerView: View {
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    @State private var showPopUp = false
    @State private var loading = false
    
    @ObservedObject var mediaItems: PickedMediaItems
    @ObservedObject var videoItems = PickedMediaItems()
    
    var body: some View {
        VStack {
            List(videoItems.items, id: \.id) { item in
                ZStack(alignment: .topLeading) {
                    if let url = item.url {
                        VideoPlayer(player: AVPlayer(url: url))
                            .frame(minHeight: 200)
                    } else { EmptyView() }
                    
                    Image(systemName: "video")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .padding(4)
                        .background(Color.black.opacity(0.5))
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear() {
            let imageItems = mediaItems.items.filter({ $0.mediaType == .photo })
            let videoItems = mediaItems.items.filter({ $0.mediaType == .video })
            videoItems.forEach { item in
                self.videoItems.append(item: item)
            }
            showPopUp = imageItems.count < 2 || videoItems.count < 2
            if !showPopUp {
                loading = true
                let images = imageItems.compactMap({ $0.photo })
                VideoGenerator.current.generate(withImages: images) { progress in
                    if progress.isFinished {
                        loading = false
                    }
                } outcome: { result in
                    switch result {
                    case .success(let url):
                        print("Success to create video")
                        let newItem = PhotoPickerModel(with: url)
                        self.videoItems.items.insert(newItem, at: 0)
                    case .failure(let error):
                        print("Failed to create video: \(error)")
                    }
                }

            }
        }
        .onDisappear() {
            videoItems.items.removeAll()
        }
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
                ActivityIndicator(isAnimating: loading)
                    .configure { $0.color = .systemMint }
                    .padding()
                    //.background(Color.blue)
                    //.cornerRadius(100)
            }
        })
        .confirmationDialog(
            "Back to Dashboard",
            isPresented: $showPopUp
        ) {
            Button("Back", role: .destructive) {
                // Handle empty trash action.
                self.mode.wrappedValue.dismiss()
            }
        } message: {
            Text("Not enough images to perform the operation, Better go back to Dashboard & select more images")
        }
    }
}
