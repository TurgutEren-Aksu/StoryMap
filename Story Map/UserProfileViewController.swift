//
//  UserProfileViewController.swift
//  HaritaDeneme
//
//  Created by Turgut Eren Aksu on 27.12.2024.
//

import UIKit
import FirebaseAuth

class UserProfileViewController: UIViewController {
    
    @IBOutlet weak var emailLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        if let user = Auth.auth().currentUser {
            if let email = user.email {
                // E-posta adresinden @ işaretine kadar olan kısmı al
                if let atIndex = email.firstIndex(of: "@") {
                    let username = String(email[..<atIndex])
                    emailLabel.text = username
                } else {
                    emailLabel.text = "Geçersiz E-posta"
                }
            } else {
                emailLabel.text = "E-posta bulunamadı"
            }
        }
    }
    
    @IBAction func backButton(_ sender: UIButton) {
        self.dismiss(animated: true,completion: nil)
    }
    @IBAction func logoutButton(_ sender: UIButton) {
        logout()
        print("Kullanıcı Hesabından Çıktı")
    }
    
    func logout() {
        // 1. Kullanıcı oturumunu sonlandır (Firebase örneği):
        // Firebase'de kullanıcıyı çıkış yaptırma (eğer Firebase kullanıyorsanız)
        try? Auth.auth().signOut()
        
        // 2. Çıkış yaptıktan sonra, giriş ekranına yönlendirme:
        navigateToLoginScreen()
    }
    
    func navigateToLoginScreen() {
        // 4. Giriş ekranına yönlendirme işlemi:
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
            // Login ekranını storyboard'dan al
            let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginAndRegisterViewController") as! LoginAndRegisterViewController
            
            // Yeni root view controller olarak giriş ekranını ayarla
            sceneDelegate.window?.rootViewController = loginVC
            
            // Ekran değişiminin animasyonlu olması için:
            UIView.transition(with: sceneDelegate.window!, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
        }
    }
    
    @IBAction func deleteAccount(_ sender: UIButton) {
        promptForAccountDeletion()
    }
    // Hesap silme için onay almak amacıyla alert gösteren fonksiyon
    func promptForAccountDeletion() {
        let alert = UIAlertController(title: "Hesap Silme", message: "Hesabınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.", preferredStyle: .alert)
        
        // "İptal" butonu
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel, handler: nil))
        
        // "Sil" butonu
        alert.addAction(UIAlertAction(title: "Sil", style: .destructive, handler: { _ in
            // Kullanıcıdan şifreyi almak için alerti açıyoruz
            self.promptForPassword()
        }))
        
        // Aktif view controller'dan alert'i göster
        self.present(alert, animated: true, completion: nil)
    }
    
    // Kullanıcıdan şifreyi almak için fonksiyon
    func promptForPassword() {
        let alert = UIAlertController(title: "Şifrenizi Girin", message: "Hesabınızı silmek için şifrenizi girin.", preferredStyle: .alert)
        
        // Şifreyi gizli şekilde almak için textField ekliyoruz
        alert.addTextField { textField in
            textField.isSecureTextEntry = true
            textField.placeholder = "Şifre"
        }
        
        // "İptal" butonu
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel, handler: nil))
        
        // "Onayla" butonu
        alert.addAction(UIAlertAction(title: "Onayla", style: .default, handler: { _ in
            if let password = alert.textFields?.first?.text {
                // Şifreyi aldıktan sonra re-authenticate işlemi yapıyoruz
                self.deleteUserAccountWithPassword(password: password)
            }
        }))
        
        // Şifre giriş alert'ini gösteriyoruz
        self.present(alert, animated: true, completion: nil)
    }
    
    // Kullanıcıyı silme işlemi
    func deleteUserAccountWithPassword(password: String) {
        // Mevcut kullanıcıyı alın
        guard let user = Auth.auth().currentUser else {
            print("Kullanıcı oturumu açık değil")
            return
        }
        
        // Kullanıcıyı silmeden önce, kullanıcıdan tekrar kimlik doğrulaması isteniyor.
        // Burada şifreyi alıyoruz ve kimlik doğrulaması yapıyoruz.
        let credential = EmailAuthProvider.credential(withEmail: user.email!, password: password)
        
        // Kimlik doğrulaması için re-authenticate işlemi
        user.reauthenticate(with: credential) { (result, error) in
            if let error = error {
                print("Kullanıcı tekrar kimlik doğrulamasında hata: \(error.localizedDescription)")
                return
            }
            
            // Kimlik doğrulaması başarılıysa, kullanıcıyı sil
            user.delete { (error) in
                if let error = error {
                    print("Kullanıcı hesabı silinemedi: \(error.localizedDescription)")
                } else {
                    print("Kullanıcı hesabı başarıyla silindi.")
                    // Hesap silindikten sonra yapılması gereken işlemler
                    self.navigateToLoginScreen() // Örneğin, giriş ekranına yönlendirme
                }
            }
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

