//
//  UIApplication+Ext.swift
//  Maps App
//
//  Created by Colin Murphy on 10/16/20.
//

import UIKit

extension UIApplication {
    
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
}
