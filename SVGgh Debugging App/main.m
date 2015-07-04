//
//  main.m
//  SVGgh Debugging App
//
//  Created by Glenn Howes on 6/11/15.
//  Copyright (c) 2015 Generally Helpful. All rights reserved.
//

#if !__has_feature(modules)
#import <UIKit/UIKit.h>
#else
@import UIKit;
#endif


#import "SVGghDebuggingAppDelegate.h"

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([SVGghDebuggingAppDelegate class]));
    }
}
