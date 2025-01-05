import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class MemoryTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // memories dizisi, tüm verileri saklar
    var memories: [Memory] = []
    
    // UITableView'a bağlanacak IBOutlet
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
            super.viewDidLoad()
            
            // TableView veri kaynağı ve delegate'ini kendisine atıyoruz
            tableView.dataSource = self
            tableView.delegate = self
        
            
            // Firebase'den verileri yükle
            loadMemories()
        }
        
        // Firebase'den anıları yükleyen fonksiyon
        func loadMemories() {
            guard let uid = Auth.auth().currentUser?.uid else { return } // Kullanıcı UID'sini al
            
            // Firestore'dan verileri çekme
            Firestore.firestore().collection("users").document(uid).collection("memories").getDocuments { [weak self] snapshot, error in
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
                        // Önce önbelleğe bakıyoruz
                        if let cachedImage = ImageCacheManager.shared.getImageFromCache(forKey: imageUrl) {
                            memory.image = cachedImage
                            self.memories.append(memory)
                        } else {
                            // Firebase Storage'dan fotoğraf indiriyoruz
                            let storageRef = Storage.storage().reference(forURL: imageUrl)
                            storageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
                                if let error = error {
                                    print("Fotoğraf indirilemedi: \(error.localizedDescription)")
                                } else if let data = data, let image = UIImage(data: data) {
                                    // İndirilen görseli önbelleğe kaydediyoruz
                                    ImageCacheManager.shared.saveImageToCache(image: image, forKey: imageUrl)
                                    memory.image = image
                                    self.memories.append(memory)
                                    
                                    // TableView'i ana thread'de yeniden yükle
                                    DispatchQueue.main.async {
                                        self.tableView.reloadData()
                                    }
                                }
                            }
                        }
                    } else {
                        self.memories.append(memory)
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        }
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return memories.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
            let memory = memories[indexPath.row]
            
            // Başlık ve açıklama yerleştir
            cell.textLabel?.text = memory.title
            cell.detailTextLabel?.text = memory.description
            
            // Resmi yerleştir
            if let image = memory.image {
                cell.imageView?.image = image
            } else {
                cell.imageView?.image = UIImage(named: "placeholderImage")
            }
            
            // Resmin sabit boyutları
            if let imageView = cell.imageView {
                imageView.translatesAutoresizingMaskIntoConstraints = false
                cell.contentView.addSubview(imageView)
                imageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
                imageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
                imageView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 10).isActive = true
                imageView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 15).isActive = true
                imageView.contentMode = .scaleAspectFit
            }
            
            // Başlık ve fotoğraf arasına 5 birimlik boşluk
            if let textLabel = cell.textLabel {
                textLabel.translatesAutoresizingMaskIntoConstraints = false
                cell.contentView.addSubview(textLabel)
                textLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 10).isActive = true
                textLabel.leadingAnchor.constraint(equalTo: cell.imageView!.trailingAnchor, constant: 5).isActive = true
                textLabel.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -15).isActive = true
                textLabel.numberOfLines = 0
                textLabel.lineBreakMode = .byWordWrapping
            }
            
            // Açıklama (detailTextLabel) başlıkla alt alta olacak şekilde konumlandırıyoruz
            if let detailTextLabel = cell.detailTextLabel {
                detailTextLabel.translatesAutoresizingMaskIntoConstraints = false
                cell.contentView.addSubview(detailTextLabel)
                detailTextLabel.topAnchor.constraint(equalTo: cell.textLabel!.bottomAnchor, constant: 5).isActive = true
                detailTextLabel.leadingAnchor.constraint(equalTo: cell.imageView!.trailingAnchor, constant: 5).isActive = true
                detailTextLabel.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -15).isActive = true
                detailTextLabel.numberOfLines = 0
                detailTextLabel.lineBreakMode = .byWordWrapping
            }
            
            return cell
        }
        
        // Hücre yüksekliğini yazının uzunluğuna göre ayarlamak için
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let memory = memories[indexPath.row]
        
        // Yazı uzunluğunu doğru bir şekilde hesaplamak için:
        let font = UIFont.systemFont(ofSize: 14)
        let description = memory.description
        let constraintSize = CGSize(width: tableView.frame.size.width - 40, height: .greatestFiniteMagnitude)
        
        // Yazının uzunluğunu hesapla
        let boundingBox = description.boundingRect(with: constraintSize, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        let textHeight = boundingBox.height
        
        // Fotoğrafın sabit yüksekliği
        let imageHeight: CGFloat = 100
        
        // Boşlukları (padding) ekle
        let padding: CGFloat = 20
        
        // Hücre yüksekliği hesapla:
        // Yazı uzunluğu fotoğraftan küçükse, hücre yüksekliği fotoğraf yüksekliği kadar olacak
        // Eğer yazı uzunluğu daha fazla ise, hücre yüksekliği yazı uzunluğu kadar olacak
        return max(textHeight + padding, imageHeight + padding)
    }

    }
