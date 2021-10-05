//
//  CrossPlatformImage.h
//  SVGgh
//
//  Created by Glenn Howes on 9/17/21.
//  Copyright © 2021 Generally Helpful. All rights reserved.
//

#ifndef CrossPlatformImage_h
#define CrossPlatformImage_h

#if defined(__has_feature) && __has_feature(modules)
@import Foundation;
@import QuartzCore;
#else
#import <Foundation/Foundation.h>
#endif

NS_ASSUME_NONNULL_BEGIN
typedef CGImageRef CGImageARCRef __attribute__((NSObject));

@interface GHImageWrapper : NSObject
@property(nonatomic, retain) CGImageARCRef cgImage;
-(instancetype) initWithCGImage:(CGImageARCRef)image;
@end

#endif /* CrossPlatformImage_h */


NS_ASSUME_NONNULL_END
