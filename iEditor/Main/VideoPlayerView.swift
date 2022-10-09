//
//  VideoPlayerView.swift
//  iEditor
//
//  Created by Atik on 10/10/22.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @State var finalMoviePath: URL?
    
    var body: some View {
        if let url = finalMoviePath {
            VideoPlayer(player: AVPlayer(url: url))
        } else {
            Text("Error to merge videos")
        }
    }
}

struct VideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        VideoPlayerView()
    }
}
