//
//  SegmentedDemoViewController.swift
//  SVGgh
//
//  Created by Glenn Howes on 4/23/16.
//  Copyright © 2016 Generally Helpful. All rights reserved.
//

import UIKit

class SegmentedDemoTableCell: UITableViewCell
{
    @IBOutlet var segmentedControl : GHSegmentedControl!
    {
        didSet
        {
            
            if let helmetRenderer = SVGghLoaderManager.loader().loadRender(forSVGIdentifier: "Helmet", in: nil)
            {
                self.segmentedControl.insertSegment(with: helmetRenderer, at: 0, animated: false)
            }
            
            if let eyeRenderer = SVGghLoaderManager.loader().loadRender(forSVGIdentifier: "Eye", in: nil)
            {
                self.segmentedControl.insertSegment(with: eyeRenderer, at: 1, animated: false)
            }
            
            self.segmentedControl.insertSegment(withTitle: "Demo", at: 2, animated: false)
            
            self.segmentedControl.selectedSegmentIndex = 1;
            
            if let myScheme = self.colorScheme
            {
                
                self.segmentedControl.schemeNumber = Int(myScheme)
            }

        }
    }
    var colorScheme: ColorScheme?
    {
        didSet
        {
            guard let scheme = self.colorScheme else
            {
                return
            }
            self.segmentedControl.schemeNumber = Int(scheme)
        }
    }
}

class SegmentedDemoViewController: UIViewController, UITableViewDataSource {

    @IBOutlet var tableView: UITableView!
    {
        didSet
        {
            tableView.dataSource = self
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return kLastColorScheme
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = tableView.dequeueReusableCell(withIdentifier: "SegmentCell", for: indexPath as IndexPath) as! SegmentedDemoTableCell
        result.colorScheme = ColorScheme(indexPath.row)
        return result
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
