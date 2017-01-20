//
//  MoviesViewController.swift
//  Flicks
//
//  Created by Jiapei Liang on 1/20/17.
//  Copyright © 2017 jiapei. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var networkErrorView: UIView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var movies: [NSDictionary]?
    
    var filteredMovies: [NSDictionary]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        // Check whether internet is available
        if Reachability.isConnectedToNetwork()
        {
            print("Internet Connection Available!")
            networkErrorView.isHidden = true
        }
        else
        {
            print("Internet Connection not Available!")
            networkErrorView.isHidden = false
            
        }
        
        // Initialize a UIRefreshControl
        let refreshControl = UIRefreshControl()
        
        // Bind the action to the refresh control
        refreshControl.addTarget(self, action: #selector(refreshControlAction(refreshControl:)), for: UIControlEvents.valueChanged)
        
        // add refresh control to table view
        tableView.insertSubview(refreshControl, at: 0)
        
        refreshControlAction(refreshControl: refreshControl)
    }

    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let filteredMovies = filteredMovies {
            return filteredMovies.count
        } else {
            return 0;
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
        
        let movie = filteredMovies![indexPath.row]
        
        let title = movie["title"] as! String
        let overview = movie["overview"] as! String
        
        let baseUrl = "http://image.tmdb.org/t/p/w342"
        let posterPath = movie["poster_path"] as! String
        
        let imageUrl = baseUrl + posterPath
        
        let imageRequest = NSURLRequest(url: NSURL(string: imageUrl)! as URL)
        
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        cell.posterImageView.setImageWith(imageRequest as URLRequest, placeholderImage: nil, success: { (imageRequest, imageResponse, image) in
            
            // imageResponse will be nil if the image is cached
            if imageResponse != nil {
                print("Image was NOT cached, fade in image")
                cell.posterImageView.alpha = 0.0
                cell.posterImageView.image = image
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    cell.posterImageView.alpha = 1.0
                })
            } else {
                print("Image was cached so just update the image")
                cell.posterImageView.image = image
            }
            
        }, failure: {
            (imageRequest, imageResponse, error) -> Void in
            print("Failed to load image")
        })
        
        return cell
    }
    
    // Makes a network request to get updated data
    // Updates the tableView with the new data
    // Hides the RefreshControl
    func refreshControlAction(refreshControl: UIRefreshControl) {
        
        let apiKey = "d495b21c5c2a1a4a346cc03313315968"
        let url = URL(string: "https://api.themoviedb.org/3/movie/now_playing?api_key=\(apiKey)")!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        
        // Display HUD right before the request is made
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        let task: URLSessionDataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            
            // Hide HUD once the network request comes back (must be done on main UI thread)
            MBProgressHUD.hide(for: self.view, animated: true)
            
            if let data = data {
                if let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                    
                    self.movies = dataDictionary["results"] as! [NSDictionary]
                    self.filteredMovies = self.movies
                    
                    // Reload the tableView now that there is new data
                    self.tableView.reloadData()
                    
                    // Reload the collectionView now that there is new data
                    self.collectionView.reloadData()
                    
                    // Tell the refreshControl to stop spinning
                    refreshControl.endRefreshing()
                    
                    
                }
            }
        }
        
        task.resume()
        
    }
    
    // This method updates filteredData based on the text in the Search Box
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // When there is no text, filteredData is the same as the original data
        // When user has entered text into the search box
        // Use the filter method to iterate over all items in the data array
        // For each item, return true if the item should be included and false if the
        // item should NOT be included
        filteredMovies = searchText.isEmpty ? movies : movies?.filter({(movie: NSDictionary) -> Bool in
            // If dataItem matches the searchText, return true to include it
            let title = movie["title"] as! String
            
            return title.range(of: searchText, options: .caseInsensitive) != nil
        })
        
        tableView.reloadData()
        
        // Reload the collectionView now that there is new data
        self.collectionView.reloadData()
    }

    // show cancel button on search bar
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = true
    }
    
    // When cancel button is clicked, clear searchtext, show all movies, hide cancel button
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
        
        // Show all movies again
        filteredMovies = movies
        tableView.reloadData()
    }
    
    
    @IBAction func refresh(_ sender: Any) {
        
        // Check whether internet is available
        if Reachability.isConnectedToNetwork()
        {
            print("Internet Connection Available!")
            networkErrorView.isHidden = true
            
            let apiKey = "d495b21c5c2a1a4a346cc03313315968"
            let url = URL(string: "https://api.themoviedb.org/3/movie/now_playing?api_key=\(apiKey)")!
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
            let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
            
            // Display HUD right before the request is made
            MBProgressHUD.showAdded(to: self.view, animated: true)
            
            let task: URLSessionDataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
                
                // Hide HUD once the network request comes back (must be done on main UI thread)
                MBProgressHUD.hide(for: self.view, animated: true)
                
                if let data = data {
                    if let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                        print(dataDictionary)
                        
                        self.movies = dataDictionary["results"] as! [NSDictionary]
                        self.filteredMovies = self.movies
                        
                        // Reload the tableView now that there is new data
                        self.tableView.reloadData()
                        
                        // Reload the collectionView now that there is new data
                        self.collectionView.reloadData()
                    }
                }
            }
            
            task.resume()
        }
        else
        {
            print("Internet Connection not Available!")
            networkErrorView.isHidden = false
            
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let filteredMovies = filteredMovies {
            print("FilteredMovies: \(filteredMovies.count)")
            return filteredMovies.count
        } else {
            print("FilteredMovies: 0")
            return 0;
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell
        
        let movie = filteredMovies![indexPath.row]
        
        let title = movie["title"] as! String
        
        let baseUrl = "http://image.tmdb.org/t/p/w342"
        let posterPath = movie["poster_path"] as! String
        
        let imageUrl = baseUrl + posterPath
        
        let imageRequest = NSURLRequest(url: NSURL(string: imageUrl)! as URL)
        
        cell.title.text = title

        cell.posterImageView.setImageWith(imageRequest as URLRequest, placeholderImage: nil, success: { (imageRequest, imageResponse, image) in
            
            // imageResponse will be nil if the image is cached
            if imageResponse != nil {
                print("Image was NOT cached, fade in image")
                cell.posterImageView.alpha = 0.0
                cell.posterImageView.image = image
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    cell.posterImageView.alpha = 1.0
                })
            } else {
                print("Image was cached so just update the image")
                cell.posterImageView.image = image
            }
            
        }, failure: {
            (imageRequest, imageResponse, error) -> Void in
            print("Failed to load image")
        })
        
        return cell
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
