/// <#Brief Description#> 
///
/// Created by TWINB00591630 on 2024/6/30.
/// Copyright © 2024 Cathay United Bank. All rights reserved.

import UIKit

internal struct AlertProvider {
    let title: String?
    let message: String?
    let preferredStyle: UIAlertController.Style
    let actions: [UIAlertAction]

    init(title: String = "", message: String = "", preferredStyle: UIAlertController.Style = .alert, actions: [UIAlertAction] = [UIAlertAction(title: "OK", style: .cancel)]) {
        self.title = title
        self.message = message
        self.preferredStyle = preferredStyle
        self.actions = actions
    }
}
