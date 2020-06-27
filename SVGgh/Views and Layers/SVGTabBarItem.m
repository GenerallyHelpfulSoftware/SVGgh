//
//  SVGTabBarItem.m
//  SVGgh
//
//  Created by Glenn Howes on 7/9/15.
//  Copyright © 2015 Generally Helpful. All rights reserved.
//

#import "SVGTabBarItem.h"

#import "SVGRenderer.h"
#import "SVGghLoader.h"


@implementation SVGTabBarItem

-(void) updateImagesForcingImage:(BOOL)forceNewImage forcingSelectedImage:(BOOL) forceNewSelectedImage
{
    CGFloat scale =  [[UIScreen mainScreen] scale];
#if TARGET_OS_TV
    CGFloat baseDimension = 138; // Is there an official value for this?
#else
    CGFloat baseDimension = 30;
#endif
    CGSize  imageSize = CGSizeMake(baseDimension, baseDimension);
    
    UIImage* startingSelectedImage = self.selectedImage;
    UIImage* startingImage = self.image;
    
    if((startingImage == nil || forceNewImage) && self.artworkPath.length)
    {
        SVGRenderer* renderer = [[SVGghLoaderManager loader] loadRenderForSVGIdentifier:self.artworkPath inBundle:nil];
        
        if(renderer != nil)
        {// draw my SVG
            renderer.currentColor = self.nominalBaseColor;
            UIImage* image = [renderer asImageWithSize:imageSize andScale:scale];
            if(self.nominalBaseColor != nil)
            {
                image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            }
            self.image = image;
            
        }
    }
    
    if(startingSelectedImage == nil || forceNewSelectedImage)
    {
        UIColor* selectedColor = self.nominalSelectedColor;
        NSString* artworkPathToUse = self.selectedArtworkPath;
        if(artworkPathToUse.length == 0)
        {
            artworkPathToUse = self.artworkPath;
        }
        if(artworkPathToUse.length)
        {
            SVGRenderer* renderer =  [[SVGghLoaderManager loader] loadRenderForSVGIdentifier:artworkPathToUse inBundle:nil];
            if(renderer != nil)
            {
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
        [self updateImagesForcingImage:YES forcingSelectedImage:self.selectedArtworkPath.length == 0];
    }
    
}

-(void) setSelectedArtworkPath:(NSString*)selectedArtworkPath
{
    if(_selectedArtworkPath == nil || ![selectedArtworkPath isEqualToString:_selectedArtworkPath])
    {
        _selectedArtworkPath = selectedArtworkPath;
        self.selectedImage = nil;
        [self updateImagesForcingImage:NO forcingSelectedImage:YES];
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
    [self updateImagesForcingImage:YES forcingSelectedImage:NO];
}

-(void) setSelectedColor:(UIColor *)selectedColor
{
    _selectedColor = selectedColor;
    self.selectedImage = nil;
    [self updateImagesForcingImage:NO forcingSelectedImage:YES];
}

+(void)makeSureLoaded
{
}

@end
