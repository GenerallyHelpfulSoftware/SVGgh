//
//  ViewController.m
//  Example SVGgh
//
//  Created by Glenn Howes on 1/29/14.
//  Copyright (c) 2014 Generally Helpful Software. All rights reserved.
//

#import "ExampleSVGghViewController.h"
#import <SVGgh/SVGgh.h>

@interface ExampleSVGghViewController ()

@end

@implementation ExampleSVGghViewController

-(IBAction)share:(id)sender
{
    [SVGtoPDFConverter createPDFFromRenderer:self.svgView.renderer intoCallback:^(NSData *pdfData) {
        if(pdfData.length)
        {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                NSString* shareText = NSLocalizedString(@"Sharing a PDF as an example", @"");
                __block NSArray* itemsToShare = [[NSArray alloc] initWithObjects:shareText, pdfData, nil];
                NSArray* excludedTypes = [[NSArray alloc] initWithObjects:UIActivityTypeAssignToContact, UIActivityTypePostToFacebook, UIActivityTypePostToTwitter, UIActivityTypeSaveToCameraRoll, UIActivityTypePostToWeibo, nil];
                if([UIDevice currentDevice].systemVersion.doubleValue >= 7)
                {
                    excludedTypes = [excludedTypes arrayByAddingObject:UIActivityTypeAddToReadingList];
                    excludedTypes = [excludedTypes arrayByAddingObject:UIActivityTypePostToFlickr];
                    excludedTypes = [excludedTypes arrayByAddingObject:UIActivityTypePostToVimeo];
                }
                
                UIActivityViewController* activityView = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
                activityView.excludedActivityTypes =excludedTypes;
                [self presentViewController:activityView animated:YES completion:nil];
                
            }
             ];
        }
        else
        {
            NSLog(@"Expected a PDF to be made");
        }
    }];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
