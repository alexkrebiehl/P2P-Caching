//
//  NSMutableArray+QueueExtension.h
//  Boxed In
//
//  Created by Alex Krebiehl on 5/24/13.
//
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (QueueExtension)

- (void)enqueue:(id)object;
- (id)dequeue;
- (id)peek;
- (bool)isEmpty;

@end
