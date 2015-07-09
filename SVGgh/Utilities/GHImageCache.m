//
//  SVGgh.h
//  GHIMageCache.m
// The MIT License (MIT)

//  Copyright (c) 2013-2014 Glenn R. Howes

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
//
//  Created by Glenn Howes on 10/5/13.
//


#if defined(__has_feature) && __has_feature(modules)
@import Foundation;
@import ImageIO;
@import UIKit;
#else
#import <Foundation/Foundation.h>
#import <ImageIO/ImageIO.h>
#import <UIKit/UIKit.h>
#endif

#import "GHImageCache.h"


const CGColorRenderingIntent	kColoringRenderingIntent = kCGRenderingIntentPerceptual;

NSString* const kImageAddedToCacheNotificationName = @"kImageAddedToCacheNotificationName";

NSString* const kImageAddedKey = @"image";
NSString* const kImageURLAddedKey = @"url";
NSString* const kFacesAddedToCacheNotificationName = @"kFacesAddedToCacheNotificationName";

NSString* const kFacesAddedKey = @"faces";
NSString* const kFacesURLsAddedKey = @"urls";

@implementation GHImageCache
+(NSCache*)imageCache
{
    static NSCache* sResult = nil;
    static dispatch_once_t  done;
    dispatch_once(&done, ^{
        sResult = [[NSCache alloc] init];
        sResult.name = @"Image Cache";
    });
    return sResult;
}

+(NSOperationQueue*) loadQueue
{
    static NSOperationQueue* sResult = nil;
    static dispatch_once_t  done;
    dispatch_once(&done, ^{
        sResult = [[NSOperationQueue alloc] init];
        sResult.name = @"genhelp.imageLoader";
    });
    return sResult;
}

+(void) setCachedImage:(UIImage*)anImage forURL:(NSURL*) aFileURL
{
    if(anImage == nil && aFileURL != nil)
    {
        [[GHImageCache imageCache] setObject:[NSNull null] forKey:aFileURL.absoluteString cost:10];
    }
    else if(aFileURL != nil)
    {
        [[GHImageCache imageCache] setObject:anImage forKey:aFileURL.absoluteString cost:aFileURL.isFileURL?10:10000];
    }
    else
    {
        NSLog(@"Tried to set an image Cache without an URL");
    }
}

+(void) cacheImage:(UIImage*)anImage forName:(NSString*)aName
{
    if(anImage != nil && aName.length)
    {
        [[GHImageCache imageCache] setObject:anImage forKey:aName cost:2];
    }
}

+(void) invalidateImageWithName:(NSString*)aName
{
    if(aName.length)
    {
        [[GHImageCache imageCache] removeObjectForKey:aName];
    }
}

+(UIImage*) uncacheImageForName:(NSString*)aName
{
    NSCache* myCache = [GHImageCache imageCache];
    UIImage* result = [myCache objectForKey:aName];
    return result;
}

+(void) retrieveCachedImageFromURL:(NSURL*)aURL intoCallback:(handleRetrievedImage_t)retrievalCallback
{
    UIImage* result = [[GHImageCache imageCache] objectForKey:aURL.absoluteString];
    if(result != nil)
    {
        if([result isKindOfClass:[UIImage class]])
        {
            retrievalCallback(result, aURL);
        }
        else
        {
            retrievalCallback(nil, aURL);
        }
    }
    else
    {
		CGImageRef imageRef = 0;
        if([[aURL pathExtension] isEqualToString:@"png"])
		{
			CGDataProviderRef pngProvider = CGDataProviderCreateWithURL((__bridge CFURLRef) aURL);
			if(pngProvider != 0)
			{
				imageRef = CGImageCreateWithPNGDataProvider(pngProvider, NULL, true,
															kColoringRenderingIntent);
				CFRelease(pngProvider);
			}
		}
		else  if([[aURL pathExtension] isEqualToString:@"jpg"])
		{
			CGDataProviderRef jpgProvider = CGDataProviderCreateWithURL((__bridge CFURLRef) aURL);
			if(jpgProvider != 0)
			{
				imageRef = CGImageCreateWithJPEGDataProvider(jpgProvider, NULL, true,
                                                             kColoringRenderingIntent);
				CFRelease(jpgProvider);
			}
		}
		else
		{
			result = [[UIImage alloc] initWithContentsOfFile:[aURL path]];
		}
		if(imageRef != 0)
		{
			result = [[UIImage alloc] initWithCGImage:imageRef];
			CFRelease(imageRef);
            [self setCachedImage:result forURL:aURL];
		}
        else // put a null into here so I don't spend time trying over and over to get something that doesn't exist.
        {
            [[GHImageCache imageCache] setObject:[NSNull null] forKey:aURL.absoluteString cost:20000];// wouldn't save anything by getting rid of this.
        }
        retrievalCallback(result, aURL);
    }
}

+(void) aSyncRetrieveCachedImageFromURL:(NSURL*)aURL intoCallback:(handleRetrievedImage_t)retrievalCallback
{
    [[GHImageCache loadQueue] addOperationWithBlock:^{
        [GHImageCache retrieveCachedImageFromURL:aURL intoCallback:retrievalCallback];
    }];
}

+(NSString*) newUniqueID
{
    CFUUIDRef UUIDRef = CFUUIDCreate(kCFAllocatorDefault);
    NSString* result = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, UUIDRef));
    CFRelease(UUIDRef);
    return result;
}

+(void) saveImageData:(NSData*)imageData withName:(NSString*)preferredName withCallback:(handleRetrievedImage_t)callback
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSFileManager* localFileManager = [[NSFileManager alloc] init];
    NSString* pathToImages = [basePath stringByAppendingPathComponent:@"Photos"];
    NSError* fileError = nil;
    if(![localFileManager fileExistsAtPath:pathToImages])
    {
        [localFileManager createDirectoryAtPath:pathToImages withIntermediateDirectories:YES attributes:nil error:&fileError];
    }
    if(fileError == nil)
    {
        NSString* pathToImage = [pathToImages stringByAppendingPathComponent:preferredName];
        
        NSURL* theURL = [NSURL fileURLWithPath:pathToImage];
        if([localFileManager fileExistsAtPath:pathToImage]) // already have this one.
        {
            [self retrieveCachedImageFromURL:theURL intoCallback:^(UIImage *anImage, NSURL *location) {
                if(anImage != nil)
                {
                    callback(anImage, location);
                }
                else
                {
                    NSError* fileError = nil;
                    [imageData writeToFile:pathToImage options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen  error:&fileError];
                    if(fileError == nil)
                    {
                        UIImage* myImage = [[UIImage alloc] initWithData:imageData];
                        
                        [self setCachedImage:myImage forURL:theURL];
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:kImageAddedToCacheNotificationName object:self userInfo:@{kImageAddedKey:myImage, kImageURLAddedKey:theURL}];
                        callback(myImage, theURL);
                    }
                    else
                    {
                        callback(nil, nil);
                    }
                }
            }];
        }
        else
        {
            [imageData writeToFile:pathToImage options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen  error:&fileError];
            if(fileError == nil)
            {
                UIImage* myImage = [[UIImage alloc] initWithData:imageData];
                
                [self setCachedImage:myImage forURL:theURL];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kImageAddedToCacheNotificationName object:self userInfo:@{kImageAddedKey:myImage, kImageURLAddedKey:theURL}];
                callback(myImage, theURL);
            }
        }
    }
    
    if(fileError != nil)
    {
        callback(nil, nil);
    }
}

+(NSString*) uniqueFilenameWithExtension:(NSString*)extension
{
    NSString* result = [NSString stringWithFormat:@"%@.%@", [self newUniqueID], extension];
    return result;
}

+(void) saveImage:(UIImage*)anImage withCallback:(handleExtractedFaces_t)callback
{
    if(anImage != nil)
    {
        NSString* extension = @"png";
        NSData* imageData = UIImagePNGRepresentation(anImage);
        if(imageData.length > 65535)
        {// ok, this is a biggish thing, try JPEG compression
            extension = @"jpg";
            imageData = UIImageJPEGRepresentation(anImage, 0.5);
        }
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        NSFileManager* localFileManager = [[NSFileManager alloc] init];
        NSString* pathToImages = [basePath stringByAppendingPathComponent:@"Photos"];
        NSError* fileError = nil;
        if(![localFileManager fileExistsAtPath:pathToImages])
        {
            [localFileManager createDirectoryAtPath:pathToImages withIntermediateDirectories:YES attributes:nil error:&fileError];
        }
        if(fileError == nil)
        {
            NSString* pathToImage = [pathToImages stringByAppendingPathComponent: [self uniqueFilenameWithExtension:extension]];
            [imageData writeToFile:pathToImage options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen  error:&fileError];
            if(fileError == nil)
            {
                NSURL* theURL = [NSURL fileURLWithPath:pathToImage];
                [self setCachedImage:anImage forURL:theURL];
                callback(nil, @[anImage], @[theURL]);
            }
        }
        
        if(fileError != nil)
        {
            callback(fileError, @[anImage], nil);
        }
    }
}

+(void) extractFaceImageFromPickedImage:(UIImage*) startImage withCallback:(handleExtractedFaces_t)callback
{
    [[GHImageCache loadQueue] addOperationWithBlock:^{
        
        int exifOrientation = 1;
        switch (startImage.imageOrientation) {
            case UIImageOrientationUp:
                exifOrientation = 1;
                break;
            case UIImageOrientationDown:
                exifOrientation = 3;
                break;
            case UIImageOrientationLeft:
                exifOrientation = 8;
                break;
            case UIImageOrientationRight:
                exifOrientation = 6;
                break;
            case UIImageOrientationUpMirrored:
                exifOrientation = 2;
                break;
            case UIImageOrientationDownMirrored:
                exifOrientation = 4;
                break;
            case UIImageOrientationLeftMirrored:
                exifOrientation = 5;
                break;
            case UIImageOrientationRightMirrored:
                exifOrientation = 7;
                break;
            default:
                break;
        }
        
        NSNumber *orientation = [NSNumber numberWithInt:exifOrientation];
        NSDictionary *imageOptions =
        [NSDictionary dictionaryWithObject:orientation
                                    forKey:CIDetectorImageOrientation];
        
        CIImage *ciimage = [CIImage imageWithCGImage:[startImage CGImage]
                                             options:imageOptions];
        
        
        NSDictionary *detectorOptions =
        [NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh
                                    forKey:CIDetectorAccuracy];
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                                  context:nil
                                                  options:detectorOptions];
        
        __block NSMutableArray* faceImages = [[NSMutableArray alloc] initWithCapacity:64];
        __block NSMutableArray* urls = [[NSMutableArray alloc] initWithCapacity:64];
        
        NSArray *features = [detector featuresInImage:ciimage];
        
        __block NSError* saveError = nil;
        
        for(id aFeature in features)
        {
            if([aFeature isKindOfClass:[CIFaceFeature class]])
            {
#if TARGET_IPHONE_SIMULATOR
                NSDictionary* options = @{};
#else 
                NSDictionary* options =@{kCIContextUseSoftwareRenderer:@1};
#endif
                
                CIContext* coreImageContext = [CIContext contextWithOptions:options];
                CIFaceFeature* faceFeature = (CIFaceFeature*)aFeature;
                CGRect faceRect = faceFeature.bounds;
                if(faceRect.size.height >= 128 && faceRect.size.width >= 128)
                {
                    CGFloat extraForehead = faceRect.size.height*.38;
                    CGFloat extraChin = faceRect.size.height*.06;
                    CGRect imageExtent = [ciimage extent];
                    switch(exifOrientation)
                    {
                        case 1:
                        {
                            CGFloat availableForehead = imageExtent.size.height-(faceRect.origin.y+faceRect.size.height);
                            if(extraForehead > availableForehead)extraForehead = availableForehead;
                            faceRect.size.height+=extraForehead;
                            CGFloat availableChin = faceRect.origin.y;
                            if(extraChin > availableChin) extraChin = availableChin;
                            
                            faceRect.origin.y-=extraChin;
                            faceRect.size.height+=extraChin;
                            
                        }
                        break;
                        case 3:
                        {
                            CGFloat availableForehead = faceRect.origin.y;
                            if(extraForehead > availableForehead)extraForehead = availableForehead;
                            faceRect.origin.y-=extraForehead;
                            faceRect.size.height+=extraForehead;
                            
                            CGFloat availableChin = imageExtent.size.height-(faceRect.origin.y+faceRect.size.height);
                            if(extraChin > availableChin)extraChin = availableChin;
                            faceRect.size.height+=extraChin;

                        }
                        break;
                    }
                    
                    
                    CGImageRef cgImage = [coreImageContext createCGImage:ciimage fromRect:faceRect];
                    UIImage *croppedFace = [UIImage imageWithCGImage:cgImage];
                    CGImageRelease(cgImage);
                    
                    [self saveImage:croppedFace withCallback:^(NSError* anError, NSArray* oneImageArray, NSArray* oneLocationArray) {
                        if(anError != nil)
                        {
                            saveError = anError;
                        }
                        else
                        {
                            [faceImages addObjectsFromArray:oneImageArray];
                            [urls addObjectsFromArray:oneLocationArray];
                        }
                    }];
                    if(saveError != nil)
                    {
                        break;
                    }
                }
            }
        }
        if(faceImages.count)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kFacesAddedToCacheNotificationName object:self userInfo:@{kFacesAddedKey:faceImages, kFacesURLsAddedKey:urls}];
        }
        callback(saveError, faceImages, urls);
        
    }];
}

@end

