//
//  AttributedObject.h
//  SVGgh
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
//  Created by Glenn Howes on 2/3/13.


#if defined(__has_feature) && __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

NS_ASSUME_NONNULL_BEGIN


/*! @brief basically just a wrapper around an NSDictionary. A convenient object when generating from XML
*/
@interface GHAttributedObject : NSObject
@property (strong, nonatomic, readonly) NSDictionary*  	attributes;

-(instancetype) initWithDictionary:(NSDictionary*)theAttributes;
-(instancetype) initWithAttributes:(NSDictionary*)theAttributes;


-(NSUInteger)calculatedHash; // attributed objects are immutable, I can calculate their hash once and be done with it.
@end
// useful in parsing XML
extern  NSString*  	const kAttributesElementName;
extern  NSString*  	const kContentsElementName;
extern  NSString*  	const kElementName;
extern  NSString*  	const kElementText;
extern  NSString*  	const kElementData;
extern  NSString*  	const kLengthIntoParentsContents;


NS_ASSUME_NONNULL_END
