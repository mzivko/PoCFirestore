import UIKit
import Firebase

class GroceryListTableViewController: UITableViewController {
    
    // MARK: Constants
    let listToUsers = "ListToUsers"
    
    // MARK: Properties
    var items: [GroceryItem] = []
    var user: User!
    
    //defining firebase property
    let ref = Database.database().reference(withPath: "grocery-items")
    var refFirestore: DocumentReference? = nil
    
    let delegate = UIApplication.shared.delegate as! AppDelegate
    var dbFirestore: Firestore?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: UIViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dbFirestore = delegate.db
        
        tableView.allowsMultipleSelectionDuringEditing = false
        
        user = User(uid: "FakeId", email: "testEmail@gmail.com")
        
        ref.queryOrdered(byChild: "completed").observe(.value, with: { snapshot in
            
            //just printing the snapshot data
            print(snapshot.value as Any)
            
            var newItems: [GroceryItem] = []
            
            for child in snapshot.children{
                if let snapshot = child as? DataSnapshot,
                    let groceryItem = GroceryItem(snapshot: snapshot){
                    newItems.append(groceryItem)
                }
            }
            self.items = newItems
            self.tableView.reloadData()
        })
    }
    
    // MARK: UITableView Delegate methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
        let groceryItem = items[indexPath.row]
        
        cell.textLabel?.text = groceryItem.name
        cell.detailTextLabel?.text = groceryItem.addedByUser
        
        toggleCellCheckbox(cell, isCompleted: groceryItem.completed)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            //deleting from RTDB
            let groceryItem = items[indexPath.row]
            groceryItem.ref?.removeValue()

            //deleting from Firestore DB
            dbFirestore?.collection("groceryList").whereField("item", isEqualTo: groceryItem.name.lowercased()).getDocuments(completion: { (querySnapshot, error) in
                
                if error != nil{
                    print("Error: \(error)")
                }else{
                    for document in querySnapshot!.documents{
                        document.reference.delete()
                    }
                    print("Document sucessfully removed! \(groceryItem.name)")
                }
                
            })
            
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        
        
//        var groceryItem = items[indexPath.row]
        let groceryItem = items[indexPath.row]
//        let toggledCompletion = !groceryItem.completed
        let toggledCompletion = !groceryItem.completed
//        toggleCellCheckbox(cell, isCompleted: toggledCompletion)
        toggleCellCheckbox(cell, isCompleted: toggledCompletion)
//        groceryItem.completed = toggledCompletion
        groceryItem.ref?.updateChildValues([
            "completed" : toggledCompletion
            ])
//        tableView.reloadData()
    }
    
    func toggleCellCheckbox(_ cell: UITableViewCell, isCompleted: Bool) {
        if !isCompleted {
            cell.accessoryType = .none
            cell.textLabel?.textColor = .black
            cell.detailTextLabel?.textColor = .black
        } else {
            cell.accessoryType = .checkmark
            cell.textLabel?.textColor = .gray
            cell.detailTextLabel?.textColor = .gray
        }
    }
    
    // MARK: Add Item
    
    @IBAction func addButtonDidTouch(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Grocery Item",
                                      message: "Add an Item",
                                      preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
//            let textField = alert.textFields![0]
//
//            let groceryItem = GroceryItem(name: textField.text!,
//                                          addedByUser: self.user.email,
//                                          completed: false)
//
//            self.items.append(groceryItem)
//            self.tableView.reloadData()
            
           
            
            
            //saving to cloud database
            guard let textField = alert.textFields?.first,
                let text = textField.text else {  return }
            
            let groceryItem = GroceryItem(name: text, addedByUser: self.user.email, completed: false)
            
            let groceryItemRef = self.ref.child(text.lowercased())
            
            groceryItemRef.setValue(groceryItem.toAnyObject())
            
            //saving to firestore databse
            self.refFirestore = self.dbFirestore?.collection("groceryList").addDocument(data: [
                "item": "\(text.lowercased())"
            ]){ err in
                if let err = err{
                    print("Error adding document: \(err)")
                }else{
                    print("Document added with ID: \(self.refFirestore!.documentID)")
                }
                
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel)
        
        alert.addTextField()
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
}
