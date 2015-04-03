//
//  GHControl.h
//  SVGgh
//
//  Created by Glenn Howes on 2015-03-26.
//  Copyright (c) 2015 Generally Helpful Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GHControlFactory.h"

#ifndef IBInspectable
#define IBInspectable
#endif

@interface GHControl : UIControl
@property(nonatomic, assign) ColorScheme         scheme;
/*! @property schemeNumber
 * @brief this is equivalent to the scheme property, just the one expected to be set via Storyboard or Nib
 */
@property(nonatomic, assign) IBInspectable NSInteger           schemeNumber;

// these are all related to how the button draws itself as part of a scheme
@property(nonatomic, assign) CGGradientRef       faceGradient;
@property(nonatomic, assign) CGGradientRef       faceGradientPressed;
@property(nonatomic, assign) CGGradientRef       faceGradientSelected;
@property(nonatomic, strong) IBInspectable UIColor*            textColor;
@property(nonatomic, strong) IBInspectable UIColor*            textColorPressed;
@property(nonatomic, strong) IBInspectable UIColor*            textColorSelected;
@property(nonatomic, assign) BOOL                drawsChrome;
@property(nonatomic, strong) UIColor*            ringColor;
@property(nonatomic, strong) UIColor*            textShadowColor;
@property(nonatomic, assign) BOOL                useRadialGradient;
@property (nonatomic, assign) CGFloat             textFontSize;
@property(nonatomic, assign) BOOL                 useBoldText;
@property(nonatomic, assign) BOOL                 showShadow;



-(void) setupForScheme:(NSUInteger)aScheme;

@end
