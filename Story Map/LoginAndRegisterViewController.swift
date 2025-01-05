//
//  LoginAndRegisterViewController.swift
//  HaritaDeneme
//
//  Created by Turgut Eren Aksu on 26.12.2024.
//

import UIKit
import FirebaseCore

class LoginAndRegisterViewController: UIViewController {

    @IBOutlet weak var registerSegmentView: UIView!
    
    @IBOutlet weak var loginSegmentView: UIView!
    @IBOutlet weak var segmentOutlet: UISegmentedControl!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        segmentOutlet.setTitleTextAttributes(titleTextAttributes, for: .normal)
        self.view.bringSubviewToFront(loginSegmentView)
        // Do any additional setup after loading the view.
    }
    
    @IBAction func segmentAction(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex{
        case 0:
            self.view.bringSubviewToFront(loginSegmentView)
        case 1:
            self.view.bringSubviewToFront(registerSegmentView)
        default:
            break
        }
        
        
        
    }
    
        
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
