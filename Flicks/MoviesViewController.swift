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

class MoviesViewController: UIViewController, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var networkErrorView: UIView!
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var movies: [NSDictionary]?
    
    var filteredMovies: [NSDictionary]?
    
    var endpoint: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        // Flowlayout
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        
        // Update Navigation title
        if endpoint == "now_playing" {
            self.navigationItem.title = "Now Playing"
        } else if endpoint == "top_rated" {
            self.navigationItem.title = "Top Rated"
        }
        
        // Remove back button text
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        // Update navigation bar barTintColor and tintColor
        if let navigationBar = navigationController?.navigationBar {
            navigationBar.tintColor = UIColor.white
            navigationBar.barTintColor = UIColor.black
        }
        
        // Initialize a UIRefreshControl
        let refreshControl = UIRefreshControl()
        
        // Bind the action to the refresh control
        refreshControl.addTarget(self, action: #selector(refreshControlAction(refreshControl:)), for: UIControlEvents.valueChanged)
        
        // add refresh control to collection view
        collectionView.insertSubview(refreshControl, at: 0)
        
        refreshControlAction(refreshControl: refreshControl)
    }

    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // Makes a network request to get updated data
    // Updates the collectionView with the new data
    // Hides the RefreshControl
    func refreshControlAction(refreshControl: UIRefreshControl) {
        
        let apiKey = "d495b21c5c2a1a4a346cc03313315968"
        
        print(endpoint)
        
        let url = URL(string: "https://api.themoviedb.org/3/movie/" + endpoint + "?api_key=\(apiKey)")
        
        let request = URLRequest(url: url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        
        // Display HUD right before the request is made
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        let task: URLSessionDataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            
            // Hide HUD once the network request comes back (must be done on main UI thread)
            MBProgressHUD.hide(for: self.view, animated: true)
            
            if let data = data {
                if let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                    
                    self.movies = dataDictionary["results"] as? [NSDictionary]
                    self.filteredMovies = self.movies
                    
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
        collectionView.reloadData()
    }
    
    
    @IBAction func refresh(_ sender: Any) {
        
        // Reset filteredMovies to all movies
        self.filteredMovies = self.movies
        
        // Reload the collectionView now that there is new data
        self.collectionView.reloadData()
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
        
        // Set selection backgroundcolor to gray
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.gray
        cell.selectedBackgroundView = backgroundView
        
        let movie = filteredMovies![indexPath.row]
        
        let title = movie["title"] as! String
        let rating = String(format: "%.1f", movie["vote_average"] as! Float)
        
        cell.title.text = title
        cell.rating.text = rating
        
        let lowResolutionBaseUrl = "http://image.tmdb.org/t/p/w45"
        let highResolutionBaseUrl = "http://image.tmdb.org/t/p/original"
        
        if let posterPath = movie["poster_path"] as? String {
            let lowResolutionImageUrl = lowResolutionBaseUrl + posterPath
            let highResolutionImageUrl = highResolutionBaseUrl + posterPath
            
            let lowResolutionImageRequest = NSURLRequest(url: NSURL(string: lowResolutionImageUrl)! as URL)
            let highResolutionImageRequest = NSURLRequest(url: NSURL(string: highResolutionImageUrl)! as URL)
            
            
            cell.posterImageView.setImageWith(lowResolutionImageRequest as URLRequest, placeholderImage: nil, success: { (lowResolutionImageRequest, lowResolutionImageResponse, lowResolutionImage) -> Void in
                
                //if lowResolutionImageResponse != nil  {
                print("download low resolution image")
                cell.posterImageView.alpha = 0.0
                cell.posterImageView.image = lowResolutionImage
                
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    
                    cell.posterImageView.alpha = 1.0
                    
                }, completion: { (success) -> Void in
                    
                    
                    
                    // Start download high resolution image
                    cell.posterImageView.setImageWith(highResolutionImageRequest as URLRequest, placeholderImage: nil, success: { (highResolutionImageRequest, highResolutionImageResponse, highResolutionImage) -> Void in
                        
                        if highResolutionImageResponse != nil {
                            print("start download high resolution image")
                        } else {
                            print("high resolution image was cached")
                        }
                        
                        cell.posterImageView.image = highResolutionImage
                        
                    }, failure: ({ (request, response, error) -> Void in
                        
                        print("Load high resolution image failed")
                        
                    }))
                    
                    
                    
                })
                
                
            }, failure: {
                (imageRequest, imageResponse, error) -> Void in
                print("Failed to load image")
            })
            
            
            
        }
 
        
        return cell
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let cell = sender as! UICollectionViewCell
        let indexPath = collectionView.indexPath(for: cell)
        let movie = movies![indexPath!.row]
        
        let detailViewController = segue.destination as! DetailViewController
        
        detailViewController.movie = movie
        
        detailViewController.navigationItem.title = movie["title"] as? String
        
        // Deselect collection view after segue
        self.collectionView.deselectItem(at: indexPath!, animated: true)
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
