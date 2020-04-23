//
//  MainViewController.swift
//  MyPlaces
//
//  Created by Ivan Abramov on 09/12/2019.
//  Copyright © 2019 Ivan Abramov. All rights reserved.
//

import UIKit
import RealmSwift

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var places: Results<Place>!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var sortRows: UIBarButtonItem!
    @IBOutlet weak var segment: UISegmentedControl!
    var order : Bool = false
    let searchController = UISearchController(searchResultsController: nil)
    var filteredPlaces : [Place] = []
    
    var  isSearchEmpty : Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    var  isFiltering : Bool {
        return searchController.isActive && !isSearchEmpty
    }
    
    @IBAction func segmentedControl(_ sender: UISegmentedControl) {
        sortObjects(sender.selectedSegmentIndex)
    }
    
    @IBAction func selectOrder(_ sender: UIBarButtonItem) {
        order.toggle()
        if order {
            sortRows.image = #imageLiteral(resourceName: "ZA")
        }
        else {
            sortRows.image = #imageLiteral(resourceName: "AZ")
        }
        
        sortObjects(segment.selectedSegmentIndex)
    }
    
    func sortObjects(_ index : Int) {
        if index == 0 {
            places = places.sorted(byKeyPath: "rating", ascending: order)
        }
        else {
            places = places.sorted(byKeyPath: "name", ascending: !order)
        }
        
        tableView.reloadData()
    }
       
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sortRows.image = #imageLiteral(resourceName: "AZ")
        places = realm.objects(Place.self).sorted(byKeyPath: "rating", ascending: false)
        searchController.searchResultsUpdater = self
        // 2
        searchController.obscuresBackgroundDuringPresentation = false
        // 3
        searchController.searchBar.placeholder = "Search"
        // 4
        navigationItem.searchController = searchController
        // 5
        definesPresentationContext = true
        
        segment.selectedSegmentTintColor = #colorLiteral(red: 0, green: 0.4710169435, blue: 1, alpha: 1)
        //segment.tintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        segment.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        segment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.systemBlue], for: .normal)
        segment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .selected)
    }
    

    func setRating(_ cell: CustomTableViewCell, _ index : Int) {
             let image = UIImage(systemName: "star.fill")
             let image2 = UIImage(systemName: "star")
             
             for i in  1...index {
                cell.buttons[i - 1].setImage(image, for: .normal)
             }
             
             if index + 1 <= 5 {
                 for i in (index + 1)...5 {
                    cell.buttons[i - 1].setImage(image2, for: .normal)
                 }
             }
    }
    

    // MARK: - Table view data source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isFiltering ? filteredPlaces.count : places.count
        //return places.isEmpty ? 0 : places.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomTableViewCell
        
        let place = isFiltering ? filteredPlaces[indexPath.row] : places[indexPath.row]
        //let place = places[indexPath.row]
        
        cell.nameLabel.text = place.name
        cell.locationLabel.text = place.location
        cell.typeLabel.text = place.type
        cell.imageOfPlace.image = UIImage(data: place.imageData!)
        
        cell.imageOfPlace.layer.cornerRadius = cell.imageOfPlace.frame.size.height / 2
        cell.imageOfPlace.clipsToBounds = true
        setRating(cell, place.rating)
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let place = places[indexPath.row]
        let deleteAction = UIContextualAction(style: .normal, title: "Delete") { (_, _, _) in
            StorageManager.deleteObject(place)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
//        let editAction = UIContextualAction(style: .normal, title: "Delete") { (_, _, _) in
//                   StorageManager.deleteObject(place)
//                   tableView.deleteRows(at: [indexPath], with: .automatic)
//               }
        
        deleteAction.backgroundColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
        //editAction.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        
        let actions = UISwipeActionsConfiguration(actions: [deleteAction])
        return actions
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            guard let indexPath = tableView.indexPathForSelectedRow else { return }
            let place = isFiltering ? filteredPlaces[indexPath.row] : places[indexPath.row]
            let newPlaceVC = segue.destination as! NewPlaceViewController
            newPlaceVC.currentPlace = place
        }
    }
    
    @IBAction func unwindSegue(_ segue: UIStoryboardSegue) {
        
        guard let newPlaceVC = segue.source as? NewPlaceViewController else { return }
        
        newPlaceVC.savePlace()
        tableView.reloadData()
    }
    
    func filterContentForSearchText(_ searchText: String) {
      filteredPlaces = places.filter { (place: Place) -> Bool in
        return place.name.lowercased().contains(searchText.lowercased()) || place.location?.lowercased().contains(searchText.lowercased()) ?? false ||
            place.type?.lowercased().contains(searchText.lowercased()) ?? false
      }
      
      tableView.reloadData()
    }

}

extension MainViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    let searchBar = searchController.searchBar
    filterContentForSearchText(searchBar.text!)
  }
}
