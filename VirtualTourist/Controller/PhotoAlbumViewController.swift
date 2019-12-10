//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Hajar F on 12/5/19.
//  Copyright © 2019 Hajar F. All rights reserved.
//
import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    
    @IBOutlet weak var newCollection: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    
    var pin: Pin!
    var photos = [Photo]()
    var photosToDelete = [Photo]()
    var noImages: UILabel! {
        let ni = UILabel(frame: collectionView.frame)
        ni.text = "No Images"
        ni.textAlignment = .center
        return ni
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.allowsMultipleSelection = true
        setupMapView()
        getPhotos()
        
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
            alert.dismiss(animated: true, completion: nil)
        }))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func getNewCollection(_ sender: Any) {
        newCollection.isEnabled = false
        if photosToDelete.count == 0 {
            for photo in photos {
                CoreDataStack.shared.context.delete(photo)
            }
            
            CoreDataStack.shared.save()
            photos = [Photo]()
            collectionView.reloadData()
            getPhotos()
            newCollection.isEnabled = true
        } else {
            for photo in photosToDelete {
                CoreDataStack.shared.context.delete(photo)
                photos.remove(at: photos.firstIndex(of: photo)!)
            }
           
            newCollection.title = "New Collection"
            newCollection.tintColor = .blue
            photosToDelete = [Photo]()
            CoreDataStack.shared.save()
            collectionView.reloadData()
            newCollection.isEnabled = true
            
        }
        
    }
    
    func updatePhoto() {
        newCollection.title = photosToDelete.count > 0 ? "Delete photos" : "New Collection"
        newCollection.tintColor = photosToDelete.count > 0 ? .red : view.tintColor
        
    }
    
    func getPhotos() {
        if let fetchResult = fetchPhotos() {
            photos = fetchResult
        } else {
           RequestEngine.shared.getPhotos(with: pin.latitude, longitude: pin.longitude) { (photoUrls, error) in
                guard error == nil else {
                    self.showAlert(title: "Error", message: error!)
                    return
                }
                if let photoUrls = photoUrls {
                    if photoUrls.count == 0 {
                        DispatchQueue.main.async {
                            self.collectionView.backgroundView = self.noImages
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.collectionView.backgroundView = nil
                        }
                    }
                    for url in photoUrls {
                        let photo = Photo(context: CoreDataStack.shared.context)
                        photo.url = url
                        photo.pin = self.pin
                        self.photos.append(photo)
                    }
                    
                    CoreDataStack.shared.save()
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                        self.newCollection.isEnabled = true
                    }
                }
            }
        }
    }
    
    func fetchPhotos() -> [Photo]? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        
        do {
            if let result = try CoreDataStack.shared.context.fetch(fetchRequest) as? [Photo] {
                return result.count > 0 ? result : nil
            }
        } catch {
            print("Error getting data")
        }
        return nil
    }
    
    func setupMapView() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2DMake(CLLocationDegrees(pin.latitude), CLLocationDegrees(pin.longitude))
        mapView.addAnnotation(annotation)
        
        let coordinateRegion = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
}

extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CollectionViewCell
        
        let photo = self.photos[indexPath.row]
        
        cell.imageView.image = nil
        cell.activityIndicator.isHidden = false
        cell.contentView.alpha = photosToDelete.contains(photo) ? 0.4 : 1.0
        
        if let imageData = photo.photo {
            let image = UIImage(data: imageData as Data)
            cell.imageView.image = image
            cell.activityIndicator.isHidden = true
        } else {
             cell.activityIndicator.startAnimating()
            RequestEngine.shared.downloadImage(with: photo.url!) { (data, error) in
                if error == nil {
                    let downloadedImage = UIImage(data: data!)
                    photo.photo = data as NSData? as Data?
                    
                    DispatchQueue.main.async {
                        cell.imageView.image = downloadedImage
                        cell.activityIndicator.stopAnimating()
                        cell.activityIndicator.isHidden = true
                    }
                }
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.contentView.alpha = 0.4
        
        let photo = photos[indexPath.row]
        if !photosToDelete.contains(photo) {
            photosToDelete.append(photo)
            newCollection.title = "Delete"
            newCollection.tintColor = .red
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.contentView.alpha = 1.0
        
        let photo = photos[indexPath.row]
        if photosToDelete.contains(photo) {
            if let index = photosToDelete.firstIndex(of: photo) {
                photosToDelete.remove(at: index)
                if photosToDelete.count == 0 {
                    newCollection.title = "New Collection"
                    newCollection.tintColor = .blue
                }
            }
        }
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width / 3 - 10
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 5, left: 5, bottom: 5, right: 5)
    }
}

