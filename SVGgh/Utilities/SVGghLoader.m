//
//  SVGghLoader.m
//  SVGgh
//
//  Created by Glenn Howes on 4/27/16.
//  Copyright © 2016 Generally Helpful. All rights reserved.
//

#import "SVGghLoader.h"
#import "SVGRenderer.h"

static id<SVGghLoader> gLoader = nil;

@interface SVGghPathLoader : NSObject<SVGghLoader>

@end

@interface SVGXCAssetLoader : NSObject<SVGghLoader>

@end

@implementation SVGghLoaderManager


+(id<SVGghLoader>) loader
{
    id<SVGghLoader> result = gLoader;
    if(result == nil)
    {
        static id<SVGghLoader> sDefault = nil;
        static dispatch_once_t  done;
        dispatch_once(&done, ^{
            sDefault = [SVGghPathLoader new];
            
        });
        result = sDefault;
    }
    return result;
}

+(BOOL) assetLoadingAvailable
{
#if TARGET_OS_OSX
    return YES;
#else
    NSString* systemVersion = [UIDevice currentDevice].systemVersion;
    return systemVersion.doubleValue >= 9.0;
#endif
    
}

+(void) setLoader:(nullable id<SVGghLoader>)loader
{
    gLoader = loader;
}

+(void) setLoaderToType:(SVGghLoaderType)type
{
    switch(type)
    {
        case SVGghLoaderTypeDefault:
            [self setLoader:nil];
        break;
        case SVGghLoaderTypePath:
            [self setLoader:nil];
        break;
        case SVGghLoaderTypeDataXCAsset:
        {
            if([SVGghLoaderManager assetLoadingAvailable])
            {
                [self setLoader:[SVGXCAssetLoader new]];
            }
            else
            {
                NSLog(@"Failed to use SVGghLoaderTypeDataXCAsset for pre-iOS 9 target.");
            }
        }
        break;
    }
}

@end

@implementation SVGghPathLoader
-(nullable SVGRenderer*) loadRenderForSVGIdentifier:(NSString*)identifier inBundle:(NSBundle*)bundle
{
    SVGRenderer* result = [[SVGRenderer alloc] initWithResourceName:identifier inBundle:bundle];
    return result;
}

@end

@implementation SVGXCAssetLoader

-(nullable SVGRenderer*) loadRenderForSVGIdentifier:(NSString*)identifier inBundle:(NSBundle*)bundle
{
    SVGRenderer* result = [[SVGRenderer alloc] initWithDataAssetNamed:identifier withBundle: bundle];
    return result;
}

@end
