//
//  MovieDetails.swift
//  MovieLibrary
//
//  Created by Victor on 19/07/19.
//  Copyright © 2019 Victor. All rights reserved.
//

import Foundation


struct movieDetails {
    var id : Int = 0
    var voteAverage : Double = 0.0
    var numVotes : Int = 0
    var runtime : Int = 0
    var status : String = ""
    var title : String = ""
    var originalTitle : String = ""
    var backdropURL : String = ""
    var genres : String = ""
    var releaseDate : String = ""
    var overview : String = ""
    var adult : Bool = false
    var homepage : String = ""
    var imdbPage : String = ""
    var popularity : Double = 0.0
    var tagline : String = ""
    var budget : Int = 0
    var revenue : Int = 0
    var spokenLanguages : String = ""
    var countries : String = ""
    var collectionInfo : [String:Any] = ["":""]
}
