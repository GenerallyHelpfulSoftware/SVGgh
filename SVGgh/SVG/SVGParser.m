//
//  SVGParser.m
//  SVGgh
// The MIT License (MIT)

//  Copyright (c) 2011-2014 Glenn R. Howes

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

//  Created by Glenn Howes on 2/2/11.
//

@import UIKit;
#import "SVGParser.h"
#import "GHAttributedObject.h"

@interface SVGParser ()
@property(nonatomic, strong) NSError* __nullable 	parserError;
@property(nonatomic, strong) NSMutableDictionary*	__nullable mutableRoot;
@property(nonatomic, strong) NSDictionary*          __nullable root;
@property(nonatomic, assign) BOOL					insideSVG;
@property(nonatomic, strong) NSMutableArray*		__nullable groupStack;
@end

@interface SVGParser (Private)<NSXMLParserDelegate>

@end

@implementation SVGParser(Private)



- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock
{
	NSMutableDictionary*	currentObject = [self.groupStack lastObject];
	[currentObject setObject:CDATABlock forKey:kElementData];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	NSMutableDictionary*	currentObject = [self.groupStack lastObject];
	NSString*	currentObjectString = [currentObject objectForKey:kElementText];
	if(currentObjectString != nil)
	{
		currentObjectString = [currentObjectString stringByAppendingString:string];
	}
	else 
	{
		currentObjectString = string;
	}
	[currentObject setObject:currentObjectString forKey:kElementText];
	
	
	
	NSMutableArray*	currentObjectContent = [currentObject objectForKey:kContentsElementName];
	if(currentObjectContent == nil)
	{
		currentObjectContent = [[NSMutableArray alloc] initWithObjects:string, nil];
		[currentObject setObject:currentObjectContent forKey:kContentsElementName];
	}
	else
	{
		id lastObject = [currentObjectContent lastObject];
		if([lastObject isKindOfClass:[NSString class]])
		{
			NSString*	newLastObject = [lastObject stringByAppendingString:string];
			[currentObjectContent removeLastObject];
			[currentObjectContent addObject:newLastObject];
			
		}
		else
		{
			[currentObjectContent addObject:string];
		}
	}

}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
				namespaceURI:(NSString *)namespaceURI 
				qualifiedName:(NSString *)qName 
				attributes:(NSDictionary *)attributeDict
{
	if([elementName isEqualToString:@"svg"] && self.mutableRoot == nil)
	{
		self.insideSVG = YES;
        NSMutableDictionary* newRoot = [NSMutableDictionary dictionary];
		self.mutableRoot = newRoot;
		self.groupStack	= [[NSMutableArray alloc] initWithObjects:newRoot, nil];
		[newRoot setObject:attributeDict forKey:kAttributesElementName];
		[newRoot setObject:elementName forKey:kElementName];
	}
	else if (self.insideSVG)
	{
		NSMutableDictionary*	currentObject = [self.groupStack lastObject];
		
        NSString* currentObjectsText = [currentObject objectForKey:kElementText];
        NSNumber*   indexIntoParentNumber = nil;
        if([currentObjectsText length])
        {
            indexIntoParentNumber = [[NSNumber alloc] initWithUnsignedInteger:[currentObjectsText length]];
        }
		
        
		NSMutableDictionary* anElement = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    elementName, kElementName, 
                                    attributeDict, kAttributesElementName,
                                    indexIntoParentNumber, kLengthIntoParentsContents, //note use of probably nil indexIntoParentNumber
											nil];
		
		NSMutableArray*	currentObjectContent = [currentObject objectForKey:kContentsElementName];
		if(currentObjectContent == nil)
		{
			currentObjectContent = [[NSMutableArray alloc] initWithObjects:anElement, nil];
			[currentObject setObject:currentObjectContent forKey:kContentsElementName];
		}
		else
		{
			[currentObjectContent addObject:anElement];
		}
		[self.groupStack addObject:anElement];
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	if (self.insideSVG)
	{
		[self.groupStack removeLastObject];
	}
}

@end


@implementation SVGParser

-(instancetype)initWithString:(NSString*)utf8String
{
    if(nil != (self = [super init]))
	{
        NSData* stringAsData = [utf8String dataUsingEncoding:NSUTF8StringEncoding];
		NSXMLParser* theParser = [[NSXMLParser alloc] initWithData:stringAsData];
		[theParser setDelegate:self];
		[theParser parse];
        self.parserError = [theParser parserError];
        self.root = [self.mutableRoot copy];
	}
	return self;
}

- (instancetype)initWithContentsOfURL:(NSURL *)url
{
	if(nil != (self = [super init]))
	{
		NSXMLParser* theParser = [[NSXMLParser alloc] initWithContentsOfURL:url];
		[theParser setDelegate:self];
		_svgURL = url;
		[theParser parse];
		self.parserError = [theParser parserError];
        self.root = [self.mutableRoot copy];
	}
	return self;
}

-(nullable  instancetype) initWithResourceName:(NSString*)resourceName inBundle:(nullable NSBundle*)mayBeNil
{
    NSBundle* bundleToUse = (mayBeNil == nil)? [NSBundle mainBundle] : mayBeNil;
    NSURL* theURL = [bundleToUse URLForResource:resourceName withExtension:@"svg"];
    if(theURL == NULL)
    {
        return NULL;
    }
    else
    {
        if(nil != (self = [self initWithContentsOfURL:theURL]))
        {
        }
    }
    return self;
}

-(nullable instancetype) initWithDataAssetNamed:(NSString*)assetName withBundle:(nullable NSBundle*)bundle
{
    Class dataAssetClass = NSClassFromString(@"NSDataAsset");
    if(dataAssetClass != nil)
    {
        NSDataAsset* asset = [(NSDataAsset*)[dataAssetClass alloc] initWithName:assetName bundle: bundle];
        if(asset == nil || asset.data.length == 0)
        {
           return nil;
        }
        else  if(nil != (self = [super init]))
        {
            NSXMLParser* theParser = [[NSXMLParser alloc] initWithData:asset.data];
            [theParser setDelegate:self];
            [theParser parse];
            self.parserError = [theParser parserError];
            self.root = [self.mutableRoot copy];
            if(self.parserError != nil)
            {
                self = nil;
            }
        }
    }
    else
    {
        return nil;
    }
    return self;
    
}

-(nullable NSDictionary*) root
{
    NSDictionary* result = _root;
    if(result == nil)
    {
        result = [self.mutableRoot copy];
    }
    return result;
}

-(NSURL*)	relativeURL:(NSString*)subPath
{
    NSURL*	result = nil;
    if(self.svgURL != nil)
    {
        result = [self.svgURL URLByDeletingLastPathComponent];
        result = [result URLByAppendingPathComponent:subPath];
    }
	return result;
}

-(NSURL*)   absoluteURL:(NSString*)absolutePath
{// keeping things within the ios sandbox
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    basePath = [basePath stringByDeletingLastPathComponent];
    NSString* fullPath = [basePath stringByAppendingString:absolutePath];
    return [NSURL fileURLWithPath:fullPath];
}

@end
