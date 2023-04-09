//
//  ListViewController.swift
//  travelBookTekrar
//
//  Created by ümit yusuf erdem on 12.03.2023.
//

import UIKit
import CoreData

class ListViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    
    @IBOutlet weak var tableView: UITableView!
    
    var titleArray = [String]()
    var idArray = [UUID]()
    
    var chosenTitle = "" // Seçilen başlık tanımla
    var chosenTitleId : UUID? // Seçilen başlık id si tanımla
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonClicked))

        tableView.delegate = self // tableView delegasyonlarını self ile sayfaya bağla.
        tableView.dataSource = self // tableView dataSource'u self ile sayfaya bağla.
        
        getData() // getData fonksiyonunu viewDidLoad içerisinde çalıştır.
        
    }
    
    override func viewWillAppear(_ animated: Bool) { // Uygulama açılmadan önce sayfayı hazırla.
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name(rawValue: "newPlace"), object: nil)
        // NotificationCenter ile tüm App içerisine bir mesaj gönder (newPlace)
    }
    
    @objc func getData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate // AppDelegate'i değişken olarak tanımla.
        let context = appDelegate.persistentContainer.viewContext // viewContext'i değişken olarak tanımla.
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Places") // kaydedilen veri tabanından veri çekmek için fetchRequest'i kullan
        request.returnsObjectsAsFaults = false // Cache'den veri okumaması için returnObjectsAsFaults'u false yap.
        
        
        do {
            let results = try context.fetch(request) // context.fetch(request) ile Places context'i içerisinden veri çekmeyi dene.
            if results.count > 0 { // Eğer results değişkeni 0'dan büyükse yani gelen veri varsa:
                
                
                // Verileri temizle
                self.titleArray.removeAll(keepingCapacity: false) // titleArray içerisindeki verileri sil.
                self.idArray.removeAll(keepingCapacity: false) // idArray içerisindeki verileri sil.
                
                
                
                for result in results as! [NSManagedObject] { // results içerisindeki verileri result değer ile döndür ve sırasıyla al.
                    if let title = result.value(forKey: "title") as? String { // key value yapısındaki key kısmında gelen veri String değerde ise
                        // title değerini bu gelen değere ata.
                        self.titleArray.append(title) // daha sonra titleArray içerisine bu title değerine tanımlanana değerleri sırasıyla ekle.
                    }
                    
                    if let id = result.value(forKey: "id") as? UUID { // key value içerisinde Places değerlerinde id key'ine sahip olan değer UUID değerinde bir değişken ise id adında bir değişken oluştur.
                        self.idArray.append(id) // daha sonra bu id değerini idArray içerisine ekle.
                    }
                    
                    
                    // Gelen verileri tableView'de görüntüle.  
                    tableView.reloadData()
                }
            }
            
        } catch {
            print("Error")
        }
        
        
    }
    
    @objc func addButtonClicked(){ // addButton'a basınca performSegue ile diğer VC'ye geç ve karşı tarafa gönderilecek chosenTitle değerini boş at.
        chosenTitle = "" // chosenTitle değer içermiyorsa.
        performSegue(withIdentifier: "toViewController", sender: nil) // toViewController seguesini çalıştır.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { // kaç tane satır olsun?
        return titleArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { // tableView üzerinde hangi değerler yazsın.
        let cell = UITableViewCell()
        cell.textLabel?.text = titleArray[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { // tableViewCell lere tıklanınca ne yapsın.
        chosenTitle = titleArray[indexPath.row] // tableView üzerinden seçilen ilgili satırın başlığını al
        chosenTitleId = idArray[indexPath.row] // tableView üzerinden seçilen ilgili satırın id'sini al.
        performSegue(withIdentifier: "toViewController", sender: nil) // viewController'a git.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) { // prepare for segue ile diğer VC'lere ulaş ve oraya değer gönder.
        if segue.identifier == "toViewController" {
            let destinationVC = segue.destination as! ViewController // destinationVC'yi viewController'a tanımla
            destinationVC.selectedTitle = chosenTitle // viewController'a ulaş ve oradaki chosenTitle değerini selectedTitle'a eşitle
            destinationVC.selectedTitleId = chosenTitleId // viewController'a ulaş ve oradaki chosenTitleId değerini selectedTitleId'ye eşitle
        }
    }
    


}
