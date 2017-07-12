//
//  ViewController.swift
//  sit with me
//
//  Created by Jason La on 8/31/16.
//  Copyright © 2016 Jason La. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController {
    
    @IBOutlet weak var quoteLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    
    let rootRef = FIRDatabase.database().reference()
    var randNum : Int = 2
    var count : Int = 10

    override func viewDidLoad() {
        super.viewDidLoad()

        rootRef.child("0").observe(.value, with: { snapshot in
            let dict = snapshot.value as! [String : Int]
            self.count = dict["quote"]!
            self.randNum = Int(arc4random_uniform(UInt32(self.count))) + 1
            print("rand num: \(self.randNum)")
            
            self.rootRef.child("\(self.randNum)").observe(.value, with: { snapshot in
                let dict = snapshot.value as! [String : String]
                self.quoteLabel.text = dict["quote"]
                self.sourceLabel.text = "- " + dict["source"]!
            })
        })
        

    }
    
    /*
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if (segue.identifier == "startToMindfulSegue" && t1.timer != nil) {
            let mindfulVC = segue.destination as! MindfulnessBellViewController
            mindfulVC.t1 = self.t1
        }
    }*/

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
}

