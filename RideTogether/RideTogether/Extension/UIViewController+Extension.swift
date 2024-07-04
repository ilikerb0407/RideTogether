/// <#Brief Description#> 
///
/// Created by TWINB00591630 on 2024/6/30.
/// Copyright © 2024 Cathay United Bank. All rights reserved.

import UIKit

internal extension UIViewController {
    
    final func showAlert(provider : AlertProvider) {
        let alertController: UIAlertController = .init(title: provider.title, message: provider.message, preferredStyle: provider.preferredStyle)

        for action in provider.actions {
            alertController.addAction(action)
        }
        self.present(alertController, animated: true)

        configurePopoverPresentationController(alertController)
    }

    // iPad specific code
    private func configurePopoverPresentationController(_ controller: UIAlertController) {
        if let popover = controller.popoverPresentationController {
            popover.sourceView = self.view
            let xOrigin = self.view.bounds.width / 2
            let popoverRect = CGRect(x: xOrigin, y: 0, width: 1, height: 1)
            popover.sourceRect = popoverRect
            popover.permittedArrowDirections = .up
        }
    }
}
