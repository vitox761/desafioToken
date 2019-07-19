//
//  CollectionViewController.swift
//  MovieLibrary
//
//  Created by Victor on 18/07/19.
//  Copyright © 2019 Victor. All rights reserved.
//

import UIKit

class CollectionViewController: UIViewController {

    @IBOutlet weak var posterImage: UIImageView!
    @IBOutlet weak var collectionLabel: UILabel!
    @IBOutlet weak var backdropImage: UIImageView!
    
    var collectionInfo : [String:Any]?
    let indicator:UIActivityIndicatorView = UIActivityIndicatorView  (style: UIActivityIndicatorView.Style.gray)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        startLoader()
        
        for (key,value) in self.collectionInfo! {
            if key == "name" {
                collectionLabel.text = value as? String
                }
            if key == "poster_url" {
                if let url = URL(string:(value as? String)!) {
                    if let data = try? Data(contentsOf: url) {
                        let imageData = data
                        let image = UIImage(data: imageData)
                        self.posterImage.image = image
                    }
                }
            }
            if key == "backdrop_url"{
                if let url = URL(string:(value as? String)!) {
                    if let data = try? Data(contentsOf: url) {
                        let imageData = data
                        let image = UIImage(data: imageData)
                        self.backdropImage.image = image
                    }
                }
            }
        }
        stopLoader()
    }
    
    func startLoader(){
        indicator.color = UIColor .magenta
        indicator.frame = CGRect(x:0.0, y:0.0, width:10.0, height:10.0)
        indicator.center = self.view.center
        self.view.addSubview(indicator)
        indicator.bringSubviewToFront(self.view)
        indicator.startAnimating()
    }
    
    func stopLoader(){
        self.indicator.stopAnimating()
        self.indicator.hidesWhenStopped = true
    }

}
