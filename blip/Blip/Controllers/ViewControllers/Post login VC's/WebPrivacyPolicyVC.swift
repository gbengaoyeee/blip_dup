//
//  WebPrivacyPolicyVC.swift
//  Blip
//
//  Created by Gbenga Ayobami on 2018-06-13.
//  Copyright © 2018 Blip. All rights reserved.
//

import UIKit
import WebKit

class WebPrivacyPolicyVC: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        let urlString: String = "https://www.blip.delivery/privacy-policy"
        let url: URL = URL(string: urlString)!
        let request:URLRequest = URLRequest(url: url)
        self.webView.load(request)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func donePressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

}
