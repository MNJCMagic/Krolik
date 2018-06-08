//
//  DossierViewController.swift
//  Krolik
//
//  Created by Colin on 2018-06-06.
//  Copyright © 2018 Mike Stoltman. All rights reserved.
//

import UIKit

class DossierViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var agentLabel: UILabel!
    @IBOutlet weak var targetLabel: UILabel!
    
    //MARK: Properties
    
    let networkManager = NetworkManager()
    let database = DatabaseManager()
    var currentGameId: String!
    var currentPlayer: Player!
    var playerTarget: Player!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentGameId = UserDefaults.standard.string(forKey: Game.keys.id)
        updatePlayerAndTarget()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true)
        
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        imageView.addSubview(spinner)
        spinner.center = imageView.center
        spinner.startAnimating()
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            print("ERROR: No image found (DossierViewController)")
            return
        }
        
        networkManager.uploadPhoto(photo: image, path: "\(currentGameId)/\(currentPlayer.id)_target.jpg") { (url, error) in
            if error != nil {
                print(error ?? "error uploading photo in DossierViewController")
            }
            
            self.networkManager.compareFaces(target: self.playerTarget, photoURL: url.absoluteString, completion: { (isAMatch) in
                DispatchQueue.main.async {
                    if isAMatch {
                        let killAlert = UIAlertController(title: "Target Hit!", message: "You have just sucessfully assasinated \(self.playerTarget.nickname!)!" , preferredStyle: .alert)
                        killAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(killAlert, animated: true)
                        self.killPerson()
                        spinner.stopAnimating()
                    } else {
                        let failAlert = UIAlertController(title: "Target Miss!", message: "You have missed your target! Make sure you've got your positioning right and try to hit \(self.playerTarget.nickname!) again", preferredStyle: .alert)
                        failAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(failAlert, animated: true)
                        spinner.stopAnimating()
                    }
                }
                
            })
            
        }
    }
    
    func killPerson() {
        // update target state to dead
        database.changePlayerState(gameID: UserDefaults.standard.string(forKey: Game.keys.id)!, playerID: playerTarget.id!, state: Player.state.dead)
        
        // update assassin and target values on database
    database.databaseRef.child(Player.keys.root).child(currentPlayer.id!).updateChildValues([Player.keys.target : playerTarget.target!])
    database.databaseRef.child(Player.keys.root).child(playerTarget.target!).updateChildValues([Player.keys.assassin : currentPlayer.id!])
        
        updatePlayerAndTarget()
    }
    
    //MARK: Actions
    
    @IBAction func takeAimTapped(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.cameraFlashMode = .auto
        
        // Create the Camera Overlay
        let overlayOrigin = CGPoint(x: view.frame.origin.x+75, y: view.frame.origin.y+35)
        let overlaySize = CGSize(width: view.frame.width-150, height: view.frame.height-150)
        let cameraOverlay = UIImageView(frame: CGRect(origin: overlayOrigin, size: overlaySize))
        cameraOverlay.image = UIImage(named: "crosshair")
        cameraOverlay.contentMode = .scaleAspectFit
        imagePicker.cameraOverlayView = cameraOverlay
        
        present(imagePicker, animated: true)
        
    }
    
    
    func updatePlayerAndTarget() {
        print("update player/target called")
        // get the current player and its target from the database
        database.read(playerID: UserDefaults.standard.string(forKey: Player.keys.id)!) { (currentPlayer) in
            print("current player finished reading with these values:")
            print("id: \(currentPlayer?.id ?? "nil")")
            print("nickname: \(currentPlayer?.nickname ?? "nil")")
            print("target: \(currentPlayer?.target ?? "nil")")
            
            self.currentPlayer = currentPlayer
            print("assigned current player to property")
            
            
            self.database.read(playerID: currentPlayer!.target!, completion: { (playerTarget) in
                print("finished reading playerTarget with these values:")
                print("id: \(playerTarget?.id ?? "nil")")
                print("nickname: \(playerTarget?.nickname ?? "nil")")
                print("target: \(playerTarget?.target ?? "nil")")
                
                self.playerTarget = playerTarget
                print("assigned player target to property")
                
                print("entering game end check")
                // game ends if currentPlayer's target is itself
                if self.currentPlayer.id == self.playerTarget.id {
                    let gameOverAlert = UIAlertController(title: " Game Over!", message: "Game over, you WIN! Mission complete", preferredStyle: .alert)
                    gameOverAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(gameOverAlert, animated: true, completion: nil)
                    self.database.update(gameID: self.currentGameId, update: [Game.keys.state : Game.state.ended])
                    // add self as winner to game
                    let winnerName = currentPlayer!.nickname as String
                    let winnerID = currentPlayer!.id as String
               
                   // update winner id/name to game on database
                    self.database.databaseRef.child(Game.keys.root).child(self.currentGameId).child(Game.keys.winner).updateChildValues([winnerID : winnerName])
                    print("winner is: \(winnerName)!")
                    self.performSegue(withIdentifier: "quitFromDossier", sender: self)
                    // delete game and backup to history
//                    self.database.delete(gameID: self.currentGameId)
                } else {
                    self.networkManager.getDataFromUrl(url: URL(string: self.playerTarget.photoURL)!) { (data, response, error) in
                        print("finished getting image data")
                        
                        guard let imageData = data else {
                            print("bad data")
                            return
                        }
                        guard let image = UIImage(data: imageData) else {
                            print("error creating image from data")
                            return
                        }
                        DispatchQueue.main.async {
                            print("changes image to downloaded image")
                            self.imageView.image = image
                            self.agentLabel.text = self.currentPlayer.nickname
                            self.targetLabel.text = self.playerTarget.nickname
                        }
                    }
                    
                }
            })
        }
    }
}
