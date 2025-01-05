//
//  ImageCacheManager.swift
//  Story Map
//
//  Created by Turgut Eren Aksu on 29.12.2024.
//


import UIKit

class ImageCacheManager {
    
    // Singleton örneği (tekil kullanım)
    static let shared = ImageCacheManager()
    
    private var imageCache = NSCache<NSString, UIImage>()
    
    // Görseli önbelleğe kaydetme
    func saveImageToCache(image: UIImage, forKey key: String) {
        imageCache.setObject(image, forKey: key as NSString)
    }
    
    // Anahtara göre görseli önbellekten alma
    func getImageFromCache(forKey key: String) -> UIImage? {
        return imageCache.object(forKey: key as NSString)
    }
    
    // Önbelleği temizleme
    func clearCache() {
        imageCache.removeAllObjects()
    }
}
