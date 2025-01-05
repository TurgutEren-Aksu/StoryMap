//
//  LoginSegmentViewController.swift
//  HaritaDeneme
//
//  Created by Turgut Eren Aksu on 26.12.2024.
//

import UIKit
import FirebaseAuth



class LoginSegmentViewController: UIViewController {
    
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    override func viewDidLoad() {
            super.viewDidLoad()
            
            // TextField'lara stil ekleme
            styleTextField(passwordTextField)
            styleTextField(emailTextField)
            
            // Butona stil ekleme
            styleButton(signInButton)  // Butona stil ekleme
        }
        
        // TextField'lara stil eklemek için yardımcı fonksiyon
        private func styleTextField(_ textField: UITextField) {
            // Yuvarlatılmış köşeler
            textField.layer.cornerRadius = 10
            textField.layer.masksToBounds = true // Corner radius'un düzgün görünmesi için

            // Gölge
            textField.layer.shadowColor = UIColor.black.cgColor // Gölgenin rengi
            textField.layer.shadowOffset = CGSize(width: 0, height: 2) // Gölgenin yönü
            textField.layer.shadowOpacity = 0.2 // Gölgenin opaklığı
            textField.layer.shadowRadius = 4 // Gölgenin yayılma büyüklüğü
        }

        // Butona stil eklemek için yardımcı fonksiyon
        private func styleButton(_ button: UIButton) {
            // Yuvarlatılmış köşeler
            button.layer.cornerRadius = 10
            button.layer.masksToBounds = true  // Corner radius'un düzgün görünmesi için
            
            // Gölge
            button.layer.shadowColor = UIColor.black.cgColor // Gölgenin rengi
            button.layer.shadowOffset = CGSize(width: 0, height: 4) // Gölgenin yönü
            button.layer.shadowOpacity = 0.3 // Gölgenin opaklığı
            button.layer.shadowRadius = 6 // Gölgenin yayılma büyüklüğü
        }
    
    @IBAction func signInButton(_ sender: UIButton) {
        // TextField'ların içeriğini al
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            // Kullanıcı boş alan bırakırsa uyarı göster
            showAlert(message: "Lütfen tüm alanları doldurun.")
            return
        }
        
        // Firebase oturum açma işlemi
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                // Giriş başarısız olduğunda hata mesajını göster
                self.showAlert(message: "Giriş başarısız: \(error.localizedDescription)")
                return
            }
            
            // Giriş başarılı olduğunda yeni ekrana geçiş
            self.navigateToMainScreen()
        }
    }
    
    // Uyarı göstermek için yardımcı fonksiyon
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Bilgi", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // Başarılı girişten sonra yeni ekrana geçiş
    private func navigateToMainScreen() {
        // Storyboard'daki ekranın Storyboard ID'sini kullanarak geçiş yapıyoruz
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let mainVC = storyboard.instantiateViewController(withIdentifier: "ViewController") as? ViewController {
            mainVC.modalPresentationStyle = .fullScreen // Tam ekran olarak göster
            self.present(mainVC, animated: true, completion: nil)
        }
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

