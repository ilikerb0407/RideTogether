/// 第一頁
///
/// Created by TWINB00591630 on 2023/10/27.
/// Copyright © 2023 Cathay United Bank. All rights reserved.

import UIKit
import Combine

internal class ExploreViewController: UIViewController {    
    
	var viewModel: ExploreViewModel

	init() {
		viewModel = .init()
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}	
						    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Journey"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }    
}
