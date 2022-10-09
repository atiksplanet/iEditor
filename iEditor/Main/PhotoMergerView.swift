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
    @State private var showDialog = false
    
    @State private var showVideoPlayer = false
    
    @ObservedObject var mediaItems: PickedMediaItems
    @ObservedObject var videoItems = PickedMediaItems()
    static private var finalMoviePath: URL? = nil
    
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
            
            Button {
                if PhotoMergerView.finalMoviePath == nil {
                    let urls = videoItems.items.compactMap({ $0.url })
                    doMerge(urls)
                } else {
                    showVideoPlayer.toggle()
                }
            } label: {
                Text(PhotoMergerView.finalMoviePath != nil ? "Play Result" : "Merge Videos")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .font(.largeTitle)
            .padding([.leading, .trailing], 10)
        }
        .onAppear() {
            PhotoMergerView.finalMoviePath = nil
            let imageItems = mediaItems.items.filter({ $0.mediaType == .photo })
            let videoItems = mediaItems.items.filter({ $0.mediaType == .video })
            videoItems.forEach { item in
                self.videoItems.append(item: item)
            }
            showPopUp = imageItems.count < 2 || videoItems.count < 2
            if !showPopUp {
                let images = imageItems.compactMap({ $0.photo })
                doMergePhotos(images)
            }
        }
        .onDisappear() {
            videoItems.items.removeAll()
        }
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Apply Filter") {
                    let urls = videoItems.items.compactMap({ $0.url })
                    applyFilter(urls)
                }
                .buttonStyle(.bordered)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                ActivityIndicator(isAnimating: loading)
                    .configure { $0.color = .systemMint }
            }
        })
        .alert(
            Text("Back to Dashboard"),
            isPresented: $showPopUp
        ) {
            Button("Back") {
                self.mode.wrappedValue.dismiss()
            }
        } message: {
            Text("Not enough images to perform the operation, Better go back to Dashboard & select more images")
        }
        .sheet(isPresented: $showVideoPlayer) {
            VideoPlayerView(finalMoviePath: PhotoMergerView.finalMoviePath)
        }
    }
}

fileprivate extension PhotoMergerView {
    func applyFilter(_ urls: [URL]) {
        
    }
    
    func doMergePhotos(_ images: [UIImage]) {
        loading = true
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
    
    func doMerge(_ urls: [URL]) {
        loading.toggle()
        VideoGenerator.mergeMovies(videoURLs: urls) { result in
            loading.toggle()
            switch result {
            case .success(let success):
                //print("Success to create video: \(success)")
                PhotoMergerView.finalMoviePath = success
                showVideoPlayer.toggle()
            case .failure(let failure):
                print("Failed to create video: \(failure)")
                PhotoMergerView.finalMoviePath = nil
                showVideoPlayer.toggle()
            }
        }
    }
}
