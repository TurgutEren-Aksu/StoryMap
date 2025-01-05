//
//  RegisterSegmentViewController.swift
//  HaritaDeneme
//
//  Created by Turgut Eren Aksu on 26.12.2024.
//

import UIKit
import FirebaseAuth

class RegisterSegmentViewController: UIViewController {
    
    @IBOutlet weak var confirmpassTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    override func viewDidLoad() {
            super.viewDidLoad()
            
            // Şifre TextField'ı için köşe yuvarlatma ve gölge
            styleTextField(passwordTextField)

            // Confirm Password TextField'ı için köşe yuvarlatma ve gölge
            styleTextField(confirmpassTextField)

            // E-posta TextField'ı için köşe yuvarlatma ve gölge
            styleTextField(emailTextField)
            
            // Butona stil ekleme
            styleButton(registerButton)  // Butona stil ekleme
        }
        
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
    @IBAction func registerButtonTapped(_ sender: UIButton) {
        // TextField'ların içeriğini al
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let confirmPassword = confirmpassTextField.text, !confirmPassword.isEmpty else {
            // Kullanıcı boş alan bırakırsa uyarı göster
            showAlert(message: "Lütfen tüm alanları doldurun.")
            return
        }
        
        // Şifrelerin eşleşip eşleşmediğini kontrol et
        if password != confirmPassword {
            showAlert(message: "Şifreler uyuşmuyor. Lütfen tekrar deneyin.")
            return
        }
        
        // Firebase'de kullanıcı oluşturma işlemi
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                // Hata varsa, hatayı göster
                self.showAlert(message: "Kayıt başarısız: \(error.localizedDescription)")
                return
            }
            
            // Kayıt başarılı olduğunda kullanıcıya bilgi mesajı göster
            self.showAlert(message: "Kayıt başarılı! Giriş yapabilirsiniz.") { _ in
                // Başarılı kayıt sonrası kullanıcıyı giriş ekranına yönlendir
//                self.navigateToLoginScreen()
            }
        }
    }
    
    // Uyarı göstermek için yardımcı fonksiyon
    private func showAlert(message: String, completion: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: "Bilgi", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: completion))
        present(alert, animated: true, completion: nil)
    }
    
    // Kayıt başarılı olduktan sonra giriş ekranına yönlendirme
//    private func navigateToLoginScreen() {
//        // Storyboard'daki giriş ekranına geçiş
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        if let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginSegmentViewController") as? LoginSegmentViewController {
//            self.present(loginVC, animated: true, completion: nil)
//        }
//    }
}

/*
 // MARK: - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
 // Get the new view controller using segue.destination.
 // Pass the selected object to the new view controller.
 }
 */

