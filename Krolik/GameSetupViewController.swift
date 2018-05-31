//
//  GameSetupViewController.swift
//  Krolik
//
//  Created by Colin on 2018-05-31.
//  Copyright © 2018 Mike Stoltman. All rights reserved.
//

import UIKit
import FirebaseStorage

class GameSetupViewController: UIViewController, UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "playerCell", for: indexPath)
        //cell.backgroundColor = UIColor.gray
        
        let imageView = UIImageView(frame: cell.contentView.frame)
        imageView.contentMode = .scaleAspectFit
        imageView.layer.borderWidth = 2
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        imageView.layer.borderColor = UIColor.black.cgColor
        
        getDataFromUrl(url: URL(string: "https://firebasestorage.googleapis.com/v0/b/krolik-9ed87.appspot.com/o/GameID%2Fplayer01.png?alt=media&token=376d3c90-8c71-42a7-a673-612deafb8b4b")!) { (data, response, error) in
            guard let image = UIImage(data: data!) else {
                print("DATA ERROR from the url")
                return
            }
            DispatchQueue.main.async {
                imageView.image = image
                self.collectionView.cellForItem(at: indexPath)?.contentView.addSubview(imageView)
            }
        }
        return cell
    }
    
    func getDataFromUrl(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            completion(data, response, error)
            }.resume()
    }
}
