//
//  SVGghDebuggingViewController.m
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
@property (weak, nonatomic) IBOutlet GHButton* printButton;

@end

@implementation SVGghDebuggingViewController


-(IBAction)redrawSVG:(id)sender
{
    [self.svgView setNeedsDisplay];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    SVGRenderer* aRenderer = [[SVGRenderer alloc] initWithResourceName:@"Artwork/Helmet" inBundle:nil];
    [self.segmentedControl insertSegmentWithRenderer:aRenderer accessibilityLabel:NSLocalizedString(@"Football Helmet", @"") atIndex:0 animated:NO];
	
    aRenderer = [[SVGRenderer alloc] initWithResourceName:@"Artwork/Eye" inBundle:nil];
    
    [self.segmentedControl insertSegmentWithRenderer:aRenderer accessibilityLabel:NSLocalizedString(@"Eye", @"") atIndex:1 animated:NO];
	
	aRenderer = [[SVGRenderer alloc] initWithResourceName:@"Artwork/Widgets" inBundle:nil];
#if TARGET_OS_TV
	
	[self.segmentedControl insertSegmentWithTitle:NSLocalizedString(@"Curvy", @"") atIndex:2 animated:NO];
#else
	
	[self.segmentedControl insertSegmentWithRenderer:aRenderer accessibilityLabel:NSLocalizedString(@"Widgets", @"") atIndex:2 animated:NO];
	[self.segmentedControl insertSegmentWithTitle:NSLocalizedString(@"Curvy", @"") atIndex:3 animated:NO];
#endif
    self.segmentedControl.selectedSegmentIndex = 0;

	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)print:(GHButton*)sender
{
    UIAlertAction* okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        
    }];
    
    
    self.svgView.renderer.currentColor = self.svgView.defaultColor;
    [SVGPrinter printRenderer:self.svgView.renderer
                withJobName:NSLocalizedString(@"SVGgh Test Printing", @"")
			   fromAnchorView:sender 
                 withCallback:^(NSError *error, PrintingResults printingResult) {
        if(error != nil)
        {
            
            UIAlertController* alertView = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Printing Error", @"Error Printing") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            [alertView addAction:okAction];
            [self presentViewController:alertView animated:YES completion:nil];
            
        }
        else if(printingResult != kSuccessfulPrintingResult)
        {
            switch(printingResult)
            {
                default:
                case kCouldntCreatePrintingDataResult:
                case kCouldntInterfaceWithPrinterResult:
                {
                    UIAlertController* alertView = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Printing Error", @"Error Printing") message:NSLocalizedString(@"Couldn't Connect to a Printer", @"") preferredStyle:UIAlertControllerStyleAlert];
                    [alertView addAction:okAction];
                    [self presentViewController:alertView animated:YES completion:nil];
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
	[self chooseArtworkIndex:selectedSegment];
}
-(void)chooseArtworkIndex:(NSInteger)selectedSegment
{
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
            controlIdentifier = @"widgets";
        break;
        case 3:
            controlIdentifier = @"textOnCurve";
        break;
    }
    
    UIViewController* embeddedController = [self.storyboard instantiateViewControllerWithIdentifier:controlIdentifier];
    UIViewController* oldController = nil;
    CGRect endBounds = self.containerView.bounds;
    CGRect leftStartRect = CGRectMake(-endBounds.size.width, endBounds.origin.y, endBounds.size.width, endBounds.size.height);
    CGRect rightStartRect =  CGRectOffset(endBounds, endBounds.size.width, 0.0);
    CGRect terminalBounds = leftStartRect;
    
    if(self.lastSelectedSegment > selectedSegment)
    {
        embeddedController.view.frame = leftStartRect;
        terminalBounds = rightStartRect;
    }
    else
    {
        embeddedController.view.frame = rightStartRect;
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
	
	if ([embeddedController.view isKindOfClass:[SVGDocumentView class]])
	{
		self.svgView = (SVGDocumentView*)embeddedController.view;
		self.printButton.enabled = YES;
	}
	else
	{
		self.svgView = nil;
		self.printButton.enabled = NO;
	}
	
    if(oldController == nil)
    {
        [self addChildViewController:embeddedController];
        embeddedController.view.frame = endBounds;
        [self.containerView addSubview:embeddedController.view];
        [embeddedController didMoveToParentViewController:self];
        
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    }
    else
    {
        [oldController willMoveToParentViewController:nil];
        [self addChildViewController:embeddedController];
        [self transitionFromViewController:oldController toViewController:embeddedController duration:0.35 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            embeddedController.view.frame = endBounds;
            oldController.view.frame = terminalBounds;
            
        } completion:^(BOOL finished) {
            [oldController removeFromParentViewController];
            [embeddedController didMoveToParentViewController:self];
            
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
        }];
    }
    
}

@end
