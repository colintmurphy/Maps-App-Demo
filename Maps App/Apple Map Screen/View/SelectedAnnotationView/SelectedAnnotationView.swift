//
//  SelectedAnnotationView.swift
//  Maps App
//
//  Created by Colin Murphy on 10/17/20.
//

import MapKit

class SelectedAnnotationView: UIStackView {
    
    @IBOutlet private weak var shopLabel: UILabel!
    @IBOutlet private weak var detailButton: UIButton!
    
    func set(title: String) {
        
        shopLabel.text = title
        detailButton.isHidden = true
        layer.cornerRadius = bounds.height / 2.5
        layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
    
    func setForApple(title: String) {
        
        shopLabel.text = title
        //shopLabel.isHidden = true
        detailButton.isHidden = true
        backgroundColor = .clear
    }
}
