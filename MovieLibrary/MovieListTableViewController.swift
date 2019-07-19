//
//  MovieListTableViewController.swift
//  MovieLibrary
//
//  Created by Victor on 16/07/19.
//  Copyright © 2019 Victor. All rights reserved.
//

import UIKit
import Alamofire
import CoreData
import Network

class MovieListTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel : UILabel!
    @IBOutlet weak var genresLabel : UILabel!
    @IBOutlet weak var dateLabel : UILabel!
    @IBOutlet weak var scoreLabel : UILabel!
    @IBOutlet weak var coverImage: UIImageView!
}

class MovieListTableViewController: UITableViewController {
    
    let monitor = NWPathMonitor()
    var movieList = [movieInfo]()
    var net : Bool = true
    let indicator:UIActivityIndicatorView = UIActivityIndicatorView  (style: UIActivityIndicatorView.Style.gray)
    // Cache
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewWillAppear(_ animated: Bool) {
        if movieList.count < 1 {
            startLoader()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.allowsSelection = true
        self.tableView.delegate = self
        let context = appDelegate.persistentContainer.viewContext
    
        // Net checker
        monitor.pathUpdateHandler = { pathUpdateHandler in
            if pathUpdateHandler.status == .satisfied {
                self.net = true
                if self.movieList.count == 1 {
                    self.startLoader()
                    self.movieList.popLast()
                    self.downloadFromServer()
                }
            } else {
                self.stopLoader()
                self.net = false
            }
        }
        let queue = DispatchQueue(label: "InternetConnectionMonitor")
        monitor.start(queue: queue)
        
        // Check cache
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "MovieCore")
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
                var aux = movieInfo()
                // Populate movie list from the core data
                if let id = data.value(forKey: "id") as? Int {
                    aux.id = id
                }
                if let voteAverage = data.value(forKey: "voteAverage") as? Double {
                    aux.voteAverage = voteAverage
                }
                if let title = data.value(forKey: "title") as? String {
                    aux.title = title
                }
                if let posterURL = data.value(forKey: "posterURL") as? String {
                    aux.posterURL = posterURL
                }
                if let genres = data.value(forKey: "genres") as? String {
                    aux.genres = genres
                }
                if let release = data.value(forKey: "releaseDate") as? String {
                    aux.releaseDate = release
                }
                self.movieList.append(aux)
            }
            if movieList.count == 0 {
                downloadFromServer()
                stopLoader()
            }
            stopLoader()
            self.tableView.reloadData()
        } catch {
            // Failed cache
        }
        
    }
    
    func downloadFromServer(){
        let context = appDelegate.persistentContainer.viewContext
        // Download from server
        performRequest() { dictionary, error in
            guard let dictionary = dictionary, error == nil else {
                var aux = movieInfo()
                aux.title = "No Internet"
                self.movieList = [movieInfo()]
                self.movieList.popLast()
                self.movieList.append(aux)
                self.stopLoader()
                self.tableView.reloadData()
                return
            }
            for item in dictionary {
                var aux = movieInfo()
                let entity = NSEntityDescription.entity(forEntityName: "MovieCore", in: context)
                let newEntry = NSManagedObject(entity: entity!, insertInto: context)
                
                if let id = item["id"] as? Int {
                    newEntry.setValue(id, forKey: "id")
                    aux.id = id
                }
                if let voteAverage = item["vote_average"] as? Double {
                    newEntry.setValue(voteAverage, forKey: "voteAverage")
                    aux.voteAverage = voteAverage
                }
                if let title = item["title"] as? String {
                    newEntry.setValue(title, forKey: "title")
                    aux.title = title
                }
                if let posterURL = item["poster_url"] as? String {
                    newEntry.setValue(posterURL, forKey: "posterURL")
                    aux.posterURL = posterURL
                }
                if let genres = item["genres"] as? [String] {
                    var genreList: String = ""
                    for item in genres {
                        genreList.append(item)
                        genreList.append(",")
                    }
                    genreList.removeLast()
                    
                    newEntry.setValue(genreList, forKey: "genres")
                    aux.genres = genreList
                }
                if let releaseDate = item["release_date"] as? String {
                    newEntry.setValue(releaseDate, forKey: "releaseDate")
                    aux.releaseDate = releaseDate
                }
                
                // Save to core data
                do {
                    try context.save()
                } catch {
                    print("Failed saving")
                }
                
                self.movieList.append(aux)
            }
            self.stopLoader()
            self.tableView.reloadData()
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
    
    func performRequest(completionHandler: @escaping ([[String:Any]]?, Error?) -> Void) {
        Alamofire.request("https://desafio-mobile.nyc3.digitaloceanspaces.com/movies").responseJSON { response in
            switch response.result {
            case .failure(let error):
                completionHandler(nil, error)
            case .success(let responseObject):
                let dictionary = responseObject as? [[String: Any]]
                completionHandler(dictionary, nil)
            }
        }
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.movieList.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "infoCell", for: indexPath) as! MovieListTableViewCell

        // Configure the cell...
        cell.titleLabel.text = self.movieList[indexPath.row].title
        
        if self.movieList.count > 1 {
            // Converting date
            let dateFormatterGet = DateFormatter()
            dateFormatterGet.dateFormat = "yyyy-MM-dd"
            
            let dateFormatterPrint = DateFormatter()
            dateFormatterPrint.dateFormat = "dd/MM/yyyy"
            
            if let date = dateFormatterGet.date(from: self.movieList[indexPath.row].releaseDate) {
                cell.dateLabel.text = "Released: " + dateFormatterPrint.string(from: date)
            }
            
            cell.scoreLabel.text = "User Score: " + String(self.movieList[indexPath.row].voteAverage)
            // Genre list
            cell.genresLabel.text = self.movieList[indexPath.row].genres
            
            // get image
            if let url = URL(string:self.movieList[indexPath.row].posterURL) {
                if let data = try? Data(contentsOf: url) {
                    let imageData = data
                    let image = UIImage(data: imageData)
                    cell.coverImage.image = image
                }
            }
        } else {
            cell.dateLabel.text = ""
            cell.scoreLabel.text = ""
            cell.genresLabel.text = ""
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Movie List"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if  segue.identifier == "ShowMovieDetails",
            let destination = segue.destination as? MovieDetailsViewController,
            let movieIndex = tableView.indexPathForSelectedRow?.row
        {
            destination.id = self.movieList[movieIndex].id
        }
    }
   
}
