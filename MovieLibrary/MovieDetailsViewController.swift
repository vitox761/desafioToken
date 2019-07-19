//
//  MovieDetailsViewController.swift
//  MovieLibrary
//
//  Created by Victor on 18/07/19.
//  Copyright © 2019 Victor. All rights reserved.
//

import UIKit
import Alamofire
import CoreData

class MovieDetailsViewController: UIViewController {

    // Outlets
    @IBOutlet weak var movieTitle: UILabel!
    @IBOutlet weak var originalTitle: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var runtimeLabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var overviewLabel: UILabel!
    @IBOutlet weak var genresLabel: UILabel!
    @IBOutlet weak var homepageLabel: UITextView!
    @IBOutlet weak var imdbPageLabel: UITextView!
    @IBOutlet weak var popularityLabel: UILabel!
    @IBOutlet weak var taglineLabel: UILabel!
    @IBOutlet weak var budgetLabel: UILabel!
    @IBOutlet weak var languagesLabel: UILabel!
    @IBOutlet weak var countriesLabel: UILabel!
    @IBOutlet weak var backdropImage: UIImageView!
    @IBOutlet weak var CollectionInfoButton: UIButton!
    
    
    let indicator:UIActivityIndicatorView = UIActivityIndicatorView  (style: UIActivityIndicatorView.Style.gray)
    var aux = movieDetails()
    var id : Int = 0
    // Cache
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewWillAppear(_ animated: Bool) {
        startLoader()
        
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "MovieDetails")
        request.returnsObjectsAsFaults = false
        
        do {
            // Check core data
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
                // Populate movie details from the core data
                if let id = data.value(forKey: "id") as? Int {
                    if id == self.id {
                        self.aux.id = id
                        if let voteAverage = data.value(forKey: "voteAverage") as? Double {
                            self.aux.voteAverage = voteAverage
                        }
                        if let numVotes = data.value(forKey: "numVotes") as? Int {
                            self.aux.numVotes = numVotes
                        }
                        if let runtime = data.value(forKey: "runtime") as? Int {
                            self.aux.runtime = runtime
                        }
                        if let status = data.value(forKey: "status") as? String {
                            self.aux.status = status
                        }
                        if let title = data.value(forKey: "title") as? String {
                            self.aux.title = title
                        }
                        if let originalTitle = data.value(forKey: "originalTitle") as? String {
                            self.aux.originalTitle = originalTitle
                        }
                        if let backdropURL = data.value(forKey: "backdropURL") as? String {
                            self.aux.backdropURL = backdropURL
                        }
                        if let genres = data.value(forKey: "genres") as? String {
                            self.aux.genres = genres
                        }
                        if let release = data.value(forKey: "releaseDate") as? String {
                            self.aux.releaseDate = release
                        }
                        if let overview = data.value(forKey: "overview") as? String {
                            self.aux.overview = overview
                        }
                        if let adult = data.value(forKey: "adult") as? Bool {
                            self.aux.adult = adult
                        }
                        if let budget = data.value(forKey: "budget") as? Int {
                            self.aux.budget = budget
                        }
                        if let revenue = data.value(forKey: "revenue") as? Int {
                            self.aux.revenue = revenue
                        }
                        if let homepage = data.value(forKey: "homepage") as? String {
                            self.aux.homepage = homepage
                        }
                        if let imdbPage = data.value(forKey: "imdbPage") as? String {
                            self.aux.imdbPage = imdbPage
                        }
                        if let popularity = data.value(forKey: "popularity") as? Double {
                            self.aux.popularity = popularity
                        }
                        if let tagline = data.value(forKey: "tagline") as? String {
                            self.aux.tagline = tagline
                        }
                        if let spokenLanguages = data.value(forKey: "spokenLanguages") as? String {
                            self.aux.spokenLanguages = spokenLanguages
                        }
                        if let countries = data.value(forKey: "countries") as? String {
                            self.aux.countries = countries
                        }
                        if let collectionName = data.value(forKey: "collectionName") as? String {
                            self.aux.collectionInfo.updateValue(collectionName, forKey: "name")
                        }
                        if let collectionPoster = data.value(forKey: "collectionPoster") as? String {
                            self.aux.collectionInfo.updateValue(collectionPoster, forKey: "poster_url")
                        }
                        if let collectionBack = data.value(forKey: "collectionBack") as? String {
                            self.aux.collectionInfo.updateValue(collectionBack, forKey: "backdrop_url")
                        }
                    }
                }
            }
            if self.aux.id == 0 {
                // Download from server
                getInfoFromServer()
            }
            populateView()
            stopLoader()
        } catch {
            // failed core data
        }
    }
    
    override func viewDidLoad()  {
        super.viewDidLoad()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if  segue.identifier == "ShowCollectionInfo",
            let destination = segue.destination as? CollectionViewController {
            destination.collectionInfo = aux.collectionInfo
        }
    }
    
    func performRequest(completionHandler: @escaping ([String:Any]?, Error?) -> Void) {
            let url = "https://desafio-mobile.nyc3.digitaloceanspaces.com/movies/" + String(self.id)
        Alamofire.request(url).responseJSON { response in
            switch response.result {
            case .failure(let error):
                completionHandler(nil, error)
            case .success(let responseObject):
                let dictionary = responseObject as? [String: Any]
                completionHandler(dictionary, nil)
            }
        }
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
    
    func getInfoFromServer(){
        let context = appDelegate.persistentContainer.viewContext
        performRequest() { dictionary, error in
            guard let dictionary = dictionary, error == nil else {
                self.stopLoader()
                self.noInternet()
                return
            }
            let entity = NSEntityDescription.entity(forEntityName: "MovieDetails", in: context)
            let newEntry = NSManagedObject(entity: entity!, insertInto: context)
            
            if let id = dictionary["id"] as? Int {
                newEntry.setValue(id, forKey: "id")
                self.aux.id = id
            }
            if let voteAverage = dictionary["vote_average"] as? Double {
                newEntry.setValue(voteAverage, forKey: "voteAverage")
                self.aux.voteAverage = voteAverage
            }
            if let numVotes = dictionary["vote_count"] as? Int {
                newEntry.setValue(numVotes, forKey: "numVotes")
                self.aux.numVotes = numVotes
            }
            if let runtime = dictionary["runtime"] as? Int {
                newEntry.setValue(runtime, forKey: "runtime")
                self.aux.runtime = runtime
            }
            if let status = dictionary["status"] as? String {
                newEntry.setValue(status, forKey: "status")
                self.aux.status = status
            }
            if let title = dictionary["title"] as? String {
                newEntry.setValue(title, forKey: "title")
                self.aux.title = title
            }
            if let originalTitle = dictionary["original_title"] as? String {
                newEntry.setValue(originalTitle, forKey: "originalTitle")
                self.aux.originalTitle = originalTitle
            }
            if let backdropURL = dictionary["backdrop_url"] as? String {
                newEntry.setValue(backdropURL, forKey: "backdropURL")
                self.aux.backdropURL = backdropURL
            }
            if let genres = dictionary["genres"] as? [String] {
                var genreList: String = ""
                for item in genres {
                    genreList.append(item)
                    genreList.append(",")
                }
                genreList.removeLast()
                
                newEntry.setValue(genreList, forKey: "genres")
                self.aux.genres = genreList
            }
            if let releaseDate = dictionary["release_date"] as? String {
                newEntry.setValue(releaseDate, forKey: "releaseDate")
                self.aux.releaseDate = releaseDate
            }
            if let overview = dictionary["overview"] as? String {
                newEntry.setValue(overview, forKey: "overview")
                self.aux.overview = overview
            }
            if let adult = dictionary["adult"] as? Bool {
                newEntry.setValue(adult, forKey: "adult")
                self.aux.adult = adult
            }
            if let budget = dictionary["budget"] as? Int {
                newEntry.setValue(budget, forKey: "budget")
                self.aux.budget = budget
            }
            if let revenue = dictionary["revenue"] as? Int {
                newEntry.setValue(revenue, forKey: "revenue")
                self.aux.revenue = revenue
            }
            if let homepage = dictionary["homepage"] as? String {
                newEntry.setValue(homepage, forKey: "homepage")
                self.aux.homepage = homepage
            }
            if let imdbPage = dictionary["imdb_id"] as? String {
                newEntry.setValue(imdbPage, forKey: "imdbPage")
                self.aux.imdbPage = imdbPage
            }
            if let popularity = dictionary["popularity"] as? Double {
                newEntry.setValue(popularity, forKey: "popularity")
                self.aux.popularity = popularity
            }
            if let tagline = dictionary["tagline"] as? String {
                newEntry.setValue(tagline, forKey: "tagline")
                self.aux.tagline = tagline
            }
            if let spokenLanguages = dictionary["spoken_languages"] as? [[String:Any]] {
                var languages = "Languages: "
                for item in spokenLanguages {
                    for (key,value) in item {
                        if key == "name" {
                            languages.append((value as? String)!)
                            languages.append(", ")
                        }
                    }
                }
                languages.removeLast()
                languages.removeLast()
                
                newEntry.setValue(languages, forKey: "spokenLanguages")
                self.aux.spokenLanguages = languages
            }
            if let collection = dictionary["belongs_to_collection"] as? [String:Any] {
                for (key,value) in collection {
                    if key == "name" {
                        newEntry.setValue(value, forKey: "collectionName")
                    }
                    if key == "poster_url" {
                        newEntry.setValue(value, forKey: "collectionPoster")
                    }
                    if key == "backdrop_url" {
                        newEntry.setValue(value, forKey: "collectionBack")
                    }
                }
                self.aux.collectionInfo = collection
            }
            if let countries = dictionary["production_countries"] as? [[String:Any]] {
                
                var countriesList = "Produced in: "
                for item in countries {
                    for (key,value) in item {
                        if key == "name" {
                            countriesList.append((value as? String)!)
                            countriesList.append(", ")
                        }
                    }
                }
                countriesList.removeLast()
                countriesList.removeLast()
                
                newEntry.setValue(countriesList, forKey: "countries")
                self.aux.countries = countriesList
            }
            self.populateView()
            self.stopLoader()
            // Save to core data
            do {
                try context.save()
            } catch {
                print("Failed saving")
            }
        }
    }
    
    func noInternet(){
        self.runtimeLabel.text = " No Internet "
        self.movieTitle.text = ""
        self.originalTitle.text = ""
        self.statusLabel.text = ""
        self.pointsLabel.text = ""
        self.overviewLabel.text = ""
        self.languagesLabel.text = ""
        self.genresLabel.text = ""
        self.popularityLabel.text = ""
        self.countriesLabel.text = ""
        self.taglineLabel.text = ""
        self.budgetLabel.text = ""
        self.imdbPageLabel.text = ""
        self.homepageLabel.text = ""
    }
    
    func populateView() {
        // Converting date
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd"
        
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "dd/MM/yyyy"
        
        if self.aux.collectionInfo.count == 1 {
            self.CollectionInfoButton.isHidden = true
        }
        
        self.movieTitle.text = self.aux.title
        self.originalTitle.text = self.aux.originalTitle
        if let date = dateFormatterGet.date(from: self.aux.releaseDate) {
            self.statusLabel.text = self.aux.status + ": " + dateFormatterPrint.string(from: date)
        }
        self.runtimeLabel.text = "Runtime: " + String(self.aux.runtime) + " minutes"
        self.pointsLabel.text = "Vote average: " + String(self.aux.voteAverage) + " | " + String(self.aux.numVotes) + " votes"
        self.overviewLabel.text = self.aux.overview
        self.budgetLabel.text = "Budget: U$" + String(self.aux.budget) + " | Revenue: U$" + String(self.aux.revenue)
        self.homepageLabel.isEditable = false
        
        if self.aux.homepage == "" {
            self.homepageLabel.text = ""
        }
        else {
            let attributedString = NSMutableAttributedString(string: "Homepage")
            attributedString.addAttribute(.link, value: self.aux.homepage, range: NSRange(location: 0, length: 8))
            
            
            self.homepageLabel.attributedText = attributedString
        }
        
        let attributedString = NSMutableAttributedString(string: "Imdb Page")
        attributedString.addAttribute(.link, value: "https://www.imdb.com/title/" + self.aux.imdbPage, range: NSRange(location: 0, length: 9))
        
        self.imdbPageLabel.isEditable = false
        self.imdbPageLabel.attributedText = attributedString
        self.popularityLabel.text = "Popularity " + String(self.aux.popularity)
        self.taglineLabel.text = self.aux.tagline
        self.languagesLabel.text = self.aux.spokenLanguages
        
        
        self.countriesLabel.text = self.aux.countries
        
        var genreList : String = ""
        if self.aux.adult {
            genreList = "Genres: Adult, "
        } else {
            genreList = "Genres: "
        }
        genreList.append(self.aux.genres)
        self.genresLabel.text = genreList
        if let url = URL(string:self.aux.backdropURL) {
            if let data = try? Data(contentsOf: url) {
                let imageData = data
                let image = UIImage(data: imageData)
                self.backdropImage.image = image
            }
        }
        self.view.layoutIfNeeded()
    }
    
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        UIApplication.shared.open(URL)
        return false
    }
}
