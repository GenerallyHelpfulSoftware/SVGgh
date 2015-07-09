//
//  AttributedObject.m
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
//
//  Created by Glenn Howes on 2/3/13.
//

#import "GHAttributedObject.h"



NSString*	const kAttributesElementName = @"attributes";
NSString*	const kContentsElementName = @"contents";
NSString*	const kElementName		=	@"name";
NSString*	const kElementText		= @"text";
NSString*	const kElementData		= @"data";
NSString*	const kLengthIntoParentsContents = @"parentContentLocation"; // for objects that modify another object's text

@interface GHAttributedObject()
@property(nonatomic, assign)NSUInteger calculatedHash;
@end

@implementation GHAttributedObject
@synthesize attributes=_attributes;


-(instancetype) initWithAttributes:(NSDictionary*)theAttributes
{
    if(nil != (self = [self init]))
	{
		_attributes = theAttributes;
	}
	return self;
}

-(instancetype) initWithDictionary:(NSDictionary*)theDefinition
{
    NSDictionary* theAttributes = [theDefinition objectForKey:kAttributesElementName];
	if(nil != (self = [self initWithAttributes:theAttributes]))
	{
		_attributes = theAttributes;
        _calculatedHash = NSNotFound;
	}
	return self;
}

-(NSUInteger) hash
{
    if(self.calculatedHash == NSNotFound)
    {
        _calculatedHash = [self calculatedHash];
    }
    return self.calculatedHash;
}

-(NSUInteger)calculatedHash
{
    NSUInteger result = self.attributes.hash;
    return result;
}

-(BOOL)isEqual:(id)object
{
    BOOL result = self == object;
    
    if(!result && ([object class] == [self class]))
    {
        result = [[object attributes] isEqual:self.attributes];
    }
    
    return result;
}

-(NSString*) description
{
    NSString* result = [self.attributes description];
    return result;
}


@end
