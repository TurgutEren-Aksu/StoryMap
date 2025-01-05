//
//  ViewController.swift
//  HaritaDeneme
//
//  Created by Turgut Eren Aksu on 21.12.2024.
//

import UIKit
import GoogleMaps
import GooglePlaces


class ViewController: UIViewController {
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var mapManager: MapManager!
    var searchBarManager: SearchBarManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // searchBar Görünüm ayarları
        searchBar.layer.cornerRadius = 10
        searchBar.layer.masksToBounds = true
        searchBar.backgroundImage = UIImage()
        searchBar.layer.borderWidth = 0
        searchBar.layer.borderColor = UIColor.clear.cgColor
        searchBar.backgroundColor = .systemBlue
        searchBar.layer.cornerRadius = 10
        searchBar.layer.masksToBounds = true
        
        
        // mapManager başladığı yer
        mapManager = MapManager(mapView: mapView, parentViewController: self)
        
        
        // searchBarın başladığı yer
        searchBarManager = SearchBarManager(mapView: mapView, parentViewController: self, tableView: tableView)
        searchBarManager.attach(to: searchBar)
        mapManager.loadMemories()
        
        // tableView ayarları
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SuggestionCell")
        
        
    }
    
    @IBAction func userProfileButton(_ sender: UIButton) {
        // ekranın storyBoard idsine göre geçiş yapıyor
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let mainVC = storyboard.instantiateViewController(withIdentifier: "UserProfileViewController") as? UserProfileViewController {
            
            self.present(mainVC, animated: true, completion: nil)
        }
        
    }
    @IBAction func goToListView(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let memoryVC = storyboard.instantiateViewController(withIdentifier: "MemoryTableViewController") as? MemoryTableViewController {
            
            self.present(memoryVC, animated: true, completion: nil)
        }
    }
}

