//
//  PhotoPickerModel.swift
//  VideoEditor
//
//  Created by Atikul Gazi on 6/10/22.
//

import SwiftUI
import Photos

struct PhotoPickerModel {
    enum MediaType {
        case photo, video
    }
    
    var id: String
    var photo: UIImage?
    var url: URL?
    var mediaType: MediaType = .photo
    
    init(with photo: UIImage) {
        id = UUID().uuidString
        self.photo = photo
        mediaType = .photo
    }
    
    init(with videoURL: URL) {
        id = UUID().uuidString
        url = videoURL
        mediaType = .video
    }
    
    mutating func delete() {
        switch mediaType {
        case .photo: photo = nil
        case .video:
            guard let url = url else { return }
            try? FileManager.default.removeItem(at: url)
            self.url = nil
        }
    }
}
