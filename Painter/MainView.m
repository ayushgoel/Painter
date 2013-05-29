//
//  MainView.m
//  Painter
//
//  Created by Edward Chiang on 2010/12/10.
//  Copyright 2010 Edward in Action. All rights reserved.
//

#import "MainView.h"

@interface MainView ()
@property (nonatomic, retain) NSMutableDictionary *squiggles;	// sguiggles in progress
@property (nonatomic, retain) NSMutableArray *finishedSquiggles;	// finished squiggles

@end

@implementation MainView
@synthesize color = color_;
@synthesize lineWidth = lineWidth_;
@synthesize squiggles = squiggles_;
@synthesize finishedSquiggles = finishedSquiggles_;

- (void)commonInitializer {
  // initialize squiggles and finishedSquiggles
  self.squiggles = [[[NSMutableDictionary alloc] init] autorelease];
  self.finishedSquiggles = [[[NSMutableArray alloc] init] autorelease];
  // the starting color is black
  self.color = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
  self.lineWidth = 5;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
  if (self = [super initWithCoder:aDecoder]) {
    [self commonInitializer];
  }
  return self;
}

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self commonInitializer];
  }
  return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
  // Drawing code.
  CGContextRef context = UIGraphicsGetCurrentContext();

  for (Squiggle *squiggle in self.finishedSquiggles)
    [self drawSquiggle:squiggle inContext:context];

  [self.squiggles enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    [self drawSquiggle:obj inContext:context];
  }];
}


// draws the given squiggle into the given context
- (void)drawSquiggle:(Squiggle *)squiggle inContext:(CGContextRef)context {
  // set the drawing color to the squiggle's color
  UIColor *squiggleColor = squiggle.strokeColor;
  CGColorRef	colorRef = [squiggleColor CGColor];	// get the CGColor
  CGContextSetStrokeColorWithColor(context, colorRef);

  // set the line width to the squiggle's line width
  CGContextSetLineWidth(context, squiggle.lineWidth);

  NSMutableArray *points = [squiggle points];	// get points from squiggle

  // draw squiggle only if it has more than one point.
  // Solves crashes.
  if ([points count] != 0) {
    // retrieve the NSValue object and store the value in firstPoint
    CGPoint firstPoint;	// declare a CGPoint
    [[points objectAtIndex:0] getValue:&firstPoint];

    if ([points count] == 1) {
      CGPoint dummyPoint = CGPointMake(firstPoint.x + self.lineWidth,
                                       firstPoint.y + self.lineWidth);
      NSValue *value = [NSValue valueWithBytes:&dummyPoint objCType:@encode(CGPoint)];
      [points addObject:value];
    }

    // move to the point
    CGContextMoveToPoint(context, firstPoint.x, firstPoint.y);

    // draw a line from each point to the next in order
    for (NSValue *value in points) {
      CGPoint point;	// declare a new point
      [value getValue:&point];	// store the value in point

      // draw a line to the new point
      CGContextAddLineToPoint(context, point.x, point.y);
    }
  }
  CGContextStrokePath(context);
}


// called when the user lefts a finger from the screen
- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  // loop through the touches
  for (UITouch *touch in touches) {
    // get the unique key for the touch
    NSValue *touchValue = [NSValue valueWithPointer:touch];
    NSString *key = [NSString stringWithFormat:@"%@", touchValue];
    // retrieve the squiggle for this touch using the key
    Squiggle *squiggle = [self.squiggles valueForKey:key];

    // remove the squiggle from the dictionary and place it in an array
    // of finished squiggles [finishedSquiggles addObject:squiggle];
    // add to finishedSquiggles [squiggles removeObjectForKey:key];
    // remove from squiggles
    [self.finishedSquiggles addObject:squiggle]; // add to finishedSquiggles
    [self.squiggles removeObjectForKey:key]; // remove from squiggles
  }//endfor
}


// clear the painting if the user touched the "Clear" button
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  // if the user touched the Clear button
  if (buttonIndex ==1 )
    [self resetView];	// clear the screen
}

// determines if this view can become the first responder
- (BOOL)canBecomeFirstResponder {
  return YES;
}

// called when a motion event, such as a shake, ends
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
  // if a shake event ended
  if (event.subtype == UIEventSubtypeMotionShake){
    // create an alert prompting the user about clearing the painting
    NSString *message = @"Are you sure you want to clear the painting?";
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Clear painting"
                                                     message:message
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"Clear", nil] autorelease];
    [alert show];
  }// end if
  [super motionEnded:motion withEvent:event];
} // end method

// called whenever the user places a finger on the screen
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  NSArray *array = [touches allObjects];	// get all the new touches

  // loop through each new touch
  for (UITouch *touch in array ) {
    // create and configure a new squiggle
    Squiggle *squiggle = [[Squiggle alloc] init];
    [squiggle setStrokeColor:self.color];	// set squiggle's stroke color
    [squiggle setLineWidth:self.lineWidth];	// set squiggle's line width

    // add the location of the first touch to the squiggle
    [squiggle addPoint:[touch locationInView:self]];

    // the key for each touch is the value of the pointer
    NSValue *touchValue = [NSValue valueWithPointer:touch];
    NSString *key = [NSString stringWithFormat:@"%@", touchValue];

    // add the new touch to the dictionary under a unique key
    [self.squiggles setValue:squiggle forKey:key];
    [squiggle release];	// we are done with squiggle so release it
  }	// end for
}


// called whenever the user drags a finger on the screen
- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  NSArray *array = [touches allObjects];	// get all the moved touches

  // loop through all the touches
  for (UITouch *touch in array) {
    // get the unique key for this touch
    NSValue * touchValue = [NSValue valueWithPointer:touch];

    // fetch the squiggle this touch should be added to using the key
    Squiggle *squiggle = [self.squiggles valueForKey:[NSString stringWithFormat:@"%@", touchValue]];

    // get the current and previous touch locations
    CGPoint current = [touch locationInView:self];
    CGPoint previous = [touch previousLocationInView:self];
    [squiggle addPoint:current];	// add the new point to the squiggle

    // screen needs to be redrawn
    CGPoint lower, higher;
    lower.x = (previous.x > current.x ? current.x : previous.x);
    lower.y	= (previous.y > current.y ? current.y: previous.y);
    higher.x = (previous.x < current.x ? current.x : previous.x);
    higher.y = (previous.y < current.y ? current.y: previous.y);

    // redraw the screen in the required region
    [self setNeedsDisplayInRect:CGRectMake(lower.x - self.lineWidth,
                                           lower.y - self.lineWidth, higher.x - lower.x + self.lineWidth * 2,
                                           higher.y - lower.y + self.lineWidth * 2)];
  }	// end for
}

// clear the paintings in main view
- (void)resetView {
  [self.squiggles removeAllObjects];
  [self.finishedSquiggles removeAllObjects];
  [self setNeedsDisplay];	// refresh the display
}

- (void)dealloc {
  self.squiggles = nil;
  self.finishedSquiggles = nil;
  self.color = nil;
  [super dealloc];
}

@end
