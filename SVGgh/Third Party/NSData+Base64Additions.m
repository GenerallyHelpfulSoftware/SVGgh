//
//  NSData+Base64Additions.m
//  RockPaperScissors
//
//  Created by Ian Baird on 10/28/08.
//
//  Copyright (c) 2008 Skorpiostech, Inc. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import "NSData+Base64Additions.h"
#import "Base64Transcoder.h"

NSData* DecodeBase64FromStringToData(NSString* decodeString)
{
    NSData *decodeBuffer = nil;
    // Must be 7-bit clean!
    NSData *tmpData = [decodeString dataUsingEncoding:NSASCIIStringEncoding];
    
    size_t estSize = EstimateBas64DecodedDataSize([tmpData length]);
    uint8_t* outBuffer = calloc(estSize, sizeof(uint8_t));
    if(outBuffer != nil)
    {
        size_t outBufferLength = estSize;
        if (Base64DecodeData([tmpData bytes], [tmpData length], outBuffer, &outBufferLength))
        {
            decodeBuffer = [NSData dataWithBytesNoCopy:outBuffer length:outBufferLength freeWhenDone:YES];
        }
        else
        {
            free(outBuffer);
        }
    }
    return decodeBuffer;
}

@implementation NSData (Base64Addons)

+(instancetype)decodeBase64ForString:(NSString *)decodeString
{
    NSData* result = DecodeBase64FromStringToData(decodeString);
    return result;
}

+(instancetype)decodeWebSafeBase64ForString:(NSString *)decodeString
{
    return [NSData decodeBase64ForString:[[decodeString stringByReplacingOccurrencesOfString:@"-" withString:@"+"] stringByReplacingOccurrencesOfString:@"_" withString:@"/"]];
}

-(NSString *)encodeBase64ForData
{
    NSString *encodedString = nil;
    
    // Make sure this is nul-terminated.
    size_t outBufferEstLength = EstimateBas64EncodedDataSize([self length]) + 1;
    char *outBuffer = calloc(outBufferEstLength, sizeof(char));
    if(outBuffer != nil)
    {
        size_t outBufferLength = outBufferEstLength;
        if (Base64EncodeData([self bytes], [self length], outBuffer, &outBufferLength, FALSE))
        {
            encodedString = [NSString stringWithCString:outBuffer encoding:NSASCIIStringEncoding];
        }
        
        free(outBuffer);
    }
    return encodedString;
}
                                    
-(NSString *)encodeWebSafeBase64ForData
{
    return [[[self encodeBase64ForData] stringByReplacingOccurrencesOfString:@"+" withString:@"-"] stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
}
                                    
-(NSString *)encodeWrappedBase64ForData
{
    NSString *encodedString = nil;
    
    // Make sure this is nul-terminated.
    size_t outBufferEstLength = EstimateBas64EncodedDataSize([self length]) + 1;
    char *outBuffer = calloc(outBufferEstLength, sizeof(char));
    if(outBuffer != nil)
    {
        size_t outBufferLength = outBufferEstLength;
        if (Base64EncodeData([self bytes], [self length], outBuffer, &outBufferLength, TRUE))
        {
            encodedString = [NSString stringWithCString:outBuffer encoding:NSASCIIStringEncoding];
        }
        
        free(outBuffer);
    }
    return encodedString;
}
                                    
@end
