//
//  CustomTableViewCell.swift
//  MyPlaces
//
//  Created by Ivan Abramov on 12/01/2020.
//  Copyright © 2020 Ivan Abramov. All rights reserved.
//

import UIKit

class CustomTableViewCell: UITableViewCell {

    @IBOutlet var imageOfPlace: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var typeLabel: UILabel!
    @IBOutlet var buttons: [UIButton]!

}
