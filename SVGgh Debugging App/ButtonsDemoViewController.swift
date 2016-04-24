//
//  ButtonsDemoViewController.swift
//  SVGgh
//
//  Created by Glenn Howes on 4/23/16.
//  Copyright © 2016 Generally Helpful. All rights reserved.
//

import UIKit
import SVGgh

class ButtonCell: UICollectionViewCell
{
    @IBOutlet var button : GHButton!
    
    var colorScheme: ColorScheme?
        {
        didSet
        {
            guard let scheme = self.colorScheme else
            {
                return
            }
            self.button.schemeNumber = Int(scheme)
        }
    }
}



class ButtonsDemoViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBOutlet var collectionView: UICollectionView!
        {
        didSet
        {
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.reloadData()
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return kLastColorScheme
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let result = collectionView.dequeueReusableCellWithReuseIdentifier("ButtonCell", forIndexPath: indexPath) as! ButtonCell
        result.colorScheme = ColorScheme(indexPath.item)
        return result
    }
    
    func collectionView(collectionView : UICollectionView,layout collectionViewLayout:UICollectionViewLayout,sizeForItemAtIndexPath indexPath:NSIndexPath) -> CGSize
    {
        let baseSize = CGFloat(floor(fmin(self.view.bounds.width, self.view.bounds.height)/5.0))
        return CGSize(width: baseSize, height: baseSize)
    }
    
    
}
