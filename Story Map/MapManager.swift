import UIKit
import FirebaseStorage
import FirebaseFirestore
import GoogleMaps
import CoreLocation
import FirebaseAuth


class MapManager: NSObject, CLLocationManagerDelegate, GMSMapViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let locationManager = CLLocationManager()
    private var mapView: GMSMapView!
    private weak var parentViewController: UIViewController?
    private var shouldUpdateLocation = true

    
    // Enlem ve boylamı saklamak için değişkenler
    var latitude: Double?
    var longitude: Double?
    private let firestore = Firestore.firestore()
    private let storage = Storage.storage()
    
    
    // Anılar dizisi (Veri artık Firebase yerine bellekte saklanacak)
    var memories: [Memory] = []
    
    // Info paneli
    private var infoPanel: UIView?
    private var titleLabel: UILabel?
    private var descriptionLabel: UILabel?
    private var imageView: UIImageView?
    private var closeButton: UIButton?  // X butonu
    private var deleteButton: UIButton? // Marker silme butonu
    private var currentMarker: GMSMarker? // Şu anki tıklanan marker
    
    init(mapView: GMSMapView, parentViewController: UIViewController) {
        super.init()
        self.mapView = mapView
        self.parentViewController = parentViewController
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        // Konum izni isteme
        self.locationManager.requestWhenInUseAuthorization()
        
        self.mapView.isMyLocationEnabled = true
        self.mapView.settings.myLocationButton = true
        
        // Harita için delegasyon ayarı
        self.mapView.delegate = self
    }
    
    
    let uid = Auth.auth().currentUser?.uid
    
    // Konum izni verildiğinde
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
    func mapView(_ mapView: GMSMapView, didDrag marker: GMSMarker) {
        shouldUpdateLocation = false
    }

    
    // Konum güncellenirse
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        if shouldUpdateLocation {
                let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 10)
                mapView.camera = camera
            }
    }
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        shouldUpdateLocation = false
    }
    // Harita tıklama olayını dinle
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        // Enlem ve boylam bilgilerini değişkende tut
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        
        // Konsola yazdır
        print("Tıklanan koordinat: Latitude: \(coordinate.latitude), Longitude: \(coordinate.longitude)")
        
        // Kullanıcıdan anı metni ve resim (isteğe bağlı) almak için bir alert göster
        let alert = UIAlertController(title: "Yeni Anı Ekle", message: "Burası hakkında bir anı bırakın.", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Başlık"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Anı açıklaması"
        }
        
        alert.addAction(UIAlertAction(title: "Ekle", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            
            // Başlık ve açıklama alalım
            let title = alert.textFields?[0].text ?? ""
            let description = alert.textFields?[1].text ?? ""
            
            // Resim eklemek isteyip istemediğini soralım
            self.askForImageOption(for: title, description: description, latitude: coordinate.latitude, longitude: coordinate.longitude)
        }))
        
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        
        // Parent view controller'da alert'i göster
        parentViewController?.present(alert, animated: true)
    }
    
    // Resim eklemek isteyip istemediğini sor
    func askForImageOption(for title: String, description: String, latitude: Double, longitude: Double) {
        let alert = UIAlertController(title: "Resim Eklemek İster Misiniz?", message: "Bu anıya bir resim eklemek istiyor musunuz?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Evet", style: .default, handler: { [weak self] _ in
            // Resim seçme işlemi başlat
            self?.selectImage(for: title, description: description, latitude: latitude, longitude: longitude)
        }))
        
        alert.addAction(UIAlertAction(title: "Hayır", style: .cancel, handler: { [weak self] _ in
            // Resim eklemeden anıyı kaydet
            self?.saveMemoryWithoutImage(for: title, description: description, latitude: latitude, longitude: longitude)
        }))
        
        parentViewController?.present(alert, animated: true)
    }
    
    // Resim seçme ekranını göster
    func selectImage(for title: String, description: String, latitude: Double, longitude: Double) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        parentViewController?.present(imagePicker, animated: true)
        
        // Resim seçildikten sonra anıyı oluşturacağız
        self.selectedMemory = Memory(title: title, description: description, latitude: latitude, longitude: longitude, date: Date(), image: nil)
    }
    
    // Seçilen resim
    var selectedMemory: Memory?
    
    // Resim seçildikten sonra çalışacak fonksiyon
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Seçilen resmi al
        if let image = info[.originalImage] as? UIImage {
            // Seçilen resmi Memory objesine ekle
            selectedMemory?.image = image
            
            // Resmi aldıktan sonra anıyı kaydedelim
            if let memory = selectedMemory {
                // Belleğe kaydet
                self.saveMemoryWithImage(memory, image: image)
            }
        }
        
        // Picker'ı kapat
        picker.dismiss(animated: true)
    }
    
    // resimle beraber anıyı kaydet
    func saveMemoryWithImage(_ memory: Memory, image: UIImage) {
        guard let uid = Auth.auth().currentUser?.uid else { return } // Kullanıcı UID'si al
        
        memories.append(memory) // Belleğe ekleme
        addMarkerForMemory(memory) // Haritaya marker ekleme
        
        // Fotoğrafı sıkıştır ve optimize et
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Görsel sıkıştırılamadı.")
            return
        }
        
        // Görsel boyutunu kontrol et
        let imageSizeInMB = Double(imageData.count) / (1024.0 * 1024.0)
        if imageSizeInMB > 5.0 {
            print("Fotoğraf boyutu çok büyük (\(imageSizeInMB) MB). Lütfen daha küçük bir fotoğraf yükleyin.")
            return
        }
        
        // Fotoğrafın önbelleğe alınması
        let imageName = UUID().uuidString
        ImageCacheManager.shared.saveImageToCache(image: image, forKey: imageName) // Görseli önbelleğe kaydediyoruz
        
        // Firebase Storage için benzersiz dosya adı oluştur
        let storageRef = storage.reference().child("users/\(uid)/images/\(imageName).jpg")
        
        // Görseli Firebase Storage'a yükle
        storageRef.putData(imageData, metadata: nil) { [weak self] metadata, error in
            if let error = error {
                print("Fotoğraf yükleme başarısız: \(error.localizedDescription)")
                return
            }
            
            // Fotoğraf URL'sini al ve Firestore'a kaydet
            storageRef.downloadURL { url, error in
                guard let self = self else { return }
                if let error = error {
                    print("URL alma başarısız: \(error.localizedDescription)")
                    return
                }
                
                if let imageUrl = url?.absoluteString {
                    let memoryData: [String: Any] = [
                        "title": memory.title,
                        "description": memory.description,
                        "latitude": memory.latitude,
                        "longitude": memory.longitude,
                        "date": Timestamp(date: memory.date),
                        "imageUrl": imageUrl
                    ]
                    
                    self.firestore.collection("users").document(uid).collection("memories").addDocument(data: memoryData) { error in
                        if let error = error {
                            print("Firestore'a kaydedilemedi: \(error.localizedDescription)")
                        } else {
                            print("Anı ve fotoğraf Firestore'a başarıyla kaydedildi.")
                        }
                    }
                }
            }
        }
    }
    
    
    
    
    // resimsiz anıyı kaydet
    func saveMemoryWithoutImage(for title: String, description: String, latitude: Double, longitude: Double) {
        guard let uid = Auth.auth().currentUser?.uid else { return } // Kullanıcı UID'si al
        
        let memory = Memory(title: title, description: description, latitude: latitude, longitude: longitude, date: Date(), image: nil)
        memories.append(memory) // Belleğe ekleme
        addMarkerForMemory(memory) // Haritaya marker ekleme
        
        // Firestore'ye kaydet
        let memoryData: [String: Any] = [
            "title": title,
            "description": description,
            "latitude": latitude,
            "longitude": longitude,
            "date": Timestamp(date: Date())
        ]
        
        firestore.collection("users").document(uid).collection("memories").addDocument(data: memoryData) { error in
            if let error = error {
                print("Firestore'a kaydedilemedi: \(error.localizedDescription)")
            } else {
                print("Anı Firestore'a başarıyla kaydedildi.")
            }
        }
    }
    
    
    // Anıyı haritada marker olarak göster
    func addMarkerForMemory(_ memory: Memory) {
        let position = CLLocationCoordinate2D(latitude: memory.latitude, longitude: memory.longitude)
        let marker = GMSMarker(position: position)
        marker.title = memory.title
        marker.snippet = memory.description
        marker.map = mapView
        marker.userData = memory // Memory verisini marker'a bağla
    }
    
    
    // Marker'a tıklanıldığında custom info paneli açılacak
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        if let memory = marker.userData as? Memory {
            showInfoPanel(for: memory, marker: marker)
        }
        return true
    }
    
    // Modern, estetik card style info panelini göster
    func showInfoPanel(for memory: Memory, marker: GMSMarker) {
        // Eğer panel zaten varsa, önceki paneli temizle
        infoPanel?.removeFromSuperview()
        
        // Yeni paneli oluştur
        infoPanel = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 220))
        infoPanel?.backgroundColor = UIColor.white
        infoPanel?.layer.cornerRadius = 12
        infoPanel?.layer.shadowColor = UIColor.black.cgColor
        infoPanel?.layer.shadowOpacity = 0.3
        infoPanel?.layer.shadowOffset = CGSize(width: 0, height: 5)
        infoPanel?.layer.shadowRadius = 10
        
        // Paneli ekranın tam ortasına yerleştir
        if let panel = infoPanel {
            panel.center = parentViewController?.view.center ?? CGPoint(x: 160, y: 240)
        }
        
        // Resim eklemek
        if let image = memory.image {
            imageView = UIImageView(image: image)
            imageView?.contentMode = .scaleAspectFill
            imageView?.frame = CGRect(x: 10, y: 10, width: 100, height: 100)
            imageView?.layer.cornerRadius = 8
            imageView?.clipsToBounds = true
            infoPanel?.addSubview(imageView!)
        }
        
        // Başlık Label'ı
        titleLabel = UILabel(frame: CGRect(x: 120, y: 10, width: 180, height: 30))
        titleLabel?.text = memory.title
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel?.numberOfLines = 1
        infoPanel?.addSubview(titleLabel!)
        
        // Açıklama Label'ı
        descriptionLabel = UILabel(frame: CGRect(x: 120, y: 50, width: 180, height: 60))
        descriptionLabel?.text = memory.description
        descriptionLabel?.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel?.numberOfLines = 0
        infoPanel?.addSubview(descriptionLabel!)
        
        // çarpı butonu
        closeButton = UIButton(frame: CGRect(x: 280, y: 10, width: 30, height: 30))
        closeButton?.setTitle("X", for: .normal)
        closeButton?.setTitleColor(UIColor.red, for: .normal)
        closeButton?.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        closeButton?.addTarget(self, action: #selector(closeInfoPanel), for: .touchUpInside)
        infoPanel?.addSubview(closeButton!)
        
        // silme butonu
        deleteButton = UIButton(frame: CGRect(x: 120, y: 120, width: 100, height: 40))
        deleteButton?.setTitle("Sil", for: .normal)
        deleteButton?.backgroundColor = UIColor.red
        deleteButton?.layer.cornerRadius = 8
        deleteButton?.addTarget(self, action: #selector(deleteMarker), for: .touchUpInside)
        infoPanel?.addSubview(deleteButton!)
        
        // Paneli ekle
        parentViewController?.view.addSubview(infoPanel!)
        
        // Şu anki marker'ı sakla
        self.currentMarker = marker
    }
    
    // info panelini kapatma fonksiyonu
    @objc func closeInfoPanel() {
        infoPanel?.removeFromSuperview()
    }
    
    // marker'ı silme fonksiyonu
    @objc func deleteMarker() {
        // Marker verisini al
        guard let marker = currentMarker, let memory = marker.userData as? Memory else {
            return
        }
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Firestore'dan marker'ı sil
        let memoryRef = firestore.collection("users").document(uid).collection("memories").whereField("latitude", isEqualTo: memory.latitude).whereField("longitude", isEqualTo: memory.longitude)
        
        memoryRef.getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("Firebase'den veri silme hatası: \(error.localizedDescription)")
                return
            }
            
            if let document = snapshot?.documents.first {
                // Belgeyi sil
                document.reference.delete { error in
                    if let error = error {
                        print("Firestore'dan silme başarısız: \(error.localizedDescription)")
                    } else {
                        print("Firestore'dan başarıyla silindi.")
                        
                        // Firebase Storage'dan resmi sil
                        if let imageUrl = document.data()["imageUrl"] as? String {
                            let storageRef = Storage.storage().reference(forURL: imageUrl)
                            storageRef.delete { error in
                                if let error = error {
                                    print("Storage'dan resim silinemedi: \(error.localizedDescription)")
                                } else {
                                    print("Resim başarıyla silindi.")
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Marker'ı haritadan kaldır
        currentMarker?.map = nil
        
        // Info panelini kapat
        closeInfoPanel()
    }
    
    func loadMemories() {
        guard let uid = Auth.auth().currentUser?.uid else { return } // Kullanıcı UID'si al
        
        firestore.collection("users").document(uid).collection("memories").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("Anılar yüklenirken hata oluştu: \(error.localizedDescription)")
                return
            }
            
            guard let self = self, let documents = snapshot?.documents else { return }
            
            for document in documents {
                let data = document.data()
                let title = data["title"] as? String ?? ""
                let description = data["description"] as? String ?? ""
                let latitude = data["latitude"] as? Double ?? 0.0
                let longitude = data["longitude"] as? Double ?? 0.0
                let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
                let imageUrl = data["imageUrl"] as? String
                
                var memory = Memory(title: title, description: description, latitude: latitude, longitude: longitude, date: date, image: nil)
                
                if let imageUrl = imageUrl {
                    // Önce önbelleğe bak
                    if let cachedImage = ImageCacheManager.shared.getImageFromCache(forKey: imageUrl) {
                        // Eğer önbellekte varsa, direkt kullan
                        memory.image = cachedImage
                        self.memories.append(memory)
                        self.addMarkerForMemory(memory)
                    } else {
                        // Eğer önbellekte yoksa, indir ve önbelleğe kaydet
                        let storageRef = Storage.storage().reference(forURL: imageUrl)
                        storageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
                            if let error = error {
                                print("Fotoğraf indirilemedi: \(error.localizedDescription)")
                            } else if let data = data, let image = UIImage(data: data) {
                                // İndirilen görseli önbelleğe kaydediyoruz
                                ImageCacheManager.shared.saveImageToCache(image: image, forKey: imageUrl)
                                memory.image = image
                                self.memories.append(memory)
                                self.addMarkerForMemory(memory)
                            }
                        }
                    }
                } else {
                    // Resim yoksa direkt marker ekliyoruz
                    self.memories.append(memory)
                    self.addMarkerForMemory(memory)
                }
            }
        }
    }
}
