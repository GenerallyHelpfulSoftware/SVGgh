//
//  CrossPlatformImage.m
//  SVGgh
//
//  Created by Glenn Howes on 9/17/21.
//  Copyright © 2021 Generally Helpful. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CrossPlatformImage.h"

@implementation GHImageWrapper
-(instancetype) initWithCGImage:(CGImageARCRef)image
{
    if(NULL != (self = [super init]))
    {
        self.cgImage = image;
    }
    return self;
}
@end
