/// 導航頁面
///
/// Created by TWINB00591630 on 2023/10/25.
/// Copyright © 2023 Cathay United Bank. All rights reserved.

import UIKit
import Combine

internal class KFJourneyViewController: UIViewController {    
    
	var viewModel: KFJourneyViewModel

	init() {
		viewModel = .init()
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}	
						    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }    
}
