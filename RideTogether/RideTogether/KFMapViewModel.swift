/// <#Brief Description#>
///
/// Created by TWINB00591630 on 2023/10/30.
/// Copyright © 2023 Cathay United Bank. All rights reserved.

import Combine
import Foundation

internal class KFMapViewModel {

    var tapStartSubject = PassthroughSubject<Void, Never>()
    
    func start() {
        tapStartSubject.send()
    }
}

enum Status {
    case start
    case pause
    case restart
}
