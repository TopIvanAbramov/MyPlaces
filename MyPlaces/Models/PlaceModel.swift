//
//  PlaceModel.swift
//  MyPlaces
//
//  Created by Ivan Abramov on 12/01/2020.
//  Copyright © 2020 Ivan Abramov. All rights reserved.
//

import RealmSwift

class Place: Object {
    
    @objc dynamic var name = ""
    @objc dynamic var location: String?
    @objc dynamic var type: String?
    @objc dynamic var imageData: Data?
    @objc dynamic var rating: Int = 0
    
    convenience init(name: String, location: String?, type: String?, imageData: Data?, rating: Int) {
        self.init()
        self.name = name
        self.location = location
        self.type = type
        self.imageData = imageData
        self.rating = rating
    }
}
