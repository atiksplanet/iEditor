//
//  MediaPicker.swift
//  VideoEditor
//
//  Created by Atikul Gazi on 6/10/22.
//

import SwiftUI
import PhotosUI

struct MediaPicker: UIViewControllerRepresentable {
    typealias UIViewControllerType = PHPickerViewController
    
    @ObservedObject var mediaItems: PickedMediaItems
    var didFinishPicking: (_ didSelectItems: Bool) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .any(of: [.images, .videos])
        config.selectionLimit = 0
        config.preferredAssetRepresentationMode = .current
        
        let controller = PHPickerViewController(configuration: config)
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        
    }
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(with: self)
    }
    
    
    class Coordinator: PHPickerViewControllerDelegate {
        var photoPicker: MediaPicker
        
        init(with photoPicker: MediaPicker) {
            self.photoPicker = photoPicker
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            photoPicker.didFinishPicking(!results.isEmpty)
            
            guard !results.isEmpty else {
                return
            }
            
            for result in results {
                let itemProvider = result.itemProvider
                
                guard let typeIdentifier = itemProvider.registeredTypeIdentifiers.first,
                      let utType = UTType(typeIdentifier)
                else { continue }
                
                if utType.conforms(to: .image) {
                    self.getPhoto(from: itemProvider)
                } else if utType.conforms(to: .movie) {
                    self.getVideo(from: itemProvider, typeIdentifier: typeIdentifier)
                }
            }
        }
        
        
        private func getPhoto(from itemProvider: NSItemProvider) {
            let objectType: NSItemProviderReading.Type = UIImage.self
            
            if itemProvider.canLoadObject(ofClass: objectType) {
                itemProvider.loadObject(ofClass: objectType) { object, error in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    if let image = object as? UIImage {
                        DispatchQueue.main.async {
                            self.photoPicker.mediaItems.append(item: PhotoPickerModel(with: image))
                        }
                    }
                }
            }
        }
        
        
        private func getVideo(from itemProvider: NSItemProvider, typeIdentifier: String) {
            itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
                if let error = error {
                    print(error.localizedDescription)
                }
                
                guard let url = url else { return }
                
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                guard let targetURL = documentsDirectory?.appendingPathComponent(url.lastPathComponent) else { return }
                
                do {
                    if FileManager.default.fileExists(atPath: targetURL.path) {
                        try FileManager.default.removeItem(at: targetURL)
                    }
                    
                    try FileManager.default.copyItem(at: url, to: targetURL)
                    
                    DispatchQueue.main.async {
                        self.photoPicker.mediaItems.append(item: PhotoPickerModel(with: targetURL))
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
}
