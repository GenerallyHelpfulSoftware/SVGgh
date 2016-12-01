//
//  GzipInputStream.m
//
//  Copyright 2012 Eric U Kong Wong
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not
//  use this file except in compliance with the License.  You may obtain a copy
//  of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
//  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
//  License for the specific language governing permissions and limitations under
//  the License.
//

#import "GzipInputStream.h"
#include <zlib.h>

@interface GzipInputStream()
{
    gzFile gzfile;
    NSString *filepath;
    NSMutableData *residualData;
    NSStreamStatus streamStatus;
}
- (NSString *)firstLineFromData:(NSMutableData *)data;
@end

@implementation GzipInputStream

- (id)initWithData:(NSData *)data
{
    return nil;
}

- (id)initWithFileAtPath:(NSString *)path
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return nil;
    }
    if (self = [super init]) {
        residualData = nil;
        filepath = path;
        streamStatus = NSStreamStatusNotOpen;
    }
    return self;
}

// we promise -initWithFileAtPath: will call a designated initializer!

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (id)initWithURL:(NSURL *)url
{
    if ([url isFileURL])
        return [self initWithFileAtPath:[url path]];
    else {
        return nil;
    }
}
#pragma clang diagnostic pop

- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {}
- (void)removeFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {}


- (void)dealloc
{
    [self close];}

- (void)open
{
    if (filepath) {
        gzfile = gzopen([filepath UTF8String], "rb");
        residualData = [[NSMutableData alloc] initWithCapacity:1024];
        streamStatus = NSStreamStatusOpen;
    }
}

- (void)close
{
    if (gzfile) {
        gzclose(gzfile);
        gzfile = NULL;
    }
    if (residualData) {
        residualData = nil;
    }
    streamStatus = NSStreamStatusClosed;
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len
{
    streamStatus = NSStreamStatusReading;
    int bytesRead = gzread(gzfile, buffer, (unsigned)len);
    if (bytesRead < 0) {
        streamStatus = NSStreamStatusError;
    }
    else if (bytesRead == 0) {
        streamStatus = NSStreamStatusAtEnd;
    }
    else {
        streamStatus = NSStreamStatusOpen;
    }
    return bytesRead;
}

- (NSString *)readLine
{
    uint8_t buffer[1024];
    NSString * line = [self firstLineFromData:residualData];
    while (!line) {
        NSInteger bytesRead = [self read:buffer maxLength:sizeof(buffer)];
        if (bytesRead > 0) {
            [residualData appendBytes:buffer length:bytesRead];
            line = [self firstLineFromData:residualData];
        }
        else if (residualData.length == 0) {
            streamStatus = NSStreamStatusAtEnd;
            return nil;
        }
        else {
            line = [[NSString alloc] initWithBytes:residualData.bytes
                                             length:residualData.length
                                           encoding:NSUTF8StringEncoding];
            line = [line stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            [residualData setLength:0];
        }
    }
    return line;
}

- (NSData *)readData:(NSUInteger)bufferSize;
{
    uint8_t buffer[bufferSize];
    NSInteger bytesRead = [self read:buffer maxLength:bufferSize];
    if (bytesRead > 0) {
        NSData *decompressedData = [NSData dataWithBytes:buffer length:bytesRead];
        return decompressedData;
    }
    else if (residualData.length == 0) {
        streamStatus = NSStreamStatusAtEnd;
        return nil;
    }
    else {
        streamStatus = NSStreamStatusError;
        return nil;
    }
}

- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len
{
    if (residualData.length > 0) {
        *buffer = (uint8_t *)residualData.bytes;
        *len = residualData.length;
        return YES;
    }
    else
        return NO;
}

- (BOOL)hasBytesAvailable
{
    if (gzeof(gzfile) || residualData.length > 0) {
        return NO;
    }
    return YES;
}

- (NSStreamStatus)streamStatus
{
    return streamStatus;
}

- (NSError *)streamError
{
    int err;
    (void) gzerror(gzfile, &err);
    return [NSError errorWithDomain:NSCocoaErrorDomain code:err userInfo:nil];
}

#pragma mark helper private method
- (NSString *)firstLineFromData:(NSMutableData *)data
{
    NSString * line = nil;
    
    uint8_t *buf = (uint8_t *)data.bytes;
    uint8_t *pos = memchr(buf, '\n', data.length);
    if (pos) {
        size_t len = pos - buf;
        line = [[NSString alloc] initWithBytes:buf length:len encoding:NSUTF8StringEncoding];
        line = [line stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        [data replaceBytesInRange:NSMakeRange(0,len+1) withBytes:NULL length:0];
    }
    return line;
}

@end
