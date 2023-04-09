//
//  ViewController.swift
//  travelBookTekrar
//
//  Created by ümit yusuf erdem on 12.03.2023.
//

import UIKit
import MapKit // Harita kullanmak için MapKit kütüphanesi kullanılır.
import CoreLocation // Kullanıcı konunumunu almak için CoreLocation kullanılır.
import CoreData // CoreData kütüphanesini ekleyip veri tabanına ulaş.


class ViewController: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate { // mapView'i delege edebilmemiz için MKMapViewDelegate kullanıyoruz.
    
    var locationManager = CLLocationManager() // Kullanıcı konumunu alacak ve işlemler yapacaksak bunu kullanmamız gerekiyor.
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var commentText: UITextField!
    
    var choosenLatitude = Double()
    var choosenLongitude = Double()
    
    var selectedTitle = "" // ListViewController'dan değer gelecek.
    var selectedTitleId : UUID? // ListViewController'dan değer gelecek.
    
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self // mapView delegasyonu viewDidLoad içerisinde yapılır.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest// Konumun verisi ne kadar keskinlikle bulunacak.
        locationManager.requestWhenInUseAuthorization() // Kullanıcıdan izin istememiz gerekiyor. (requestWhenInUseAuthorization) kullanıcı app'i kullanırken izin ver.
        locationManager.startUpdatingLocation() // Kullanıcının yerini almaya başla.
        
        // Uzun basınca (UILongPressGestureRecognizer) tanımlanan bir gestureRegocnizer oluştur.
        let gestureRegocnizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRegocnizer: )))
        gestureRegocnizer.minimumPressDuration = 3 // Kaç saniye basılı tutunca işlem yapılacak.
        mapView.addGestureRecognizer(gestureRegocnizer)
        
        if selectedTitle != "" { // selectedTitle'a boş değer geldiyse.
            
            // ID kullanarak Core Data'dan veri çekme işlemini yap
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate // AppDelegate'i değişken yap.
            let context = appDelegate.persistentContainer.viewContext // Context'i context değişkenine ata.
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places") // Places entitysi içerisinden veri çekmek için fetchRequest değeri tanımla.
            
            
            let idString = selectedTitleId!.uuidString // UUID olarak tanımlanan değeri uuidString'e çevir.
            // id'si idString'e tanımlı olanları çağır.
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString) // predicate ile fitreleme yap.
            fetchRequest.returnsObjectsAsFaults = false // cache'dan değer almaması için returnsObjectsAsFaults'u false olarak tanımla
            
            do {
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        if let title = result.value(forKey: "title") as? String {
                            annotationTitle = title
                            if let subTitle = result.value(forKey: "subtitle") as? String {
                                annotationSubtitle = subTitle
                                if let latitude = result.value(forKey: "latitude") as? Double {
                                    annotationLatitude = latitude
                                    if let longitude = result.value(forKey: "longitude") as? Double {
                                        annotationLongitude = longitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annotation)
                                        nameText.text = annotationTitle
                                        commentText.text = annotationSubtitle
                                        
                                        locationManager.stopUpdatingLocation() // Lokasyon update'i durdur. Seçilen yeri göster.
                                        
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                        
                                    }
                                }
                                
                            }
                            
                        }
 
                
                    }
                }
            } catch {
                print("Error") // bir hata oluşursa konsol'da error yazdır.
            }
            
            
            
        } else {
            // Yeni bir annotation ekle
            
        }
        
    }
    
    @objc func chooseLocation(gestureRegocnizer: UILongPressGestureRecognizer) {
        
        if gestureRegocnizer.state == .began { // Bir dokunma işlemi başladıysa:
            // Dokunulan noktaları al.
            let touchPoint = gestureRegocnizer.location(in: self.mapView)
            
            // dokunulan noktayı koordinata çevir.
            let touchedCoordinates = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            
            choosenLatitude = touchedCoordinates.latitude
            choosenLongitude = touchedCoordinates.longitude
            
            // Pin(Annotation oluşturma.)
            let annotation = MKPointAnnotation()
            
            // Pin'e istediğin koordinatı ver (touchedCoordinates)
            annotation.coordinate = touchedCoordinates
            
            // Pin'e isim ve al başlık ver.
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            
            // Pin'i haritaya ekle
            self.mapView.addAnnotation(annotation)
        }
        
    }
    
    
    
    // Kullanıcının yerini aldığımızda ne yapacağız?
    // Kullanıcının güncellenen konumunu locations: [CLLocation] şeklinde dizi içerisinde veriyor.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle == "" {
            // Enlem ve boylam çizmemiz için gerekli olan obje
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            // locations[0] anlık konumu gösteriyor. Alınan konum locations[] içerisinde bir dizi olarak tanımlanmaktadır.
            
            // Haritada gösterebilmemiz için span adında bir zoom seviyesi belirliyoruz.
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            
            
            // center: nereye merkez alayım. span: ne kadar zoomlayayım.
            let region = MKCoordinateRegion(center: location, span: span)
            
            mapView.setRegion(region, animated: true)
        } else {
            // Birşey yapma
        }
    }
    
    
    // Annotation Özelleştirme metodu
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true // Baloncuk ile birlikte ekstra bilgi gösterebildiğimiz yer (.canShowCallout)
            pinView?.tintColor = UIColor.blue
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure) // Detay gösterme butonu
            pinView?.rightCalloutAccessoryView = button // Sağ tarafında gösterecek görünümde bu button'u göster.
        } else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    
    // Navigasyon Göster. infoButton'a tıklandığını algıla.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != "" {
            
            // Gitmek istediğin yeri gösteren bir obje ekle.
            var requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarks, error in
                // Closure
                
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        let  launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                
                }
                
            }
        }
    }
    
    
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        // into: context : Hangi contexte koyalım.
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle")
        newPlace.setValue(choosenLatitude, forKey: "latitude")
        newPlace.setValue(choosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do {
            try context.save()
            print("Success")
        } catch {
            print("Error")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil) // BütünApp'e bir mesaj gönderiyor.
        navigationController?.popViewController(animated: true) // Bir önceki VC'ye geri götür.
        
    }
    

}

