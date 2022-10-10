//
//  Extensions.swift
//  iEditor
//
//  Created by Atik on 9/10/22.
//

import SwiftUI
import UIKit
import AVFoundation

extension AVAsset {
    
    func videoOrientation() -> (orientation: UIInterfaceOrientation, device: AVCaptureDevice.Position) {
        var orientation: UIInterfaceOrientation = .unknown
        var device: AVCaptureDevice.Position = .unspecified
        
        let tracks: [AVAssetTrack] = self.tracks(withMediaType: .video)
        if let videoTrack = tracks.first {
            
            let t = videoTrack.preferredTransform
            
            if (t.a == 0 && t.b == 1.0 && t.d == 0) {
                orientation = .portrait
                
                if t.c == 1.0 {
                    device = .front
                } else if t.c == -1.0 {
                    device = .back
                }
            }
            else if (t.a == 0 && t.b == -1.0 && t.d == 0) {
                orientation = .portraitUpsideDown
                
                if t.c == -1.0 {
                    device = .front
                } else if t.c == 1.0 {
                    device = .back
                }
            }
            else if (t.a == 1.0 && t.b == 0 && t.c == 0) {
                orientation = .landscapeRight
                
                if t.d == -1.0 {
                    device = .front
                } else if t.d == 1.0 {
                    device = .back
                }
            }
            else if (t.a == -1.0 && t.b == 0 && t.c == 0) {
                orientation = .landscapeLeft
                
                if t.d == 1.0 {
                    device = .front
                } else if t.d == -1.0 {
                    device = .back
                }
            }
        }
        
        return (orientation, device)
    }
    
    func writeAudioTrackToURL(URL: URL, completion: @escaping (Bool, Error?) -> ()) {
        do {
            let audioAsset = try self.audioAsset()
            audioAsset.writeToURL(URL: URL, completion: completion)
            
        } catch {
            completion(false, error)
        }
    }
    
    func writeToURL(URL: URL, completion: @escaping (Bool, Error?) -> ()) {
        guard let exportSession = AVAssetExportSession(asset: self, presetName: AVAssetExportPresetAppleM4A) else {
            completion(false, nil)
            return
        }
        
        exportSession.outputFileType = AVFileType.m4a
        exportSession.outputURL      = URL as URL
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(true, nil)
            case .unknown, .waiting, .exporting, .failed, .cancelled:
                completion(false, nil)
            @unknown default:
                completion(false, nil)
            }
        }
    }
    
    func audioAsset() throws -> AVAsset {
        let composition = AVMutableComposition()
        let audioTracks = tracks(withMediaType: AVMediaType.audio)
        for track in audioTracks {
            
            let compositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                try compositionTrack?.insertTimeRange(track.timeRange, of: track, at: track.timeRange.start)
            } catch {
                throw error
            }
            compositionTrack?.preferredTransform = track.preferredTransform
        }
        return composition
    }
}

extension UIImage {
    
    /// Method to scale an image to the given size while keeping the aspect ratio
    ///
    /// - Parameter newSize: the new size for the image
    /// - Returns: the resized image
    func scaleImageToSize(newSize: CGSize) -> UIImage? {
        
        var scaledImageRect: CGRect = CGRect.zero
        
        let aspectWidth: CGFloat = newSize.width / size.width
        let aspectHeight: CGFloat = newSize.height / size.height
        let aspectRatio: CGFloat = min(aspectWidth, aspectHeight)
        
        scaledImageRect.size.width = size.width * aspectRatio
        scaledImageRect.size.height = size.height * aspectRatio
        
        scaledImageRect.origin.x = (newSize.width - scaledImageRect.size.width) / 2.0
        scaledImageRect.origin.y = (newSize.height - scaledImageRect.size.height) / 2.0
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        if UIGraphicsGetCurrentContext() != nil {
            draw(in: scaledImageRect)
            let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return scaledImage
        }
        
        return nil
    }
    
    /// Method to get a size for the image appropriate for video (dividing by 16 without overlapping 1200)
    ///
    /// - Returns: a size fit for video
    func getSizeForVideo() -> CGSize {
        let scale = UIScreen.main.scale
        var imageWidth = 16 * ((size.width / scale) / 16).rounded(.awayFromZero)
        var imageHeight = 16 * ((size.height / scale) / 16).rounded(.awayFromZero)
        var ratio: CGFloat!
        
        if imageWidth > 1400 {
            ratio = 1400 / imageWidth
            imageWidth = 16 * (imageWidth / 16).rounded(.towardZero) * ratio
            imageHeight = 16 * (imageHeight / 16).rounded(.towardZero) * ratio
        }
        
        if imageWidth < 800 {
            ratio = 800 / imageWidth
            imageWidth = 16 * (imageWidth / 16).rounded(.awayFromZero) * ratio
            imageHeight = 16 * (imageHeight / 16).rounded(.awayFromZero) * ratio
        }
        
        if imageHeight > 1200 {
            ratio = 1200 / imageHeight
            imageWidth = 16 * (imageWidth / 16).rounded(.towardZero) * ratio
            imageHeight = 16 * (imageHeight / 16).rounded(.towardZero) * ratio
        }
        
        return CGSize(width: imageWidth, height: imageHeight)
    }
    
    
    /// Method to resize an image to an appropriate video size
    ///
    /// - Returns: the resized image
    func resizeImageToVideoSize() -> UIImage? {
        let scale = UIScreen.main.scale
        let videoImageSize = getSizeForVideo()
        let imageRect = CGRect(x: 0, y: 0, width: videoImageSize.width * scale, height: videoImageSize.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: imageRect.width, height: imageRect.height), false, scale)
        if let _ = UIGraphicsGetCurrentContext() {
            draw(in: imageRect, blendMode: .normal, alpha: 1)
            
            if let resultImage = UIGraphicsGetImageFromCurrentImageContext() {
                UIGraphicsEndImageContext()
                return resultImage
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}

extension FileManager {
    func removeItemIfExisted(_ url:URL) -> Void {
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(atPath: url.path)
            }
            catch {
                debugPrint("Failed to delete file")
            }
        }
    }
}

extension Date {
    var ticks: UInt64 {
        return UInt64((self.timeIntervalSince1970 + 62_135_596_800) * 10_000_000)
    }
}
