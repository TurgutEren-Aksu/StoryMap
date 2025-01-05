//
//  SearchBarManager.swift
//  HaritaDeneme
//
//  Created by Turgut Eren Aksu on 25.12.2024.
//
import UIKit
import GooglePlaces
import GoogleMaps

class SearchBarManager: NSObject, UISearchBarDelegate,UITableViewDataSource, UITableViewDelegate {
    private let placesClient = GMSPlacesClient.shared()
    private weak var mapView: GMSMapView!
    private weak var parentViewController: UIViewController!
    private weak var tableView: UITableView!
    private var predictions: [GMSAutocompletePrediction] = []
    
    init(mapView: GMSMapView, parentViewController: UIViewController,tableView: UITableView) {
        super.init()
        self.mapView = mapView
        self.parentViewController = parentViewController
        self.tableView = tableView
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.isHidden = true
    }
    
    func attach(to searchBar: UISearchBar) {
        searchBar.delegate = self
        styleSearchBar(searchBar)
    }

    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard !searchText.isEmpty else {
            predictions.removeAll()
            tableView.reloadData()
            
            // TableView'ı yumuşak bir şekilde gizleme
            UIView.animate(withDuration: 0.3) {
                self.tableView.alpha = 0.0
            } completion: { _ in
                self.tableView.isHidden = true
                self.tableView.alpha = 1.0
            }
            return
        }

        // Google Places API ile arama kısmı
        let filter = GMSAutocompleteFilter()
        filter.type = .establishment // mekan araması için
        placesClient.findAutocompletePredictions(fromQuery: searchText, filter: filter, sessionToken: nil) { [weak self] results, error in
            guard let self = self else { return }

            if let error = error {
                print("Arama sırasında hata oluştu: \(error.localizedDescription)")
                return
            }

            guard let results = results else {
                print("Sonuç bulunamadı.")
                return
            }

            self.predictions = results
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }


       // tableview datasource ve delegate metodları
       func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
           return predictions.count
       }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SuggestionCell", for: indexPath)
        let prediction = predictions[indexPath.row]

        // Başlık
        cell.textLabel?.text = prediction.attributedPrimaryText.string
        
        // Alt başlık ekleme (eğer varsa)
        if let secondaryText = prediction.attributedSecondaryText?.string {
            cell.detailTextLabel?.text = secondaryText
        }

        // Öneri simgesi eklemek (isteğe bağlı)
        cell.imageView?.image = UIImage(systemName: "magnifyingglass")  // Örnek simge

        return cell
    }


    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let prediction = predictions[indexPath.row]

        // kullanıcının seçtiği yeri alıp kamerayı oraya odaklıyor
        placesClient.fetchPlace(fromPlaceID: prediction.placeID, placeFields: .coordinate, sessionToken: nil) { [weak self] place, error in
            if let error = error {
                print("Yer detayı alınamadı: \(error.localizedDescription)")
                return
            }

            guard let place = place else {
                print("Yer bulunamadı.")
                return
            }

            // Kamerayı o anki mekana odaklıyor
            let camera = GMSCameraPosition.camera(withLatitude: place.coordinate.latitude, longitude: place.coordinate.longitude, zoom: 15)
            self?.mapView.animate(to: camera)

            // Marker ekle
            let marker = GMSMarker()
            marker.position = place.coordinate
            marker.title = prediction.attributedPrimaryText.string
            marker.map = self?.mapView

            // Marker'ı 5 saniye sonra kaldır
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                marker.map = nil
            }

            // TableView'ı yumuşak bir şekilde gizleme
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.3) {
                    self?.tableView.alpha = 0.0
                } completion: { _ in
                    self?.tableView.isHidden = true
                    self?.tableView.alpha = 1.0
                }
            }
        }
    }

    func styleSearchBar(_ searchBar: UISearchBar) {
        // Text field için stil ayarları
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = .white
            textField.layer.cornerRadius = 15
            textField.layer.masksToBounds = true
            textField.layer.borderWidth = 1
            textField.layer.borderColor = UIColor.lightGray.cgColor
            textField.font = UIFont.systemFont(ofSize: 16)
            textField.textColor = .black
            textField.attributedPlaceholder = NSAttributedString(string: "Arama yap", attributes: [
                .foregroundColor: UIColor.darkGray
            ])
            
            // Arama ikonunun rengini değiştirme
            if let leftView = textField.leftView as? UIImageView {
                leftView.tintColor = .systemGray
            }
        }
        
        // SearchBar dış görünüm
        searchBar.layer.cornerRadius = 15
        searchBar.layer.masksToBounds = true
        searchBar.layer.borderWidth = 1
        searchBar.layer.borderColor = UIColor.lightGray.cgColor
        searchBar.layer.shadowColor = UIColor.black.cgColor
        searchBar.layer.shadowOffset = CGSize(width: 0, height: 2)
        searchBar.layer.shadowOpacity = 0.1
        searchBar.layer.shadowRadius = 5
    }

   }
