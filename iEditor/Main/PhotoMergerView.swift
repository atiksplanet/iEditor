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
            .font(.title)
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
                doMergePhotos(images, filter: "CISepiaTone")
            }
        }
        .onDisappear() {
            videoItems.items.removeAll()
        }
        .toolbar(content: {
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
    func doMergePhotos(_ images: [UIImage], filter: String = "CISepiaTone") {
        loading = true
        VideoGenerator.current.generate(withImages: images) { progress in
            if progress.isFinished {
                loading = false
            }
        } outcome: { result in
            switch result {
            case .success(let url):
                loading = true
                print("Success to create video")
                let asset = AVAsset(url: url)
                VideoGenerator.current.ApplyFilter(video: asset, filter: filter) { url, error in
                    loading = false
                    guard let url = url else {
                        return
                    }
                    let newItem = PhotoPickerModel(with: url)
                    self.videoItems.items.insert(newItem, at: 0)
                }
            case .failure(let error):
                print("Failed to create video: \(error)")
            }
        }
    }
    
    func doMerge(_ urls: [URL]) {
        guard loading == false else {
            return
        }
        
        loading.toggle()
        let assets = urls.map({ AVAsset(url: $0) })
        VideoGenerator.current.mergeWithAnimation(arrayVideos: assets) { newUrl, error in
            guard let url = newUrl else {
                //print("Failed to create video: \(String(describing: error))")
                loading.toggle()
                PhotoMergerView.finalMoviePath = nil
                showVideoPlayer.toggle()
                return
            }
            addTextWithFrame(url: url, appName: "Hello Appnap")
        }
    }
    
    func addTextWithFrame(url: URL, appName: String) {
        VideoGenerator.current.addTextWithFrame(videoURL: url, name: appName) { riskUrl in
            loading.toggle()
            if let goodUrl = riskUrl {
                PhotoMergerView.finalMoviePath = goodUrl
            } else {
                PhotoMergerView.finalMoviePath = nil
            }
            showVideoPlayer.toggle()
        }
    }
}
