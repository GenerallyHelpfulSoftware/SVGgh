//
//  SVGPathGenerator.m
//  SVGgh
// The MIT License (MIT)

//  Copyright (c) 2012-2014 Glenn R. Howes

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
//  Created by Glenn Howes on 12/31/12.


#import "SVGPathGenerator.h"
#import "SVGUtilities.h"
#import "GHPathUtilities.h"

@interface NSMutableAttributedString (GH)
- (void)setAttributes:(NSDictionary *)attrs forCharactersInSet:(NSCharacterSet*)aSet;
@end

@implementation NSMutableAttributedString (GH)
- (void)setAttributes:(NSDictionary *)attrs forCharactersInSet:(NSCharacterSet*)aSet
{
    NSRange rangeOfSet = [self.string rangeOfCharacterFromSet:aSet];
    NSUInteger stringLength = self.string.length;
    while(rangeOfSet.location != NSNotFound)
    {
        [self setAttributes:attrs range:rangeOfSet];
        if(rangeOfSet.location+rangeOfSet.length < stringLength)
        {
            NSRange searchRange = NSMakeRange(rangeOfSet.location+rangeOfSet.length,
                                stringLength-rangeOfSet.location-rangeOfSet.length);
            rangeOfSet = [self.string rangeOfCharacterFromSet:aSet options:0 range:searchRange];
        }
        else
        {
            break;
        }
    }
}

@end

@interface NSString(GH)
-(NSString*)stringByRemovingCharactersInSet:(NSCharacterSet*)removeSet;
@end

@implementation NSString(GH)
-(NSString*)stringByRemovingCharactersInSet:(NSCharacterSet*)removeSet
{
    NSString* result = nil;
    NSRange rangeOfSet = [self rangeOfCharacterFromSet:removeSet];
    if(rangeOfSet.location == NSNotFound)
    {
        NSMutableString* mutableResult = [self mutableCopy];
        
        NSRange searchRange = NSMakeRange(0, mutableResult.length);
        NSRange backRange = [mutableResult rangeOfCharacterFromSet:removeSet options:NSBackwardsSearch range:searchRange];
        while(backRange.location != NSNotFound)
        {
            [mutableResult replaceCharactersInRange:backRange withString:@""];
            if(backRange.location == 0)
            {
                break;
            }
            else
            {
                searchRange = NSMakeRange(0, backRange.location);
                backRange = [mutableResult rangeOfCharacterFromSet:removeSet options:NSBackwardsSearch range:searchRange];
            }
        }
        result = [mutableResult copy];
    }
    else
    {
        result = [self copy];
    }
    
    return result;
}

@end

int ParameterCountForOperator(unichar anOperator)
{
    int result = 0;
    switch(anOperator)
    {
        case 'L':
        case 'l':
        case 'm':
        case 'M':
        case 'T':
        case 't':
            result = 2;
        break;
        case 'H':
        case 'h':
        case 'V':
        case 'v':
            result = 1;
        break;
        case 'z':
        case 'Z':
            result = 0;
        break;
        case 'Q':
        case 'q':
        case 's':
        case 'S':
            result = 4;
        break;
        case 'C':
        case 'c':
            result = 6;
        break;
        case 'A':
        case 'a':
            result = 7;
        break;
        default:
            NSLog(@"Unknown parameter:%@", [[NSString alloc] initWithCharacters:&anOperator length:1]);
        break;
    }
    return result;
}

@interface PathValidationResult()
// redefining the properties so that I can present a non-mutable interface for this object (see header file). 
@property(nonatomic, assign) NSRange rangeOfError;
@property(nonatomic, assign) SVGPathValidationError errorCode;
@property(nonatomic, assign) unsigned char  operatorAtError;
@property(nonatomic, assign) BOOL   errorInLastOperation;
@property(nonatomic, copy) NSString* __nullable  unexpectedCharacters;

@end

@implementation PathValidationResult

@end

@implementation SVGPathGenerator
+(NSCharacterSet*)invalidPathCharacters
{
    static NSCharacterSet* sResult = nil;
    static dispatch_once_t  done;
    dispatch_once(&done, ^{
        sResult = [[NSCharacterSet characterSetWithCharactersInString:@"mMlLtTsScCqQaAzZhHvV0123456789-. \n"] invertedSet];
    });
    return sResult;
}

+(CGRect) addPoint:(CGPoint)aPoint toRect:(CGRect)aRect
{
    CGRect result = aRect;
    if(CGRectIsNull(aRect))
    {
        result = CGRectMake(aPoint.x, aPoint.y, 0, 0);
    }
    else if(!CGRectContainsPoint(result, aPoint))
    {
        CGRect pointRect = CGRectMake(aPoint.x, aPoint.y, 0, 0);
        result = CGRectUnion(pointRect, result);
    }
    return result;
}

+(NSInteger) parametersNeededForOperator:(unsigned char)svgOperator
{
    NSInteger result = 0;
    switch(svgOperator)
    {
        case 'm':
        case 'M': // absolute moveto
        {
            result = 2;
        }
        break;
            
        case 'Z':
        case 'z': // close path
        {
            result = 0;
        }
        break;
        case 'l':
        case 'L': // absolute lineto
        {
            result = 2;
        }
        break;
        case 'h':
        case 'H':// absolute horizontal lineto
        case 'v':
        case 'V': // absolute vertical lineto
        {
            result = 1;
        }
        break;
        case 'c':
        case 'C': // absolute Cubic Bezier curve
        {
            result = 6;
        }
        break;
        case 's':
        case 'S': // absolute shorthand Cubic Bezier curve
        {
            result = 4;
        }
        break;
        case 'q':
        case 'Q': // quadratic Bezier curve
        {
            result = 4;
        }
        break;
        case 't':
        case 'T': // absolute shorthand quadratic Bezier curve
        {
            result = 2;
        }
            break;
        case 'a':
        case 'A': // absolute elliptical Arc segment
        {
            result = 7;
        }
        break;
            
        default:
        {
            result = 0;
        }
        break;
    }
    return result;
}

+(NSString*)insertionStringForPoint:(CGPoint)transformedPoint intoString:(NSString*)anSVGPath atRange:(NSRange)insertionRange
{
    NSString* result = nil;

    NSRange startRange = [anSVGPath rangeOfCharacterFromSet:[[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet]];
    insertionRange.location-=startRange.location;
    NSString* pathToRender = [anSVGPath substringFromIndex:startRange.location];
    pathToRender = [pathToRender substringToIndex:insertionRange.location];
    if(pathToRender.length)
    {
        NSData* asciiData = [pathToRender dataUsingEncoding:NSASCIIStringEncoding];
        NSUInteger	dataLength = [asciiData length];
        const char*		rawData = (const char*)[asciiData bytes];
        NSUInteger	index = 0;
        char	activeOperator = 'M';
        CGFloat	lastCubicControlX = CGFLOAT_MAX;
        CGFloat	lastCubicControlY = CGFLOAT_MAX;
        
        CGFloat	lastQuadraticControlX = CGFLOAT_MAX;
        CGFloat	lastQuadraticControlY = CGFLOAT_MAX;
        
        CGPoint currentPoint = CGPointZero;
        BOOL failed = NO;
        while(index < dataLength && !failed)
        {
            char anOperator = rawData[index];
            if((anOperator >= 'a' && anOperator <= 'z') || (anOperator >= 'A' && anOperator <= 'Z'))
            { // is there a new activeOperator, or should we continue to treat numbers like they had gotten the previous activeOperator
                activeOperator = rawData[index++]; // new activeOperator
            }
            
            BOOL isAbsolute = activeOperator >= 'A' && activeOperator <= 'Z';
            switch(activeOperator)
            {
                case 'm':
                case 'M': // absolute moveto
                {
                    CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    if(!failed)
                    {
                        if(isAbsolute)
                        {
                            currentPoint = CGPointMake(xCoord, yCoord);
                        }
                        else
                        {
                            currentPoint = CGPointMake(currentPoint.x+xCoord, currentPoint.y+yCoord);
                        }
                    }
                    lastCubicControlX = CGFLOAT_MAX;
                    lastQuadraticControlX = CGFLOAT_MAX;
                    if(!failed)
                        activeOperator = 'L'; // subsequent implied operations will be absolute line to's
                }
                break;
                    
                case 'Z':
                case 'z': // close path
                {
                    lastCubicControlX = CGFLOAT_MAX;
                    lastQuadraticControlX = CGFLOAT_MAX;
                    
                    if(index < (dataLength-1))
                    {
                        char nextOperator = rawData[index];
                        if(nextOperator != 'z' &&
                           ((nextOperator >= 'a' && nextOperator <= 'z') ||
                            (nextOperator >= 'A' && nextOperator <= 'Z')))
                        {
                            
                        }
                        else
                        {
                            index++;
                        }
                    }
                    else
                    {
                        index++;
                    }
                }
                break;
                case 'l':
                case 'L': // absolute lineto
                {
                    CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    if(!failed)
                    {
                        if(isAbsolute)
                        {
                            currentPoint = CGPointMake(xCoord, yCoord);
                        }
                        else
                        {
                            currentPoint = CGPointMake(currentPoint.x+xCoord, currentPoint.y+yCoord);
                        }
                    }
                    
                    lastCubicControlX = CGFLOAT_MAX;
                    lastQuadraticControlX = CGFLOAT_MAX;
                }
                break;
                case 'h':
                case 'H':// absolute horizontal lineto
                {
                    CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    CGFloat yCoord = currentPoint.y;
                    if(!failed)
                    {
                        if(isAbsolute)
                        {
                            currentPoint = CGPointMake(xCoord, yCoord);
                        }
                        else
                        {
                            currentPoint = CGPointMake(currentPoint.x+xCoord, currentPoint.y+yCoord);
                        }
                    }
                    lastCubicControlX = CGFLOAT_MAX;
                    lastQuadraticControlX = CGFLOAT_MAX;
                }
                break;
                    
                case 'v':
                case 'V': // absolute vertical lineto
                {
                    CGFloat	xCoord = currentPoint.x;
                    CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    if(!failed)
                    {
                        if(isAbsolute)
                        {
                            currentPoint = CGPointMake(xCoord, yCoord);
                        }
                        else
                        {
                            currentPoint = CGPointMake(currentPoint.x+xCoord, currentPoint.y+yCoord);
                        }
                    }
                    
                    lastCubicControlX = CGFLOAT_MAX;
                    lastQuadraticControlX = CGFLOAT_MAX;
                }
                break;
                    
                case 'c':
                case 'C': // absolute Cubic Bezier curve
                {
                    (void)GetNextCoordinate(rawData, &index, dataLength, &failed);
                    (void)GetNextCoordinate(rawData, &index, dataLength, &failed);
                    CGFloat	xControl2 = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    CGFloat	yControl2 = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    
                    if(!failed)
                    {
                        if(isAbsolute)
                        {
                            currentPoint = CGPointMake(xCoord, yCoord);
                        }
                        else
                        {
                            currentPoint = CGPointMake(currentPoint.x+xCoord, currentPoint.y+yCoord);
                        }
                        
                    }
                    lastCubicControlX = xControl2;
                    lastCubicControlY = yControl2;
                    lastQuadraticControlX = CGFLOAT_MAX;
                }
                break;
                    
                case 's':
                case 'S': // absolute shorthand Cubic Bezier curve
                {
                    if(lastCubicControlX == CGFLOAT_MAX)
                    {
                    }
                    else if(lastCubicControlY == CGFLOAT_MAX)
                    {
                    }
                    else
                    {
                        CGFloat	xControl2 = GetNextCoordinate(rawData, &index, dataLength, &failed);
                        CGFloat	yControl2 = GetNextCoordinate(rawData, &index, dataLength, &failed);
                        CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                        CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                        if(!failed)
                        {
                            if(isAbsolute)
                            {
                                currentPoint = CGPointMake(xCoord, yCoord);
                            }
                            else
                            {
                                currentPoint = CGPointMake(currentPoint.x+xCoord, currentPoint.y+yCoord);
                            }
                        }
                        lastCubicControlX = xControl2;
                        lastCubicControlY = yControl2;
                        lastQuadraticControlX = CGFLOAT_MAX;
                    }
                }
                break;
                    
                case 'q':
                case 'Q': // quadratic Bezier curve
                {
                    CGFloat	xControl1 = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    CGFloat	yControl1 = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    
                    if(!failed)
                    {
                        if(isAbsolute)
                        {
                            currentPoint = CGPointMake(xCoord, yCoord);
                        }
                        else
                        {
                            currentPoint = CGPointMake(currentPoint.x+xCoord, currentPoint.y+yCoord);
                        }
                    }
                    lastQuadraticControlX = xControl1;
                    lastQuadraticControlY = yControl1;
                    lastCubicControlX = CGFLOAT_MAX;
                }
                break;
                    
                case 't':
                case 'T': // absolute shorthand quadratic Bezier curve
                {
                    if(lastQuadraticControlX == CGFLOAT_MAX)
                    {
                    }
                    else if(lastQuadraticControlY == CGFLOAT_MAX)
                    {
                    }
                    else
                    {
                        CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                        CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                        CGFloat	xControl1 = currentPoint.x;
                        CGFloat yControl1 = currentPoint.y;
                        
                        xControl1 -= (lastQuadraticControlX-xControl1);
                        yControl1 -= (lastQuadraticControlY-yControl1);
                        if(!failed)
                        {
                            if(isAbsolute)
                            {
                                currentPoint = CGPointMake(xCoord, yCoord);
                            }
                            else
                            {
                                currentPoint = CGPointMake(currentPoint.x+xCoord, currentPoint.y+yCoord);
                            }
                        }
                        lastQuadraticControlX = xControl1;
                        lastQuadraticControlY = yControl1;
                        lastCubicControlX = CGFLOAT_MAX;
                    }
                }
                break;
                    
                case 'a':
                case 'A': // absolute elliptical Arc segment
                {
                    (void)GetNextCoordinate(rawData, &index, dataLength, &failed);
                    (void)GetNextCoordinate(rawData, &index, dataLength, &failed);
                    if(!failed)
                    {
                        CGFloat xRotation = GetNextCoordinate(rawData, &index, dataLength, &failed);
                        if(xRotation < -360 || xRotation > 360)
                        {
                            failed = YES;
                        }
                    }
                    if(!failed)
                    {
                        CGFloat	largeArcFlag = GetNextCoordinate(rawData, &index, dataLength, &failed);
                        if(!(largeArcFlag == 0 || largeArcFlag == 1))
                        {
                            failed = YES;
                        }
                    }
                    if(!failed)
                    {
                        CGFloat	sweepFlag = GetNextCoordinate(rawData, &index, dataLength, &failed);
                        if(!(sweepFlag == 0 || sweepFlag == 1))
                        {
                            failed = YES;
                        }
                    }
                    CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    if(!failed)
                    {
                        if(isAbsolute)
                        {
                            currentPoint = CGPointMake(xCoord, yCoord);
                        }
                        else
                        {
                            currentPoint = CGPointMake(currentPoint.x+xCoord, currentPoint.y+yCoord);
                        }
                    }
                    lastCubicControlX = CGFLOAT_MAX;
                    lastQuadraticControlX = CGFLOAT_MAX;
                }
                break;
                    
                default:
                {
                }
                break;
            }
            if(failed || index >= dataLength)
            {
                if(isAbsolute)
                {
                    if(activeOperator == 'V')
                    {
                        result = [NSString stringWithFormat:@" %0.0lf", transformedPoint.y];
                    }
                    else if(activeOperator == 'H')
                    {
                        result = [NSString stringWithFormat:@" %0.0lf", transformedPoint.x];
                    }
                    else
                    {
                        result = [NSString stringWithFormat:@" %0.0lf %0.0lf", transformedPoint.x, transformedPoint.y];
                    }
                }
                else
                {
                    CGFloat deltaX = transformedPoint.x-currentPoint.x;
                    CGFloat deltaY = transformedPoint.y-currentPoint.y;
                    if(activeOperator == 'v')
                    {
                        result = [NSString stringWithFormat:@" %0.0lf", deltaY];
                    }
                    else if(activeOperator == 'h')
                    {
                        result = [NSString stringWithFormat:@" %0.0lf", deltaX];
                    }
                    else
                    {
                        result = [NSString stringWithFormat:@" %0.0lf %0.0lf", deltaX, deltaY];
                    }
                    result = [result stringByReplacingOccurrencesOfString:@" -" withString:@"-"];
                }
            }
        }
    }

    return result;
}

+(NSRange) pointOperandRangeForString:(NSString*)svgPath selectionRange:(NSRange)selectionRange
{
    NSRange result = NSMakeRange(NSNotFound, 0);
    if(selectionRange.location != NSNotFound && selectionRange.location <= svgPath.length && selectionRange.location > 0)
    {
        NSCharacterSet* operatorCharacters = [NSCharacterSet characterSetWithCharactersInString:@"mMlLsStTcCqQaAzZhHvV"];
        BOOL selectingOperator = NO;
        if(selectionRange.length)
        {
            NSString* selectedCharacters = [svgPath substringWithRange:selectionRange];
            NSRange operatorRange = [selectedCharacters rangeOfCharacterFromSet:operatorCharacters];
            selectingOperator = operatorRange.location != NSNotFound;
        }
        if(!selectingOperator)
        {
            NSRange rangeOfpreviousOperand = [svgPath rangeOfCharacterFromSet:operatorCharacters options:NSBackwardsSearch
                                                                        range:NSMakeRange(0, selectionRange.location)];
            if(rangeOfpreviousOperand.location != NSNotFound && rangeOfpreviousOperand.length > 0)
            {
                
                NSData* asciiData = [svgPath dataUsingEncoding:NSASCIIStringEncoding];
                NSUInteger	dataLength = [asciiData length];
                const char*		rawData = (const char*)[asciiData bytes];
                NSUInteger	index = 0;
                
                if(rangeOfpreviousOperand.location >= (svgPath.length-1))
                {
                    index = dataLength-1;
                }
                else
                {
                    index = rangeOfpreviousOperand.location+1;
                }
                unichar pathOperator = [svgPath characterAtIndex:rangeOfpreviousOperand.location+rangeOfpreviousOperand.length-1];
                
                BOOL finished = NO;
                BOOL failed = NO;
                while(!finished)
                {
                    NSUInteger	startIndex = index;
                    switch(pathOperator)
                    {
                        case 'Z':
                        case 'z':
                        {
                            finished = YES;
                            failed = YES;
                        }
                        break;
                        case 'l':
                        case 'L':
                        case 'm':
                        case 'M':
                        case 'T':
                        case 't':
                        {
                            GetNextCoordinate(rawData, &index, dataLength, &finished);
                            if(!finished)
                                GetNextCoordinate(rawData, &index, dataLength, &finished);
                        }
                        break;
                        case 'h':
                        case 'H':
                        case 'v':
                        case 'V':
                        {
                            GetNextCoordinate(rawData, &index, dataLength, &finished);
                        }
                        break;
                        case 'a':
                        case 'A':
                        {
                            GetNextCoordinate(rawData, &index, dataLength, &finished);
                            GetNextCoordinate(rawData, &index, dataLength, &finished);
                            GetNextCoordinate(rawData, &index, dataLength, &finished);
                            GetNextCoordinate(rawData, &index, dataLength, &finished);
                            GetNextCoordinate(rawData, &index, dataLength, &finished);
                            if(finished || selectionRange.location< index)
                            {// not interested in flags, radiae or angles
                                failed = YES;
                            }
                            else
                            {
                                startIndex = index;
                                GetNextCoordinate(rawData, &index, dataLength, &finished);
                                if(!finished)
                                    GetNextCoordinate(rawData, &index, dataLength, &finished);
                            }
                        }
                        break;
                        case 's':
                        case 'S':
                        case 'q':
                        case 'Q':
                        {
                            GetNextCoordinate(rawData, &index, dataLength, &finished);
                            if(!finished)
                                GetNextCoordinate(rawData, &index, dataLength, &finished);
                            if(!finished)
                                GetNextCoordinate(rawData, &index, dataLength, &finished);
                            if(!finished)
                                GetNextCoordinate(rawData, &index, dataLength, &finished);
                        }
                        break;
                        case 'c':
                        case 'C':
                        {
                            GetNextCoordinate(rawData, &index, dataLength, &finished);
                            if(!finished)
                                GetNextCoordinate(rawData, &index, dataLength, &finished);
                            if(!finished)
                                GetNextCoordinate(rawData, &index, dataLength, &finished);
                            if(!finished)
                                GetNextCoordinate(rawData, &index, dataLength, &finished);
                            if(!finished)
                                GetNextCoordinate(rawData, &index, dataLength, &finished);
                            if(!finished)
                                GetNextCoordinate(rawData, &index, dataLength, &finished);
                        }
                        break;
                    }
                    
                    if(index > selectionRange.location)
                    {
                        if(failed == NO)
                        {
                            NSCharacterSet* notSpaceSet = [[NSCharacterSet characterSetWithCharactersInString:@" "] invertedSet];
                            if(startIndex < index)
                            { // backup over skipped spaces
                                NSRange rangeOfpreviousNonSpace = [svgPath rangeOfCharacterFromSet:notSpaceSet options:NSBackwardsSearch
                                                                                            range:NSMakeRange(startIndex, index-startIndex)];
                                if(rangeOfpreviousNonSpace.location != NSNotFound)
                                {
                                    index = rangeOfpreviousNonSpace.location+rangeOfpreviousNonSpace.length;
                                }
                            }
                            if(selectionRange.location>=index)
                            {
                                startIndex = index;
                            }
                            else
                            {
                                NSRange rangeOfpreviousNonSpace = [svgPath rangeOfCharacterFromSet:notSpaceSet options:NSBackwardsSearch
                                                                                     range:NSMakeRange(0, startIndex)];
                                if(rangeOfpreviousNonSpace.location != NSNotFound)
                                {
                                    startIndex = rangeOfpreviousNonSpace.location+rangeOfpreviousNonSpace.length;
                                }
                            }
                        }
                        finished = YES;
                    }
                    if(finished && !failed)
                    {
                        result = NSMakeRange(startIndex, index-startIndex);
                    }
                }
            }
        }
    }
    return result;
}


+(PathValidationResult*) findFailure:(NSString*)anSVGPath
{
    PathValidationResult* result = [[PathValidationResult alloc] init];
    result.rangeOfError = NSMakeRange(NSNotFound, 0);
    result.operatorAtError = 'M';
    result.errorInLastOperation = YES;
    
    NSCharacterSet* invalidPathCharacters = [self invalidPathCharacters];
    NSRange badCharacters = [anSVGPath rangeOfCharacterFromSet:invalidPathCharacters];
    if(badCharacters.location != NSNotFound)
    {
        result.errorCode = kPathParsingErrorUnknownOperand;
        result.rangeOfError = badCharacters;
        result.unexpectedCharacters = [anSVGPath substringWithRange:badCharacters];
    }
    else
    {
    
        NSString* pathToRender = [anSVGPath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSRange startRange = [anSVGPath rangeOfCharacterFromSet:[[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet]];
        
        if(pathToRender.length)
        {
            NSData* asciiData = [pathToRender dataUsingEncoding:NSASCIIStringEncoding];
            NSUInteger	dataLength = [asciiData length];
            const char*		rawData = (const char*)[asciiData bytes];
            NSUInteger	index = 0;
            char	activeOperator = 'M';
            SVGPathValidationError	errorState = kPathParsingErrorNone;
            
            CGFloat	lastQuadraticControlX = CGFLOAT_MAX;
            CGFloat	lastQuadraticControlY = CGFLOAT_MAX;
            
            CGPoint currentPoint = CGPointZero;
            BOOL failed = NO;
            BOOL startMove = NO;
            NSInteger failureLength = 0;
            while(index < dataLength && errorState == kPathParsingErrorNone && !failed)
            {
                char anOperator = rawData[index];
                if((anOperator >= 'a' && anOperator <= 'z') || (anOperator >= 'A' && anOperator <= 'Z'))
                { // is there a new activeOperator, or should we continue to treat numbers like they had gotten the previous activeOperator
                    activeOperator = rawData[index++]; // new activeOperator
                }
                NSInteger startIndex = index;
                if(!startMove && (activeOperator != 'm' && activeOperator != 'M'))
                {
                    errorState = kPathParsingErrorMissingStart;
                    failureLength = index;
                }
                else
                {
                    switch(activeOperator)
                    {
                        case 'm':
                        case 'M': // absolute moveto
                        {
                            startMove = YES;
                            CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                            CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                            
                            currentPoint = CGPointMake(xCoord, yCoord);
                            
                            lastQuadraticControlX = CGFLOAT_MAX;
                            if(!failed)
                                activeOperator = 'L'; // subsequent implied operations will be absolute line to's
                        }
                        break;
                            
                        case 'Z':
                        case 'z': // close path
                        {
                            lastQuadraticControlX = CGFLOAT_MAX;
                            
                            if(index < (dataLength-1))
                            {
                                char nextOperator = rawData[index];
                                if(nextOperator != 'z' &&
                                   ((nextOperator >= 'a' && nextOperator <= 'z') ||
                                    (nextOperator >= 'A' && nextOperator <= 'Z')))
                                {
                                    
                                }
                                else {
                                    index++;
                                }
                            }
                            else
                            {
                                index++;
                            }
                        }
                        break;
                        case 'l':
                        case 'L': // absolute lineto
                        {
                            CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                            CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                            
                            currentPoint = CGPointMake(xCoord, yCoord);
                            
                            lastQuadraticControlX = CGFLOAT_MAX;
                        }
                        break;
                        case 'h':
                        case 'H':// absolute horizontal lineto
                        {
                            CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                            CGFloat yCoord = currentPoint.y;
                            currentPoint = CGPointMake(xCoord, yCoord);
                            lastQuadraticControlX = CGFLOAT_MAX;
                        }
                        break;
                            
                        case 'v':
                        case 'V': // absolute vertical lineto
                        {
                            CGFloat	xCoord = currentPoint.x;
                            CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                            
                            currentPoint = CGPointMake(xCoord, yCoord);
                            
                            lastQuadraticControlX = CGFLOAT_MAX;
                        }
                        break;
                            
                        case 'c':
                        case 'C': // absolute Cubic Bezier curve
                        {
                            (void)GetNextCoordinate(rawData, &index, dataLength, &failed);
                            (void)GetNextCoordinate(rawData, &index, dataLength, &failed);
                            (void)GetNextCoordinate(rawData, &index, dataLength, &failed);
                            (void)GetNextCoordinate(rawData, &index, dataLength, &failed);
                            CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                            CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                            
                            
                            currentPoint = CGPointMake(xCoord, yCoord);
                            
                            lastQuadraticControlX = CGFLOAT_MAX;
                        }
                        break;
                        case 's':
                        case 'S': // absolute shorthand Cubic Bezier curve
                        {
                            GetNextCoordinate(rawData, &index, dataLength, &failed);
                            GetNextCoordinate(rawData, &index, dataLength, &failed);
                            CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                            CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                            currentPoint = CGPointMake(xCoord, yCoord);
                            
                            lastQuadraticControlX = CGFLOAT_MAX;
                            
                        }
                        break;
                        case 'q':
                        case 'Q': // quadratic Bezier curve
                        {
                            CGFloat	xControl1 = GetNextCoordinate(rawData, &index, dataLength, &failed);
                            CGFloat	yControl1 = GetNextCoordinate(rawData, &index, dataLength, &failed);
                            CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                            CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                            
                            currentPoint = CGPointMake(xCoord, yCoord);
                            
                            lastQuadraticControlX = xControl1;
                            lastQuadraticControlY = yControl1;
                        }
                        break;
                        case 't':
                        case 'T': // absolute shorthand quadratic Bezier curve
                        {
                            CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                            CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                            CGFloat	xControl1 = currentPoint.x;
                            CGFloat yControl1 = currentPoint.y;
                            
                            xControl1 -= (lastQuadraticControlX-xControl1);
                            yControl1 -= (lastQuadraticControlY-yControl1);
                            
                            currentPoint = CGPointMake(xCoord, yCoord);
                            
                            lastQuadraticControlX = xControl1;
                            lastQuadraticControlY = yControl1;
                            
                        }
                        break;
                        case 'a':
                        case 'A': // absolute elliptical Arc segment
                        {
                            (void)GetNextCoordinate(rawData, &index, dataLength, &failed);
                            (void)GetNextCoordinate(rawData, &index, dataLength, &failed);
                            if(!failed)
                            {
                                NSInteger beginning = index;
                                CGFloat xRotation = GetNextCoordinate(rawData, &index, dataLength, &failed);
                                if(xRotation < -360 || xRotation > 360)
                                {
                                    errorState = kPathParsingErrorExpectedDegrees;
                                    failureLength = index-beginning;
                                    index = failureLength;
                                    failed = YES;
                                }
                            }
                            if(!failed)
                            {
                                NSInteger beginning = index;
                                CGFloat	largeArcFlag = GetNextCoordinate(rawData, &index, dataLength, &failed);
                                if(!(largeArcFlag == 0 || largeArcFlag == 1))
                                {
                                    errorState = kPathParsingErrorExpectedBoolean;
                                    failureLength = index-beginning;
                                    index = failureLength;
                                    failed = YES;
                                }
                            }
                            if(!failed)
                            {
                                NSInteger beginning = index;
                                CGFloat	sweepFlag = GetNextCoordinate(rawData, &index, dataLength, &failed);
                                if(!(sweepFlag == 0 || sweepFlag == 1))
                                {
                                    errorState = kPathParsingErrorExpectedBoolean;
                                    failureLength = index-beginning;
                                    index = failureLength;
                                    failed = YES;
                                }
                            }
                            CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                            CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                            
                            currentPoint = CGPointMake(xCoord, yCoord);
                            
                            lastQuadraticControlX = CGFLOAT_MAX;
                        }
                       break;
                            
                        default:
                        {
                            errorState = kPathParsingErrorUnknownOperand; // don't know where I am bail
                        }
                        break;
                    }
                }
                if(errorState == kPathParsingErrorNone && failed)
                {
                    errorState =  kPathParsingErrorMissingNumber;
                }
                if(errorState != kPathParsingErrorNone && failureLength == 0)
                {
                    failureLength = index-startIndex;
                    index = startIndex;
                }
            }
            
            if(errorState != kPathParsingErrorNone)
            {
                result.operatorAtError = activeOperator;
                result.errorCode = errorState;
                result.rangeOfError = NSMakeRange(index+startRange.location, failureLength);
                NSRange lastOperator = [pathToRender rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"mMlLsStTcCqQaAzZhHvV"] options:NSBackwardsSearch range:NSMakeRange(0, pathToRender.length)];
                if(lastOperator.location != NSNotFound && lastOperator.location > index)
                {
                    result.errorInLastOperation = NO;
                }
                else
                {
                    result.errorInLastOperation = YES;
                }
            }
            else
            {
                result.errorInLastOperation = NO;
            }
        }
    }
    return result;
}


+(CGRect)  maxBoundingBoxForSVGPath:(NSString*)anSVGPath
{
    CGRect result = CGRectNull;
    NSString* pathToRender = [anSVGPath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if(pathToRender.length)
    {
		NSData* asciiData = [pathToRender dataUsingEncoding:NSASCIIStringEncoding];
		NSUInteger	dataLength = [asciiData length];
		const char*		rawData = (const char*)[asciiData bytes];
		NSUInteger	index = 0;
		char	activeOperator = 'M';
		BOOL	errorState = NO;
		CGFloat	lastCubicControlX = CGFLOAT_MAX;
		CGFloat	lastCubicControlY = CGFLOAT_MAX;
		
		CGFloat	lastQuadraticControlX = CGFLOAT_MAX;
		CGFloat	lastQuadraticControlY = CGFLOAT_MAX;
        
        CGPoint currentPoint = CGPointZero;
        CGPoint startPoint = currentPoint;
		BOOL failed = NO;
		while(index < dataLength && !errorState)
		{
			char anOperator = rawData[index];
			if((anOperator >= 'a' && anOperator <= 'z') || (anOperator >= 'A' && anOperator <= 'Z'))
			{ // is there a new activeOperator, or should we continue to treat numbers like they had gotten the previous activeOperator
				activeOperator = rawData[index++]; // new activeOperator
			}
			switch(activeOperator)
			{
				case 'M': // absolute moveto
				{
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    
                    result = [self addPoint:CGPointMake(xCoord, yCoord) toRect:result];
                    currentPoint = CGPointMake(xCoord, yCoord);
                    startPoint = currentPoint;
					lastCubicControlX = CGFLOAT_MAX;
					lastQuadraticControlX = CGFLOAT_MAX;
					activeOperator = 'L'; // subsequent implied operations will be absolute line to's
				}
                break;
                    
				case 'm': // relative moveto
				{
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					
                    xCoord += currentPoint.x;
                    yCoord += currentPoint.y;
                    
                    result = [self addPoint:CGPointMake(xCoord, yCoord) toRect:result];
                    currentPoint = CGPointMake(xCoord, yCoord);
					startPoint = currentPoint;
					lastCubicControlX = CGFLOAT_MAX;
					lastQuadraticControlX = CGFLOAT_MAX;
					activeOperator = 'l'; // subsequent implied operations will be relative line tos
				}
                break;
                    
				case 'Z':
				case 'z': // close path
				{
					lastCubicControlX = CGFLOAT_MAX;
					lastQuadraticControlX = CGFLOAT_MAX;
					currentPoint = startPoint;
					if(index < (dataLength-1))
					{
						char nextOperator = rawData[index];
						if(nextOperator != 'z' &&
                           ((nextOperator >= 'a' && nextOperator <= 'z') ||
                            (nextOperator >= 'A' && nextOperator <= 'Z')))
						{
							
						}
						else {
							index++;
						}
					}
					else
					{
						index++;
					}
				}
                break;
                    
				case 'L': // absolute lineto
				{
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    
                    result = [self addPoint:CGPointMake(xCoord, yCoord) toRect:result];
                    currentPoint = CGPointMake(xCoord, yCoord);
                    
					lastCubicControlX = CGFLOAT_MAX;
					lastQuadraticControlX = CGFLOAT_MAX;
                    
				}
                break;
                    
				case 'l': // relative lineto
				{
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    xCoord += currentPoint.x;
                    yCoord += currentPoint.y;
                    result = [self addPoint:CGPointMake(xCoord, yCoord) toRect:result];
                    currentPoint = CGPointMake(xCoord, yCoord);
					lastCubicControlX = CGFLOAT_MAX;
					lastQuadraticControlX = CGFLOAT_MAX;
				}
                break;
                    
				case 'H':// absolute horizontal lineto
				{
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    CGFloat yCoord = currentPoint.y;
                    result = [self addPoint:CGPointMake(xCoord, yCoord) toRect:result];
                    currentPoint = CGPointMake(xCoord, yCoord);
                    
                    
					lastCubicControlX = CGFLOAT_MAX;
					lastQuadraticControlX = CGFLOAT_MAX;
				}
                break;
                    
				case 'h':// relative horizontal lineto
				{
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    CGFloat yCoord = currentPoint.y;
					xCoord += currentPoint.x;
                    result = [self addPoint:CGPointMake(xCoord, yCoord) toRect:result];
                    currentPoint = CGPointMake(xCoord, yCoord);
					lastCubicControlX = CGFLOAT_MAX;
					lastQuadraticControlX = CGFLOAT_MAX;
				}
                break;
                    
				case 'V': // absolute vertical lineto
				{
                    CGFloat	xCoord = currentPoint.x;
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    
                    result = [self addPoint:CGPointMake(xCoord, yCoord) toRect:result];
                    currentPoint = CGPointMake(xCoord, yCoord);
                    
					lastCubicControlX = CGFLOAT_MAX;
					lastQuadraticControlX = CGFLOAT_MAX;
				}
                    break;
                    
				case 'v': // relative vertical lineto
				{
                    CGFloat	xCoord = currentPoint.x;
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					yCoord += currentPoint.y;
                    result = [self addPoint:CGPointMake(xCoord, yCoord) toRect:result];
                    currentPoint = CGPointMake(xCoord, yCoord);
					lastCubicControlX = CGFLOAT_MAX;
					lastQuadraticControlX = CGFLOAT_MAX;
				}
                break;
                    
				case 'C': // absolute Cubic Bezier curve
				{
					CGFloat	xControl1 = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yControl1 = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    result = [self addPoint:CGPointMake(xControl1, yControl1) toRect:result];
					CGFloat	xControl2 = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yControl2 = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    result = [self addPoint:CGPointMake(xControl2, yControl2) toRect:result];
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					
					
                    result = [self addPoint:CGPointMake(xCoord, yCoord) toRect:result];
                    currentPoint = CGPointMake(xCoord, yCoord);
					
					lastCubicControlX = xControl2;
					lastCubicControlY = yControl2;
					lastQuadraticControlX = CGFLOAT_MAX;
				}
                break;
                    
                case 'c': // relative Cubic Bezier curve
				{
					CGFloat	xControl1 = GetNextCoordinate(rawData, &index, dataLength, &failed)+currentPoint.x;
					CGFloat	yControl1 = GetNextCoordinate(rawData, &index, dataLength, &failed)+currentPoint.y;
                    result = [self addPoint:CGPointMake(xControl1, yControl1) toRect:result];
					CGFloat	xControl2 = GetNextCoordinate(rawData, &index, dataLength, &failed)+currentPoint.x;
					CGFloat	yControl2 = GetNextCoordinate(rawData, &index, dataLength, &failed)+currentPoint.y;
                    result = [self addPoint:CGPointMake(xControl2, yControl2) toRect:result];
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed)+currentPoint.x;
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed)+currentPoint.y;
                    result = [self addPoint:CGPointMake(xCoord, yCoord) toRect:result];
                    currentPoint = CGPointMake(xCoord, yCoord);
                
					
					lastCubicControlX = xControl2;
					lastCubicControlY = yControl2;
					lastQuadraticControlX = CGFLOAT_MAX;
				}
                break;
                    
				case 'S': // absolute shorthand Cubic Bezier curve
				{
					CGFloat	xControl2 = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yControl2 = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    result = [self addPoint:CGPointMake(xControl2, yControl2) toRect:result];
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	xControl1 = currentPoint.x;
					CGFloat yControl1 = currentPoint.y;
					
					if(lastCubicControlX != CGFLOAT_MAX)
					{
						xControl1 -= (lastCubicControlX-xControl1);
						yControl1 -= (lastCubicControlY-yControl1);
					}
                    result = [self addPoint:CGPointMake(xControl1, yControl1) toRect:result];
					
                    result = [self addPoint:CGPointMake(xCoord, yCoord) toRect:result];
                    currentPoint = CGPointMake(xCoord, yCoord);
                    
					lastCubicControlX = xControl2;
					lastCubicControlY = yControl2;
					lastQuadraticControlX = CGFLOAT_MAX;
				}
                break;
                    
				case 's': // relative shorthand  Cubic Bezier curve
				{
					CGFloat	xControl2 = GetNextCoordinate(rawData, &index, dataLength, &failed)+currentPoint.x;
					CGFloat	yControl2 = GetNextCoordinate(rawData, &index, dataLength, &failed)+currentPoint.y;
                    result = [self addPoint:CGPointMake(xControl2, yControl2) toRect:result];
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed)+currentPoint.x;
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed)+currentPoint.y;
					CGFloat	xControl1 = currentPoint.x;
					CGFloat yControl1 = currentPoint.y;
					
					if(lastCubicControlX != CGFLOAT_MAX)
					{
						xControl1 -= (lastCubicControlX-xControl1);
						yControl1 -= (lastCubicControlY-yControl1);
					}
                    result = [self addPoint:CGPointMake(xControl1, yControl1) toRect:result];
					
                    result = [self addPoint:CGPointMake(xCoord, yCoord) toRect:result];
                    currentPoint = CGPointMake(xCoord, yCoord);
					lastCubicControlX = xControl2;
					lastCubicControlY = yControl2;
					lastQuadraticControlX = CGFLOAT_MAX;
				}
                break;
				case 'Q': // absolute quadratic Bezier curve
				{
					CGFloat	xControl1 = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yControl1 = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    result = [self addPoint:CGPointMake(xControl1, yControl1) toRect:result];
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					
                    result = [self addPoint:CGPointMake(xCoord, yCoord) toRect:result];
                    currentPoint = CGPointMake(xCoord, yCoord);
					
					lastQuadraticControlX = xControl1;
					lastQuadraticControlY = yControl1;
					lastCubicControlX = CGFLOAT_MAX;
				}
                break;
				case 'q': // relative quadratic Bezier curve
				{
					CGFloat	xControl1 = GetNextCoordinate(rawData, &index, dataLength, &failed)+currentPoint.x;
					CGFloat	yControl1 = GetNextCoordinate(rawData, &index, dataLength, &failed)+currentPoint.y;
                    result = [self addPoint:CGPointMake(xControl1, yControl1) toRect:result];
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed)+currentPoint.x;
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed)+currentPoint.y;
                    result = [self addPoint:CGPointMake(xCoord, yCoord) toRect:result];
                    currentPoint = CGPointMake(xCoord, yCoord);
					
					
					lastQuadraticControlX = xControl1;
					lastQuadraticControlY = yControl1;
					lastCubicControlX = CGFLOAT_MAX;
				}
                break;
				case 'T': // absolute shorthand quadratic Bezier curve
				{
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	xControl1 = currentPoint.x;
					CGFloat yControl1 = currentPoint.y;
					
					if(lastQuadraticControlX != CGFLOAT_MAX)
					{
						xControl1 -= (lastQuadraticControlX-xControl1);
						yControl1 -= (lastQuadraticControlY-yControl1);
					}
                    result = [self addPoint:CGPointMake(xControl1, yControl1) toRect:result];
					
					
                    result = [self addPoint:CGPointMake(xCoord, yCoord) toRect:result];
                    currentPoint = CGPointMake(xCoord, yCoord);
					
					lastQuadraticControlX = xControl1;
					lastQuadraticControlY = yControl1;
					lastCubicControlX = CGFLOAT_MAX;
				}
                break;
				case 't': // relative shorthand  quadratic Bezier curve
				{
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed)+currentPoint.x;
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed)+currentPoint.y;
					
					CGFloat	xControl1 = currentPoint.x;
					CGFloat yControl1 = currentPoint.y;
					
					if(lastQuadraticControlX != CGFLOAT_MAX)
					{
						xControl1 -= (lastQuadraticControlX-xControl1);
						yControl1 -= (lastQuadraticControlY-yControl1);
					}
                    result = [self addPoint:CGPointMake(xControl1, yControl1) toRect:result];
					
                    result = [self addPoint:CGPointMake(xCoord, yCoord) toRect:result];
                    currentPoint = CGPointMake(xCoord, yCoord);
					
					
					lastQuadraticControlX = xControl1;
					lastQuadraticControlY = yControl1;
					lastCubicControlX = CGFLOAT_MAX;
				}
                break;
					
				case 'A': // absolute elliptical Arc segment
				{
					CGFloat	xRadius = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yRadius = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	xAxisRotationDegrees = GetNextCoordinate(rawData, &index, dataLength, &failed);
					BOOL	largeArcFlag = (GetNextCoordinate(rawData, &index, dataLength, &failed) == 0.0)?NO:YES;
					BOOL	sweepFlag = (GetNextCoordinate(rawData, &index, dataLength, &failed) == 0.0)?NO:YES;
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					
                    
					CGMutablePathRef	tempPath = CGPathCreateMutable();
                    CGPathMoveToPoint(tempPath, nil, currentPoint.x, currentPoint.y);
                    
					AddSVGArcToPath(tempPath, xRadius, yRadius, xAxisRotationDegrees,
									largeArcFlag, sweepFlag, xCoord, yCoord);
                    CGRect arcRect = CGPathGetBoundingBox(tempPath);
                    
					
                    result = [self addPoint:CGPointMake(xCoord, yCoord) toRect:result];
                    currentPoint = CGPointMake(xCoord, yCoord);
                    result = CGRectUnion(result, arcRect);
                    CGPathRelease(tempPath);
                    
					lastCubicControlX = CGFLOAT_MAX;
					lastQuadraticControlX = CGFLOAT_MAX;
				}
                break;
                    
				case 'a': // relative elliptical arc Seqment
				{
					CGFloat	xRadius = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yRadius = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	xAxisRotationDegrees = GetNextCoordinate(rawData, &index, dataLength, &failed);
					BOOL	largeArcFlag = (GetNextCoordinate(rawData, &index, dataLength, &failed) == 0.0)?NO:YES;
					BOOL	sweepFlag = (GetNextCoordinate(rawData, &index, dataLength, &failed) == 0.0)?NO:YES;
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed)+currentPoint.x;
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed)+currentPoint.y;
					
					CGMutablePathRef	tempPath = CGPathCreateMutable();
                    CGPathMoveToPoint(tempPath, nil, currentPoint.x, currentPoint.y);
                    
					AddSVGArcToPath(tempPath, xRadius, yRadius, xAxisRotationDegrees,
									largeArcFlag, sweepFlag, xCoord, yCoord);
                    CGRect arcRect = CGPathGetBoundingBox(tempPath);
                    result = [self addPoint:CGPointMake(xCoord, yCoord) toRect:result];
                    currentPoint = CGPointMake(xCoord, yCoord);
                    result = CGRectUnion(result, arcRect);
                    CGPathRelease(tempPath);
					
					lastCubicControlX = CGFLOAT_MAX;
					lastQuadraticControlX = CGFLOAT_MAX;
				}
                break;
                    
				default:
				{
					errorState = YES; // don't know where I am bail
					NSLog(@"Unknown path operand: %c", activeOperator);
				}
                break;
			}
		}
	}
    
    return result;
}

+(CGPathRef) newCGPathFromSVGPath:(NSString*)anSVGPath whileApplyingTransform:(CGAffineTransform)aTransform
{
    NSString* pathToRender = [anSVGPath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	CGMutablePathRef	mutableResult = CGPathCreateMutable();
	if([pathToRender length])
	{
        CGPathMoveToPoint(mutableResult, NULL, 0.0, 0.0);
		NSData* asciiData = [pathToRender dataUsingEncoding:NSASCIIStringEncoding];
		NSUInteger	dataLength = [asciiData length];
		const char*		rawData = (const char*)[asciiData bytes];
		NSUInteger	index = 0;
		char	activeOperator = 'M';
		BOOL	errorState = NO;
		CGFloat	lastCubicControlX = CGFLOAT_MAX;
		CGFloat	lastCubicControlY = CGFLOAT_MAX;
		
		CGFloat	lastQuadraticControlX = CGFLOAT_MAX;
		CGFloat	lastQuadraticControlY = CGFLOAT_MAX;
        BOOL failed = NO;
		
		while(index < dataLength && !errorState && !failed)
		{
			char anOperator = rawData[index];
			if((anOperator >= 'a' && anOperator <= 'z') || (anOperator >= 'A' && anOperator <= 'Z'))
			{ // is there a new activeOperator, or should we continue to treat numbers like they had gotten the previous activeOperator
				activeOperator = rawData[index++]; // new activeOperator
			}
			switch(activeOperator)
			{
				case 'M': // absolute moveto
				{
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
                    if(!failed) CGPathMoveToPoint(mutableResult,NULL, xCoord, yCoord);
					lastCubicControlX = CGFLOAT_MAX;
					lastQuadraticControlX = CGFLOAT_MAX;
					activeOperator = 'L'; // subsequent implied operations will be absolute line to's
				}
                break;
                    
				case 'm': // relative moveto
				{
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					
					if(!CGPathIsEmpty(mutableResult))
					{
						CGPoint curPoint = CGPathGetCurrentPoint(mutableResult);
						xCoord += curPoint.x;
						yCoord += curPoint.y;
					}
					if(!failed) CGPathMoveToPoint(mutableResult,NULL, xCoord, yCoord);
					
					lastCubicControlX = CGFLOAT_MAX;
					lastQuadraticControlX = CGFLOAT_MAX;
					activeOperator = 'l'; // subsequent implied operations will be relative line tos
				}
                break;
                    
				case 'Z':
				case 'z': // close path
				{
                    CGPoint lastPoint = CGPathGetCurrentPoint(mutableResult); // Workaround for bug in iOS 12 beta 3
					CGPathCloseSubpath(mutableResult);
                    CGPathMoveToPoint(mutableResult, NULL, lastPoint.x, lastPoint.y); // Workaround for bug in iOS 12 beta 3
					lastCubicControlX = CGFLOAT_MAX;
					lastQuadraticControlX = CGFLOAT_MAX;
					
					if(index < (dataLength-1))
					{
						char nextOperator = rawData[index];
						if(nextOperator != 'z' &&
                           ((nextOperator >= 'a' && nextOperator <= 'z') ||
                            (nextOperator >= 'A' && nextOperator <= 'Z')))
						{
							
						}
						else {
							index++;
						}
					}
					else
					{
						index++;
					}
				}
                break;
                    
				case 'L': // absolute lineto
				{
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					if(!failed) CGPathAddLineToPoint(mutableResult,NULL, xCoord, yCoord);
					lastCubicControlX = CGFLOAT_MAX;
					lastQuadraticControlX = CGFLOAT_MAX;
                    
				}
                break;
                    
				case 'l': // relative lineto
				{
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					if(!CGPathIsEmpty(mutableResult))
					{
						CGPoint curPoint = CGPathGetCurrentPoint(mutableResult);
						xCoord += curPoint.x;
						yCoord += curPoint.y;
					}
					if(!failed) CGPathAddLineToPoint(mutableResult,NULL, xCoord, yCoord);
					lastCubicControlX = CGFLOAT_MAX;
					lastQuadraticControlX = CGFLOAT_MAX;
				}
                break;
                    
				case 'H':// absolute horizontal lineto
				{
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGPoint curPoint = CGPathGetCurrentPoint(mutableResult);
					if(!failed) CGPathAddLineToPoint(mutableResult,NULL, xCoord, curPoint.y);
					lastCubicControlX = CGFLOAT_MAX;
					lastQuadraticControlX = CGFLOAT_MAX;
				}
                break;
                    
				case 'h':// relative horizontal lineto
				{
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGPoint curPoint = CGPathGetCurrentPoint(mutableResult);
					xCoord += curPoint.x;
					if(!failed) CGPathAddLineToPoint(mutableResult,NULL, xCoord, curPoint.y);
					lastCubicControlX = CGFLOAT_MAX;
					lastQuadraticControlX = CGFLOAT_MAX;
				}
                break;
                    
				case 'V': // absolute vertical lineto
				{
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGPoint curPoint = CGPathGetCurrentPoint(mutableResult);
					if(!failed) CGPathAddLineToPoint(mutableResult,NULL, curPoint.x, yCoord);
					lastCubicControlX = CGFLOAT_MAX;
					lastQuadraticControlX = CGFLOAT_MAX;
				}
                break;
                    
				case 'v': // relative vertical lineto
				{
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGPoint curPoint = CGPathGetCurrentPoint(mutableResult);
					yCoord += curPoint.y;
					if(!failed) CGPathAddLineToPoint(mutableResult,NULL, curPoint.x, yCoord);
					lastCubicControlX = CGFLOAT_MAX;
					lastQuadraticControlX = CGFLOAT_MAX;
				}
                break;
                    
				case 'C': // absolute Cubic Bezier curve
				{
					CGFloat	xControl1 = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yControl1 = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	xControl2 = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yControl2 = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					
					
					if(!failed) CGPathAddCurveToPoint(mutableResult,NULL, xControl1, yControl1,
										  xControl2, yControl2, xCoord, yCoord);
					
					lastCubicControlX = xControl2;
					lastCubicControlY = yControl2;
					lastQuadraticControlX = CGFLOAT_MAX;
				}
                break;
				
                case 'c': // relative Cubic Bezier curve
				{
					CGPoint curPoint = CGPathGetCurrentPoint(mutableResult);
					CGFloat	xControl1 = GetNextCoordinate(rawData, &index, dataLength, &failed)+curPoint.x;
					CGFloat	yControl1 = GetNextCoordinate(rawData, &index, dataLength, &failed)+curPoint.y;
					CGFloat	xControl2 = GetNextCoordinate(rawData, &index, dataLength, &failed)+curPoint.x;
					CGFloat	yControl2 = GetNextCoordinate(rawData, &index, dataLength, &failed)+curPoint.y;
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed)+curPoint.x;
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed)+curPoint.y;
					
					
					if(!failed) CGPathAddCurveToPoint(mutableResult,NULL, xControl1, yControl1,
										  xControl2, yControl2, xCoord, yCoord);
					
					lastCubicControlX = xControl2;
					lastCubicControlY = yControl2;
					lastQuadraticControlX = CGFLOAT_MAX;
				}
                break;
                    
				case 'S': // absolute shorthand Cubic Bezier curve
				{
					CGPoint curPoint = CGPathGetCurrentPoint(mutableResult);
					CGFloat	xControl2 = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yControl2 = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	xControl1 = curPoint.x;
					CGFloat yControl1 = curPoint.y;
					
					if(lastCubicControlX != CGFLOAT_MAX)
					{
						xControl1 -= (lastCubicControlX-xControl1);
						yControl1 -= (lastCubicControlY-yControl1);
					}
					
					
					if(!failed) CGPathAddCurveToPoint(mutableResult,NULL, xControl1, yControl1,
										  xControl2, yControl2, xCoord, yCoord);
					lastCubicControlX = xControl2;
					lastCubicControlY = yControl2;
					lastQuadraticControlX = CGFLOAT_MAX;
				}
                break;
                    
				case 's': // relative shorthand  Cubic Bezier curve
				{
					CGPoint curPoint = CGPathGetCurrentPoint(mutableResult);
					CGFloat	xControl2 = GetNextCoordinate(rawData, &index, dataLength, &failed)+curPoint.x;
					CGFloat	yControl2 = GetNextCoordinate(rawData, &index, dataLength, &failed)+curPoint.y;
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed)+curPoint.x;
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed)+curPoint.y;
					CGFloat	xControl1 = curPoint.x;
					CGFloat yControl1 = curPoint.y;
					
					if(lastCubicControlX != CGFLOAT_MAX)
					{
						xControl1 -= (lastCubicControlX-xControl1);
						yControl1 -= (lastCubicControlY-yControl1);
					}
					
					
					if(!failed) CGPathAddCurveToPoint(mutableResult,NULL, xControl1, yControl1,
										  xControl2, yControl2, xCoord, yCoord);
					lastCubicControlX = xControl2;
					lastCubicControlY = yControl2;
					lastQuadraticControlX = CGFLOAT_MAX;
				}
                break;
				case 'Q': // absolute quadratic Bezier curve
				{
					CGFloat	xControl1 = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yControl1 = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					
					if(!failed) CGPathAddQuadCurveToPoint(mutableResult,NULL, xControl1, yControl1,
                                              xCoord, yCoord);
					
					lastQuadraticControlX = xControl1;
					lastQuadraticControlY = yControl1;
					lastCubicControlX = CGFLOAT_MAX;
				}
                break;
				case 'q': // relative quadratic Bezier curve
				{
					CGPoint curPoint = CGPathGetCurrentPoint(mutableResult);
					CGFloat	xControl1 = GetNextCoordinate(rawData, &index, dataLength, &failed)+curPoint.x;
					CGFloat	yControl1 = GetNextCoordinate(rawData, &index, dataLength, &failed)+curPoint.y;
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed)+curPoint.x;
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed)+curPoint.y;
					
					
					if(!failed) CGPathAddQuadCurveToPoint(mutableResult,NULL, xControl1, yControl1,
											  xCoord, yCoord);
					
					lastQuadraticControlX = xControl1;
					lastQuadraticControlY = yControl1;
					lastCubicControlX = CGFLOAT_MAX;
				}
                break;
				case 'T': // absolute shorthand quadratic Bezier curve
				{
					CGPoint curPoint = CGPathGetCurrentPoint(mutableResult);
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	xControl1 = curPoint.x;
					CGFloat yControl1 = curPoint.y;
					
					if(lastQuadraticControlX != CGFLOAT_MAX)
					{
						xControl1 -= (lastQuadraticControlX-xControl1);
						yControl1 -= (lastQuadraticControlY-yControl1);
					}
					
					
					if(!failed) CGPathAddQuadCurveToPoint(mutableResult,NULL, xControl1, yControl1,
											  xCoord, yCoord);
					
					
					lastQuadraticControlX = xControl1;
					lastQuadraticControlY = yControl1;
					lastCubicControlX = CGFLOAT_MAX;
				}
                break;
				case 't': // relative shorthand  quadratic Bezier curve
				{
					CGPoint curPoint = CGPathGetCurrentPoint(mutableResult);
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed)+curPoint.x;
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed)+curPoint.y;
					
					CGFloat	xControl1 = curPoint.x;
					CGFloat yControl1 = curPoint.y;
					
					if(lastQuadraticControlX != CGFLOAT_MAX)
					{
						xControl1 -= (lastQuadraticControlX-xControl1);
						yControl1 -= (lastQuadraticControlY-yControl1);
					}
					if(!failed) CGPathAddQuadCurveToPoint(mutableResult,NULL, xControl1, yControl1,
											  xCoord, yCoord);
					
					
					
					lastQuadraticControlX = xControl1;
					lastQuadraticControlY = yControl1;
					lastCubicControlX = CGFLOAT_MAX;
				}
                break;
					
				case 'A': // absolute elliptical Arc segment
				{
					CGFloat	xRadius = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yRadius = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	xAxisRotationDegrees = GetNextCoordinate(rawData, &index, dataLength, &failed);
					BOOL	largeArcFlag = (GetNextCoordinate(rawData, &index, dataLength, &failed) == 0.0)?NO:YES;
					BOOL	sweepFlag = (GetNextCoordinate(rawData, &index, dataLength, &failed) == 0.0)?NO:YES;
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed);
					
					if(!failed) AddSVGArcToPath(mutableResult, xRadius, yRadius, xAxisRotationDegrees,
									largeArcFlag, sweepFlag, xCoord, yCoord);
					
                    
					lastCubicControlX = CGFLOAT_MAX;
					lastQuadraticControlX = CGFLOAT_MAX;
				}
                break;
                    
				case 'a': // relative elliptical arc Seqment
				{
					CGPoint curPoint = CGPathGetCurrentPoint(mutableResult);
					CGFloat	xRadius = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	yRadius = GetNextCoordinate(rawData, &index, dataLength, &failed);
					CGFloat	xAxisRotationDegrees = GetNextCoordinate(rawData, &index, dataLength, &failed);
					BOOL	largeArcFlag = (GetNextCoordinate(rawData, &index, dataLength, &failed) == 0.0)?NO:YES;
					BOOL	sweepFlag = (GetNextCoordinate(rawData, &index, dataLength, &failed) == 0.0)?NO:YES;
					CGFloat	xCoord = GetNextCoordinate(rawData, &index, dataLength, &failed)+curPoint.x;
					CGFloat	yCoord = GetNextCoordinate(rawData, &index, dataLength, &failed)+curPoint.y;
					
					if(!failed) AddSVGArcToPath(mutableResult, xRadius, yRadius, xAxisRotationDegrees,
									largeArcFlag, sweepFlag, xCoord, yCoord);
					
					lastCubicControlX = CGFLOAT_MAX;
					lastQuadraticControlX = CGFLOAT_MAX;
				}
                break;
                    
				default:
				{
					errorState = YES; // don't know where I am bail
					NSLog(@"Unknown path operand: %c", activeOperator);
				}
                break;
			}
		}
        
		if(index < dataLength)
		{
			char nextChar = rawData[index];
			while((nextChar == ' ' || nextChar == '\n' || nextChar == '\r') && index < dataLength)
			{
				nextChar = rawData[++index];
			}
			if((nextChar >= 'a' && nextChar <= 'z')
			   ||(nextChar >= 'A' && nextChar <= 'Z'))
			{
				activeOperator = nextChar;
				index++;
				if(index >= dataLength &&
				   (activeOperator == 'z' || activeOperator == 'Z')) // handle terminating close path
				{
					CGPathCloseSubpath(mutableResult);
				}
			}
		}
	}
    CGPathRef result = 0;
    if(!CGAffineTransformIsIdentity(aTransform))
    {
        result = CGPathCreateCopyByTransformingPath(mutableResult, &aTransform);
    }
    else
    {
        result = CGPathCreateCopy(mutableResult);
    }
   
    
	CGPathRelease(mutableResult);
	return result;
}


+(NSString*) svgPathFromCGPath:(CGPathRef)aPath
{
    __block NSMutableString* mutableResult = [[NSMutableString alloc] initWithCapacity:512];
    
    __block  CGPoint currentPoint = CGPointZero;
    __block CGPathElementType lastOperation = kCGPathElementCloseSubpath;
    __block pathVisitor_t   callback =  ^(const CGPathElement* aPathElement)
    {
        switch (aPathElement->type)
        {
            case kCGPathElementMoveToPoint:
            {
                CGPoint newPoint = aPathElement->points[0];
                currentPoint = newPoint;
                [mutableResult appendFormat:@"M%.1lf %.1lf", currentPoint.x, currentPoint.y];
            }
            break;
            case kCGPathElementAddLineToPoint:
            {
                CGPoint newPoint = aPathElement->points[0];
                if(newPoint.x == currentPoint.x)
                {
                    [mutableResult appendFormat:@"V%.1lf", newPoint.y];
                }
                else if(newPoint.y == currentPoint.y)
                {
                    
                    [mutableResult appendFormat:@"H%.1lf", newPoint.x];
                }
                else
                {
                    [mutableResult appendFormat:@"L%.1lf %.1lf", newPoint.x, newPoint.y];
                }
                currentPoint = newPoint;
            }
            break;
            case kCGPathElementAddQuadCurveToPoint:
            {
                CGPoint controlPoint = aPathElement->points[0];
                CGPoint newPoint = aPathElement->points[1];
                
                [mutableResult appendFormat:@"Q%.1lf %.1lf %.1lf %.1lf", controlPoint.x, controlPoint.y, newPoint.x, newPoint.y];
                
                currentPoint = newPoint;
            }
            break;
            case kCGPathElementAddCurveToPoint:
            {
                CGPoint controlPoint1 = aPathElement->points[0];
                CGPoint controlPoint2 = aPathElement->points[1];
                CGPoint newPoint = aPathElement->points[2];
                
                
                [mutableResult appendFormat:@"C%.1lf %.1lf %.1lf %.1lf %.1lf %.1lf", controlPoint1.x, controlPoint1.y, controlPoint2.x, controlPoint2.y, newPoint.x, newPoint.y];
                
                currentPoint = newPoint;
            }
            break;
            case kCGPathElementCloseSubpath:
            {
                [mutableResult appendString:@"Z"];
            }
            break;
            default:
            {
            }
            break;
        }
        lastOperation = aPathElement->type;
    };
    
    CGPathApply(aPath, (__bridge void *)callback, CGPathApplyCallbackFunction);
    return [mutableResult copy];
}
@end

CGPathRef CreatePathFromSVGPathString(NSString* dAttribute, CGAffineTransform transformToApply) CF_RETURNS_RETAINED
{
    CGPathRef result = [SVGPathGenerator newCGPathFromSVGPath:dAttribute whileApplyingTransform:transformToApply];
    return result;
}
