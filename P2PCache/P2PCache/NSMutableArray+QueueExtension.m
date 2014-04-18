//
//  NSMutableArray+QueueExtension.m
//  Boxed In
//
//  Created by Alex Krebiehl on 5/24/13.
//
//

#import "NSMutableArray+QueueExtension.h"

@implementation NSMutableArray (QueueExtension)

- (void)enqueue:(id)object
{
	[self addObject:object];
}

- (id)dequeue
{
	id object = [self peek];
	[self removeObjectAtIndex:0];
	return object;
}

- (id)peek
{
	return [self objectAtIndex:0];
}

- (bool)isEmpty
{
	return [self count] == 0;
}

@end
