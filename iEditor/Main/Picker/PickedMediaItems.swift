//
//  PickedMediaItems.swift
//  VideoEditor
//
//  Created by Atikul Gazi on 6/10/22.
//

import SwiftUI

class PickedMediaItems: ObservableObject {
    @Published var items = [PhotoPickerModel]()
    
    func append(item: PhotoPickerModel) {
        items.append(item)
    }
    
    func deleteAll() {
        for (index, _) in items.enumerated() {
            items[index].delete()
        }
        
        items.removeAll()
    }
}
