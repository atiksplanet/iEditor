//
//  DashboardView.swift
//  VideoEditor
//
//  Created by Atik on 6/10/22.
//

import AVKit
import SwiftUI

struct DashboardView: View {
    @State private var showPicker = false
    @State private var showPopUp = false
    
    @ObservedObject var mediaItems = PickedMediaItems()
    
    var body: some View {
        NavigationView {
            VStack(content: {
                List(mediaItems.items, id: \.id) { item in
                    ZStack(alignment: .topLeading) {
                        if item.mediaType == .photo {
                            Image(uiImage: item.photo ?? UIImage())
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } else if item.mediaType == .video {
                            if let url = item.url {
                                VideoPlayer(player: AVPlayer(url: url))
                                    .frame(minHeight: 200)
                            } else { EmptyView() }
                        }
                        
                        Image(systemName: getMediaImageName(using: item))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .padding(4)
                            .background(Color.black.opacity(0.5))
                            .foregroundColor(.red)
                    }
                }
                
                NavigationLink {
                    PhotoMergerView(mediaItems: mediaItems)
                } label: {
                    Text("Merge Photos")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .font(.largeTitle)
                .padding([.leading, .trailing], 10)
            })
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showPicker = true
                    } label: {
                        Image(systemName: "plus.rectangle.fill.on.rectangle.fill")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showPopUp = true
                    } label: {
                        Image(systemName: "trash.fill")
                    }
                }
            })
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.automatic)
        }
        .sheet(isPresented: $showPicker) {
            MediaPicker(mediaItems: mediaItems) { didSelectItem in
                // Handle didSelectItems value here...
                showPicker = false
                print(mediaItems.items.count)
            }
        }
        .confirmationDialog(
            "Permanently erase the items in the View?",
            isPresented: $showPopUp
        ) {
            Button("Empty Trash", role: .destructive) {
                // Handle empty trash action.
                mediaItems.deleteAll()
            }
        } message: {
            Text("Permanently erase the items in the View?. \nYou cannot undo this action.")
        }
    }
    
    fileprivate func getMediaImageName(using item: PhotoPickerModel) -> String {
        switch item.mediaType {
        case .photo: return "photo"
        case .video: return "video"
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
