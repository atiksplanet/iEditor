//
//  PhotoMergerView.swift
//  VideoEditor
//
//  Created by Atikul Gazi on 6/10/22.
//

import SwiftUI

struct PhotoMergerView: View {
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    @State private var showPopUp = false
    
    @ObservedObject var mediaItems: PickedMediaItems
    
    var body: some View {
        VStack {
            EmptyView()
        }
        .onAppear() {
            let imageItems = mediaItems.items.filter({ $0.mediaType == .photo })
            showPopUp = imageItems.count == 0
        }
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
