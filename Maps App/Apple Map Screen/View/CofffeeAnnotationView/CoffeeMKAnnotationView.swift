//
//  CoffeeMKAnnotationView.swift
//  Maps App
//
//  Created by Colin Murphy on 10/21/20.
//

import MapKit
import UIKit

class CoffeeMKAnnotationView: MKAnnotationView {
    
    // MARK: - IBOutlets
    
    @IBOutlet private weak var reviewLabel: UILabel!
    @IBOutlet private weak var oneStarImageView: UIImageView!
    @IBOutlet private weak var twoStarImageView: UIImageView!
    @IBOutlet private weak var threeStarImageView: UIImageView!
    @IBOutlet private weak var fourStarImageView: UIImageView!
    @IBOutlet private weak var fiveStarImageView: UIImageView!
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var contentSubView: UIView!
    
    // MARK: - Inits
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    // MARK: - Configure View
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func set(review: String, rating: Int) {
        
        reviewLabel.text = review
        if #available(iOS 13.0, *) {
            if rating > 0 { oneStarImageView.image = UIImage(systemName: "star.fill") }
            if rating > 1 { twoStarImageView.image = UIImage(systemName: "star.fill") }
            if rating > 2 { threeStarImageView.image = UIImage(systemName: "star.fill") }
            if rating > 3 { fourStarImageView.image = UIImage(systemName: "star.fill") }
            if rating > 4 { fiveStarImageView.image = UIImage(systemName: "star.fill") }
        }
    }
    
    private func commonInit() {
        
        image = UIImage(named: "purple-pin72")
        canShowCallout = true
        Bundle.main.loadNibNamed("CoffeeMKAnnotationView", owner: self, options: nil)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let snapshotView = UIView()
        snapshotView.translatesAutoresizingMaskIntoConstraints = false
        snapshotView.addSubview(contentView)
        detailCalloutAccessoryView = snapshotView
        
        NSLayoutConstraint.activate([
            snapshotView.widthAnchor.constraint(equalToConstant: 210),
            snapshotView.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
}
