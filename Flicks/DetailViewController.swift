//
//  DetailViewController.swift
//  Flicks
//
//  Created by Jiapei Liang on 1/21/17.
//  Copyright © 2017 jiapei. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var releaseDateLabel: UILabel!
    @IBOutlet weak var overviewLabel: UILabel!
    @IBOutlet weak var voteAverageLabel: UILabel!
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var infoView: UIView!
    
    var movie: NSDictionary!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       

        scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: infoView.frame.origin.y + infoView.frame.size.height)
        
        print(movie)
        
        let title = movie["title"] as! String
        titleLabel.text = title
        
        let releaseDate = movie["release_date"] as! String
        releaseDateLabel.text = releaseDate
        
        let voteAverage = String(format: "%.1f", movie["vote_average"] as! Float)
        voteAverageLabel.text = "⭐️" + voteAverage
        
        let overview = movie["overview"] as! String
        overviewLabel.text = overview
        overviewLabel.sizeToFit()
        
        let lowResolutionBaseUrl = "http://image.tmdb.org/t/p/w45"
        let highResolutionBaseUrl = "http://image.tmdb.org/t/p/original"
        
        if let posterPath = movie["poster_path"] as? String {
            let lowResolutionImageUrl = lowResolutionBaseUrl + posterPath
            let highResolutionImageUrl = highResolutionBaseUrl + posterPath
            
            let lowResolutionImageRequest = NSURLRequest(url: NSURL(string: lowResolutionImageUrl)! as URL)
            let highResolutionImageRequest = NSURLRequest(url: NSURL(string: highResolutionImageUrl)! as URL)
            
            posterImageView.setImageWith(lowResolutionImageRequest as URLRequest, placeholderImage: nil, success: { (lowResolutionImageRequest, lowResolutionImageResponse, lowResolutionImage) in
                
                // imageResponse will be nil if the image is cached
                //if lowResolutionImageResponse != nil {
                    print("Image was NOT cached, fade in image")
                    self.posterImageView.alpha = 0.0
                    self.posterImageView.image = lowResolutionImage
                    UIView.animate(withDuration: 0.3, animations: { () -> Void in
                        self.posterImageView.alpha = 1.0
                    }, completion: { (success) -> Void in
                        
                        self.posterImageView.setImageWith(highResolutionImageRequest as URLRequest, placeholderImage: nil, success: { (highResolutionImageRequest, highResolutionImageResponse, highResolutionImage) -> Void in
                            
                            self.posterImageView.image = highResolutionImage
                            
                        }, failure: ({ (request, response, error) -> Void in
                            
                            print("Load high resolution image failed")
                            
                        }))
                    })
                //} else {
                //    print("Image was cached so just update the image")
                //    self.posterImageView.image = lowResolutionImage
                //}
                
            }, failure: {
                (imageRequest, imageResponse, error) -> Void in
                print("Failed to load image")
            })
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
