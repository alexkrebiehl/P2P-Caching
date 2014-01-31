//
//  main.m
//  P2P Node
//
//  Created by Alex Krebiehl on 1/30/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <P2PCache/P2PCache.h>

int main(int argc, const char * argv[])
{

    @autoreleasepool
    {
        [P2PCache start];
        
//        NSData *test = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://www.google.com/"]];
//        NSLog(@"data: %@", test);
        
        // insert code here...
        NSLog(@"Hello, World!");
        
        
    }
    return 0;
}

