//
//  AppleSelectedAnnotationView.swift
//  Maps App
//
//  Created by Colin Murphy on 10/17/20.
//

import MapKit

class AppleSelectedAnnotationView: UIStackView {
    
    @IBOutlet private weak var shopLabel: UILabel!
    @IBOutlet private weak var detailButton: UIButton!
    
    func set(title: String) {
        shopLabel.text = title
    }
}
