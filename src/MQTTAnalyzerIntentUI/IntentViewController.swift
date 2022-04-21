//
//  IntentViewController.swift
//  MQTTAnalyzerIntentUI
//
//  Created by Philipp Arndt on 20.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import IntentsUI

class IntentViewController: UIViewController, INUIHostedViewControlling {
	@IBOutlet weak var contentLabel: UILabel!
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }
        
    // MARK: - INUIHostedViewControlling
    
    // Prepare your view controller for the interaction to handle.
    func configureView(for parameters: Set<INParameter>, of interaction: INInteraction, interactiveBehavior: INUIInteractiveBehavior, context: INUIHostedViewContext, completion: @escaping (Bool, Set<INParameter>, CGSize) -> Void) {
		
		guard let intent = interaction.intent as? SendMQTTMessageIntent else {
			completion(false, Set(), .zero)
			return
		}
		
		if let topic = intent.topic, let message = intent.message {
			self.contentLabel.text = "Okay"
		}

		completion(true, parameters, self.desiredSize)
    }
    
//    var desiredSize: CGSize {
//        return self.extensionContext!.hostedViewMaximumAllowedSize
//    }
	
	var desiredSize: CGSize {
		return CGSize.init(width: 10, height: 100)
	}
    
}
