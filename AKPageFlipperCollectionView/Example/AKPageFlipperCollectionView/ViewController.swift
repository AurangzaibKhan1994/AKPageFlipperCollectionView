//
//  ViewController.swift
//  AKPageFlipperCollectionView
//
//  Created by AurangzaibKhan1994 on 09/19/2026.
//  Copyright (c) 2026 AurangzaibKhan1994. All rights reserved.
//

import UIKit
import AKPageFlipperCollectionView

struct PageFlippingData {
    var image1: UIImage?
    // var image2: UIImage?
}

class ViewController: UIViewController {
    @IBOutlet weak var collectionView1: AKPageFlipperCollectionView! // UICollectionView!
    @IBOutlet weak var collectionView2: AKPageFlipperCollectionView!
    @IBOutlet weak var collectionView3: AKPageFlipperCollectionView!
    @IBOutlet weak var collectionView4: AKPageFlipperCollectionView!
    @IBOutlet weak var stackView1: UIStackView!
    @IBOutlet weak var stackView2: UIStackView!
    
    var pageFlippingData = [PageFlippingData]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView1.dataSource = self
        collectionView2.dataSource = self
        collectionView3.dataSource = self
        collectionView4.dataSource = self
        //        collectionView2.isHidden = true
        //        collectionView3.isHidden = true
        //        collectionView4.isHidden = true
        //        stackView2.isHidden = true
        collectionView1.flipOrientation = .vertical
        collectionView2.flipOrientation = .vertical
        collectionView3.flipOrientation = .horizontal
        collectionView4.flipOrientation = .horizontal
        
        pageFlippingData = [
            PageFlippingData(image1: UIImage(named: "tower1")),
            PageFlippingData(image1: UIImage(named: "tower2")),
            PageFlippingData(image1: UIImage(named: "tower3")),
            PageFlippingData(image1: UIImage(named: "tower4")),
            PageFlippingData(image1: UIImage(named: "tower5")),
            PageFlippingData(image1: UIImage(named: "tower6")),
            PageFlippingData(image1: UIImage(named: "tower7")),
            PageFlippingData(image1: UIImage(named: "tower8")),
            PageFlippingData(image1: UIImage(named: "tower9")),
            PageFlippingData(image1: UIImage(named: "tower10"))
        ]
    }
} // end class ViewController

// MARK: - UICollectionView DataSource & Delegate
extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pageFlippingData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.collectionView1{
            let cell = self.collectionView1.dequeueReusableCell(withReuseIdentifier: "FlipPageCollectionViewCell1", for: indexPath) as! FlipPageCollectionViewCell1
            cell.imgData1.image = pageFlippingData[indexPath.row].image1
            return cell
        }else if collectionView == self.collectionView2{
            let cell = self.collectionView2.dequeueReusableCell(withReuseIdentifier: "FlipPageCollectionViewCell2", for: indexPath) as! FlipPageCollectionViewCell2
            cell.imgData1.image = pageFlippingData[indexPath.row].image1
            return cell
        }else if collectionView == self.collectionView3{
            let cell = self.collectionView3.dequeueReusableCell(withReuseIdentifier: "FlipPageCollectionViewCell3", for: indexPath) as! FlipPageCollectionViewCell3
            cell.imgData1.image = pageFlippingData[indexPath.row].image1
            return cell
        }else{
            let cell = collectionView4.dequeueReusableCell(withReuseIdentifier: "FlipPageCollectionViewCell4", for: indexPath) as! FlipPageCollectionViewCell4
            cell.imgData1.image = pageFlippingData[indexPath.row].image1
            return cell
        }
    }
}

// MARK: - Collection View Cell
class FlipPageCollectionViewCell1: UICollectionViewCell {
    @IBOutlet weak var imgData1: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imgData1?.contentMode = .scaleAspectFill
        self.clipsToBounds = true
    }
}

// MARK: - Collection View Cell
class FlipPageCollectionViewCell2: UICollectionViewCell {
    @IBOutlet weak var imgData1: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imgData1?.contentMode = .scaleAspectFill
        self.clipsToBounds = true
    }
}

// MARK: - Collection View Cell
class FlipPageCollectionViewCell3: UICollectionViewCell {
    @IBOutlet weak var imgData1: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imgData1?.contentMode = .scaleAspectFill
        self.clipsToBounds = true
    }
}

// MARK: - Collection View Cell
class FlipPageCollectionViewCell4: UICollectionViewCell {
    @IBOutlet weak var imgData1: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imgData1?.contentMode = .scaleAspectFill
        self.clipsToBounds = true
    }
}


