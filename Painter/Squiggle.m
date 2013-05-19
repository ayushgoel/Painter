//
//  Squiggle.m
//  Painter
//
//  Created by Edward Chiang on 2010/11/20.
//  Copyright 2010 Edward. All rights reserved.
//

#import "Squiggle.h"


@implementation Squiggle

// generate set and get methods
@synthesize strokeColor = _strokeColor;
@synthesize lineWidth = _lineWidth;
@synthesize points = _points;

// initialize the Squiggle object
- (id)init {
  if (self = [super init]){
    self.points = [[[NSMutableArray alloc] init] autorelease];
    self.strokeColor = [UIColor blackColor];
  }
  return self;
}

// release Squiggle's memory
- (void) dealloc {
  self.strokeColor = nil;
  self.points = nil;
  [super dealloc];
}

#pragma mark - Public

- (void)addPoint:(CGPoint)point {
  // encode the point in an NSValue so we can put it in an NSArray
  NSValue *value = [NSValue valueWithBytes:&point objCType:@encode(CGPoint)];
  [self.points addObject:value];
}

@end
