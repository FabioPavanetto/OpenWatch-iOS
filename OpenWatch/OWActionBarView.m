//
//  OWActionBarView.m
//  OpenWatch
//
//  Created by Christopher Ballinger on 5/2/13.
//  Copyright (c) 2013 OpenWatch FPC. All rights reserved.
//

#import "OWActionBarView.h"

@implementation OWActionBarView
@synthesize segmentedControl;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.segmentedControl = [[UISegmentedControl alloc] initWithFrame:frame];
        self.segmentedControl.momentary = YES;
        UIImage *videoImage = [UIImage imageNamed:@"279-videocamera.png"];
        UIImage *photoImage = [UIImage imageNamed:@"86-camera.png"];
        UIImage *audioImage = [UIImage imageNamed:@"66-microphone.png"];
        
        [self.segmentedControl insertSegmentWithImage:videoImage atIndex:0 animated:NO];
        [self.segmentedControl insertSegmentWithImage:photoImage atIndex:1 animated:NO];
        [self.segmentedControl insertSegmentWithImage:audioImage atIndex:2 animated:NO];
        
        [self addSubview:self.segmentedControl];
        [segmentedControl addTarget:self
                             action:@selector(segmentedControlValueChanged:)
                   forControlEvents:UIControlEventValueChanged];
    }
    return self;
}

- (void) setFrame:(CGRect)frame {
    [super setFrame:frame];
    self.segmentedControl.frame = frame;
}

- (void) segmentedControlValueChanged:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(actionBarView:didSelectButtonAtIndex:)]) {
        [self.delegate actionBarView:self didSelectButtonAtIndex:self.segmentedControl.selectedSegmentIndex];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
