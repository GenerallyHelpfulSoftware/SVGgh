//
//  GHViewController.m
//  SVGgh Debugging App
//
//  Created by Glenn Howes on 1/30/14.
// The MIT License (MIT)

//  Copyright (c) 2011-2014 Glenn R. Howes

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


#import "SVGghDebuggingViewController.h"
#import <SVGgh/SVGgh.h>


@interface SVGghDebuggingViewController ()
@property (weak, nonatomic) IBOutlet GHSegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (assign, nonatomic) NSInteger lastSelectedSegment;

@end

@implementation SVGghDebuggingViewController


-(IBAction)redrawSVG:(id)sender
{
    [self.svgView setNeedsDisplay];
    
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSURL*  myArtwork = [GHControlFactory locateArtworkForObject:self atSubpath:@"Artwork/Helmet"];
    
    SVGRenderer* aRenderer = [[SVGRenderer alloc] initWithContentsOfURL:myArtwork];
    [self.segmentedControl insertSegmentWithRenderer:aRenderer atIndex:0 animated:NO];
    
    myArtwork = [GHControlFactory locateArtworkForObject:self atSubpath:@"Artwork/Eye"];
    aRenderer = [[SVGRenderer alloc] initWithContentsOfURL:myArtwork];
    
    [self.segmentedControl insertSegmentWithRenderer:aRenderer atIndex:1 animated:NO];
    
    
    
    myArtwork = [GHControlFactory locateArtworkForObject:self atSubpath:@"Artwork/Butterfly"];
    aRenderer = [[SVGRenderer alloc] initWithContentsOfURL:myArtwork];
    
    [self.segmentedControl insertSegmentWithRenderer:aRenderer atIndex:2 animated:NO];
    [self.segmentedControl insertSegmentWithTitle:NSLocalizedString(@"Curvy", @"") atIndex:3 animated:NO];
    self.segmentedControl.selectedSegmentIndex = 0;
    
    
    
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)print:(id)sender
{
    self.svgView.renderer.currentColor = self.svgView.defaultColor;
    [SVGPrinter printRenderer:self.svgView.renderer
                withJobName:NSLocalizedString(@"SVGgh Test Printing", @"")
                 withCallback:^(NSError *error, PrintingResults printingResult) {
        if(error != nil)
        {
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Printing Error", @"Error Printing") message:error.localizedDescription   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        }
        else if(printingResult != kSuccessfulPrintingResult)
        {
            switch(printingResult)
            {
                default:
                case kCouldntCreatePrintingDataResult:
                case kCouldntInterfaceWithPrinterResult:
                {
                    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Printing Error", @"Error Printing") message:NSLocalizedString(@"Couldn't Connect to Printer", @"")   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alertView show];
                }
                break;
            }
            
        }
    }];
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController* controller = segue.destinationViewController;
    if([segue.identifier isEqualToString:@"initialEmbed"])
    {
        self.svgView = (SVGDocumentView*)controller.view;
    }
}

- (IBAction)toggleView:(GHSegmentedControl *)sender
{
    NSInteger selectedSegment = sender.selectedSegmentIndex;
    NSString* controlIdentifier = nil;
    switch(selectedSegment)
    {
        case 0:
            controlIdentifier = @"helmet";
        break;
        case 1:
            controlIdentifier = @"eyes";
        break;
        case 2:
            controlIdentifier = @"creatures";
        break;
        case 3:
            controlIdentifier = @"textOnCurve";
        break;
    }
    
    UIViewController* artworkController = [self.storyboard instantiateViewControllerWithIdentifier:controlIdentifier];
    UIViewController* oldController = nil;
    CGRect endBounds = self.containerView.bounds;
    CGRect leftStartRect = CGRectMake(-endBounds.size.width, endBounds.origin.y, endBounds.size.width, endBounds.size.height);
    CGRect rightStartRect =  CGRectOffset(endBounds, endBounds.size.width, 0.0);
    CGRect terminalBounds = leftStartRect;
    
    if(self.lastSelectedSegment > selectedSegment)
    {
        artworkController.view.frame = leftStartRect;
        terminalBounds = rightStartRect;
    }
    else
    {
        artworkController.view.frame = rightStartRect;
    }
    
    self.lastSelectedSegment = selectedSegment;
    
    
    for(UIViewController* anOldController in self.childViewControllers)
    {
        if(anOldController.view.superview == self.containerView)
        {
            oldController = anOldController;
            break;
        }
    }
    
    self.svgView = (SVGDocumentView*)artworkController.view;
    
    if(oldController == nil)
    {
        [self addChildViewController:artworkController];
        artworkController.view.frame = endBounds;
        [self.containerView addSubview:artworkController.view];
        [artworkController didMoveToParentViewController:self];
    }
    else
    {
        [oldController willMoveToParentViewController:nil];
        [self addChildViewController:artworkController];
        [self transitionFromViewController:oldController toViewController:artworkController duration:0.35 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            artworkController.view.frame = endBounds;
            oldController.view.frame = terminalBounds;
            
        } completion:^(BOOL finished) {
            [oldController removeFromParentViewController];
            [artworkController didMoveToParentViewController:self];
        }];
    }
    
}
@end
