//
//  AttributedObject.h
//  Vectored
//
//  Created by Glenn Howes on 2/3/13.
//  Copyright (c) 2013 Generally Helpful Software. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface AttributedObject : NSObject
@property (strong, nonatomic, readonly) NSDictionary*	attributes;

-(id) initWithDictionary:(NSDictionary*)theAttributes;
-(id) initWithAttributes:(NSDictionary*)theAttributes;


-(NSUInteger)calculatedHash; // attributed objects are immutable, I can calculate their hash once and be done with it.
@end




extern NSString*	const kAttributesElementName;
extern NSString*	const kContentsElementName;
extern NSString*	const kElementName;
extern NSString*	const kElementText;
extern NSString*	const kElementData;
extern NSString*	const kLengthIntoParentsContents;
