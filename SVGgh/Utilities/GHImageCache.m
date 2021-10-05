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
@import ImageIO;
@import CoreServices;
@import Foundation;
@import UIKit;
#else

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
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

+(void) setCachedImage:(GHImageWrapper*) anImage forURL:(NSURL*) aFileURL
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

+(void) cacheImage:(GHImageWrapper*)anImage forName:(NSString*)aName
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

+(GHImageWrapper*) uncacheImageForName:(NSString*)aName
{
    NSCache* myCache = [GHImageCache imageCache];
    GHImageWrapper* result = [myCache objectForKey:aName];
    if([result isKindOfClass:[NSNull class]])
    {
        return NULL;
    }
    return result;
}

+(void) retrieveCachedImageFromURL:(NSURL*)aURL intoCallback:(handleRetrievedImage_t)retrievalCallback
{
    GHImageWrapper*  result = [[GHImageCache imageCache] objectForKey:aURL.absoluteString];
    if(result != nil)
    {
        if([result isKindOfClass:[NSNull class]])
        {
            retrievalCallback(nil, aURL);
        }
        else
        {
            retrievalCallback(result, aURL);
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
            CGDataProviderRef otherProvider = CGDataProviderCreateWithURL((__bridge CFURLRef) aURL);
            if(otherProvider != 0)
            {
                CGImageSourceRef imageSource = CGImageSourceCreateWithDataProvider(otherProvider, NULL);
                if(imageSource != 0)
                {
                    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
                    CFRelease(imageSource);
                }
                CFRelease(otherProvider);
            }
		}
		if(imageRef != 0)
		{
			result = [[GHImageWrapper alloc] initWithCGImage: imageRef];
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
    if(paths.count <= 0)
    {
        callback(nil, nil);
        return;
    }
    
    NSString *basePath = [paths objectAtIndex:0];
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
            [self retrieveCachedImageFromURL:theURL intoCallback:^(GHImageWrapper* anImage, NSURL *location) {
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
                        CGDataProviderRef imageProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef)imageData);
                        if(imageProvider != 0)
                        {
                            CGImageSourceRef imageSource = CGImageSourceCreateWithDataProvider(imageProvider, NULL);
                            if(imageSource != 0)
                            {
                                CGImageRef myImage = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
                                
                                GHImageWrapper* wrappedImage = [[GHImageWrapper alloc] initWithCGImage:myImage];
                                CFRelease(myImage);
                                [self setCachedImage:wrappedImage forURL:theURL];
                                
                                [[NSNotificationCenter defaultCenter] postNotificationName:kImageAddedToCacheNotificationName object:self userInfo:@{kImageAddedKey:wrappedImage, kImageURLAddedKey:theURL}];
                                callback(wrappedImage, theURL);
                                CFRelease(imageSource);
                            }
                            else
                            {
                                callback(nil, nil);
                            }
                            CFRelease(imageProvider);
                        }
                        else
                        {
                            callback(nil, nil);
                        }
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
                CGDataProviderRef imageProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef)imageData);
                if(imageProvider != 0)
                {
                    CGImageSourceRef imageSource = CGImageSourceCreateWithDataProvider(imageProvider, NULL);
                    if(imageSource != 0)
                    {
                        CGImageRef myImage = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
                        
                        GHImageWrapper* wrappedImage = [[GHImageWrapper alloc] initWithCGImage:myImage];
                        CFRelease(myImage);
                        [self setCachedImage:wrappedImage forURL:theURL];
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:kImageAddedToCacheNotificationName object:self userInfo:@{kImageAddedKey:wrappedImage, kImageURLAddedKey:theURL}];
                        callback(wrappedImage, theURL);
                        CFRelease(imageSource);
                    }
                    CFRelease(imageProvider);
                }
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

+(void) saveImageData:(NSData*) imageData withExtension:(NSString*)extension forImage:(CGImageARCRef) anImage withCallback:(handleExtractedFaces_t)callback
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if(paths.count == 0)
    {
        return; // should never happen
    }
    NSString *basePath = [paths objectAtIndex:0];
    NSFileManager* localFileManager = [[NSFileManager alloc] init];
    NSString* pathToImages = [basePath stringByAppendingPathComponent:@"Photos"];
    NSError* fileError = nil;
    if(![localFileManager fileExistsAtPath:pathToImages])
    {
        [localFileManager createDirectoryAtPath:pathToImages withIntermediateDirectories:YES attributes:nil error:&fileError];
    }
    GHImageWrapper* imageWrapper = [[GHImageWrapper alloc] initWithCGImage:anImage];
    if(fileError == nil)
    {
        NSString* pathToImage = [pathToImages stringByAppendingPathComponent: [self uniqueFilenameWithExtension:extension]];
        [imageData writeToFile:pathToImage options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen  error:&fileError];
        if(fileError == nil)
        {
            NSURL* theURL = [NSURL fileURLWithPath:pathToImage];
            [self setCachedImage:imageWrapper forURL:theURL];
            callback(nil, @[imageWrapper], @[theURL]);
        }
    }
    
    if(fileError != nil)
    {
        callback(fileError, @[imageWrapper], nil);
    }
}

+(void) saveImage:(CGImageARCRef)anImage withCallback:(handleExtractedFaces_t)callback
{
    if(anImage != nil)
    {
        CFMutableDataRef dataToFill = CFDataCreateMutable(nil, 0);
        CGImageDestinationRef destination = CGImageDestinationCreateWithData(dataToFill, kUTTypePNG, 1, nil);
        
        if(destination != 0)
        {
            CGImageDestinationAddImage(destination, anImage, nil);
            if (CGImageDestinationFinalize(destination))
            {
                if(CFDataGetLength(dataToFill) > 65635)
                {
                    CFRelease(dataToFill);
                    CFRelease(destination);
                    dataToFill = CFDataCreateMutable(nil, 0);
                    destination = CGImageDestinationCreateWithData(dataToFill, kUTTypeJPEG, 1, nil);
                    
                    if(destination != 0)
                    {
                        CGImageDestinationAddImage(destination, anImage, nil);
                        if (CGImageDestinationFinalize(destination))
                        {
                            [self saveImageData:CFBridgingRelease(dataToFill) withExtension:@"jpg" forImage:anImage withCallback:callback];
                        }
                        
                        CFRelease(destination);
                        destination = 0;
                    }
                    
                }
                else
                {
                    [self saveImageData:CFBridgingRelease(dataToFill) withExtension:@"png" forImage:anImage withCallback:callback];
                }
            }
            if(destination != 0)
            {
                CFRelease(destination);
            }
        }
        CFRelease(dataToFill);
    }
}

@end

