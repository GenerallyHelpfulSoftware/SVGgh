//
//  SVGTabBarItem.m
//  SVGgh
//
//  Created by Glenn Howes on 7/9/15.
//  Copyright © 2015 Generally Helpful. All rights reserved.
//

#import "SVGTabBarItem.h"

#import "SVGRenderer.h"
#import "GHControlFactory.h"


@implementation SVGTabBarItem

-(void) updateImages
{
    CGFloat scale =  [[UIScreen mainScreen] scale];
#if TARGET_OS_TV
    CGFloat baseDimension = 138; // Is there an official value for this?
#else
    CGFloat baseDimension = 30;
#endif
    CGSize  imageSize = CGSizeMake(baseDimension, baseDimension);
    
    if(self.image == nil && self.artworkPath.length)
    {
        NSURL*  myArtwork = [GHControlFactory locateArtworkForObject:self atSubpath:self.artworkPath];
        
        if(myArtwork != nil)
        {// draw my SVG
            SVGRenderer* renderer = [[SVGRenderer alloc] initWithContentsOfURL:myArtwork];
            renderer.currentColor = self.nominalBaseColor;
            UIImage* image = [renderer asImageWithSize:imageSize andScale:scale];
            if(self.nominalBaseColor != nil)
            {
                image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            }
            self.image = image;
            
        }
    }
    
    if(self.selectedImage == nil)
    {
        UIColor* selectedColor = self.nominalSelectedColor;
        NSString* artworkPathToUse = self.selectedArtworkPath;
        if(artworkPathToUse.length == 0)
        {
            artworkPathToUse = self.artworkPath;
        }
        if(artworkPathToUse.length)
        {
            NSURL*  myArtwork = [GHControlFactory locateArtworkForObject:self atSubpath:artworkPathToUse];
            if(myArtwork != nil)
            {
                SVGRenderer* renderer = [[SVGRenderer alloc] initWithContentsOfURL:myArtwork];
                renderer.currentColor = selectedColor;
                UIImage* image = [renderer asImageWithSize:imageSize andScale:scale];
                if(selectedColor != nil)
                {
                    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
                }
                self.selectedImage = image;
            }
        }
    }
}

-(void) setArtworkPath:(NSString *)artworkPath
{
    if(_artworkPath == nil || ![artworkPath isEqualToString:_artworkPath])
    {
        _artworkPath = artworkPath;
        self.image = nil;
        [self updateImages];
    }
    
}

-(void) setSelectedArtworkPath:(NSString*)selectedArtworkPath
{
    if(_selectedArtworkPath == nil || ![selectedArtworkPath isEqualToString:_selectedArtworkPath])
    {
        _selectedArtworkPath = selectedArtworkPath;
        self.selectedImage = nil;
        [self updateImages];
    }
}

-(UIColor*) nominalBaseColor
{
    UIColor* result = self.baseColor;
    if(result == nil)
    {
        result = [[UIBarButtonItem appearance] tintColor];
    }
    
    
    return result;
}

-(UIColor*) nominalSelectedColor
{
    UIColor* result = self.selectedColor;
    if(result == nil)
    {
        result = [self.nominalBaseColor colorWithAlphaComponent:0.5];
    }
    return result;
}

-(void) setBaseColor:(UIColor *)baseColor
{
    _baseColor = baseColor;
    self.image = nil;
    [self updateImages];
}

-(void) setSelectedColor:(UIColor *)selectedColor
{
    _selectedColor = selectedColor;
    self.selectedImage = nil;
    [self updateImages];
}

+(void)makeSureLoaded
{
}

@end
