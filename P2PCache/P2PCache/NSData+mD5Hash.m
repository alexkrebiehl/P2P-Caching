//
//  NSData+mD5Hash.m
//  P2PCache
//
//  Created by Alex Krebiehl on 2/14/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "NSData+mD5Hash.h"

@implementation NSData (mD5Hash)

- (NSString *)md5Hash
{
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(self.bytes, (CC_LONG)self.length, md5Buffer);
    
    // Convert unsigned char buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
    {
        [output appendFormat:@"%02x",md5Buffer[i]];
    }
    
    return output;
}

@end
