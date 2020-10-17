//
//  AlertHandlerProtocol.swift
//  Maps App
//
//  Created by Colin Murphy on 10/16/20.
//

import UIKit

//swiftlint:disable identifier_name

enum AlertButton: String {
    
    case ok
    case cancel
    case delete
    case settings
}

protocol AlertHandlerProtocol: UIViewController {
    func showAlert(title: String, message: String, buttons: [AlertButton], completion: @escaping (UIAlertController, AlertButton) -> Void)
}

extension AlertHandlerProtocol {
    
    func showAlert(title: String, message: String, buttons: [AlertButton] = [.ok], completion: @escaping (UIAlertController, AlertButton) -> Void) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        buttons.forEach { button in
            let action = UIAlertAction(title: button.rawValue.capitalized, style: button == .delete ? .destructive : .default) { [alert, button] _ in
                completion(alert, button)
            }
            alert.addAction(action)
        }
        present(alert, animated: true)
    }
}
