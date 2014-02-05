//
//  ViewController.h
//  Example SVGgh
//
//  Created by Glenn Howes on 1/29/14.
//  Copyright (c) 2014 Generally Helpful Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <SVGgh/SVGgh.h>

@interface ExampleSVGghViewController : UIViewController
@property(nonatomic, weak) IBOutlet SVGDocumentView* svgView;
-(IBAction)share:(id)sender;
@end
