//
//  GKBarGraph.m
//  GraphKit
//
//  Copyright (c) 2014 Michal Konturek
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "GKBarGraph.h"

#import <FrameAccessor/FrameAccessor.h>
#import <MKFoundationKit/NSArray+MK.h>

#import "GKBar.h"

static CGFloat kDefaultBarHeight = 140;
static CGFloat kDefaultBarWidth = 22;
static CGFloat kDefaultBarMargin = 20;
static CGFloat kDefaultLabelWidth = 50;
static CGFloat kDefaultLabelHeight = 15;

static CGFloat kDefaultAnimationDuration = 2.0;
@interface GKBarGraph ()
@property (strong, nonatomic) CALayer *gridLayer;
@end

@implementation GKBarGraph

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _init];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _init];
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)_init {
    self.animationDuration = kDefaultAnimationDuration;
    self.barHeight = kDefaultBarHeight;
    self.barWidth = kDefaultBarWidth;
    self.marginBar = kDefaultBarMargin;
}

- (void)setAnimated:(BOOL)animated {
    _animated = animated;
    [self.bars mk_each:^(GKBar *item) {
        item.animated = animated;
    }];
}

- (void)setAnimationDuration:(CFTimeInterval)animationDuration {
    _animationDuration = animationDuration;
    [self.bars mk_each:^(GKBar *item) {
        item.animationDuration = animationDuration;
    }];
}

- (void)setBarColor:(UIColor *)color {
    _barColor = color;
    [self.bars mk_each:^(GKBar *item) {
        item.foregroundColor = color;
    }];
}

- (void)draw {

    [self _construct];
    if ([self.dataSource respondsToSelector:@selector(numberOfVerticalSegments)]) {
        [self _drawGridLines:[self.dataSource numberOfVerticalSegments]];
    }
    [self _drawBars];
}

- (void)_construct {
    NSAssert(self.dataSource, @"GKBarGraph : No data source is assgined.");

    if ([self _hasBars]) [self _removeBars];
    if ([self _hasLabels]) [self _removeLabels];
    if (![self.verticalLabels mk_isEmpty]) {
        for (UILabel *label in self.verticalLabels) {
            [label removeFromSuperview];
        }
    }
    if (self.gridLayer) {
        [self.gridLayer removeFromSuperlayer];
    }

    [self _constructBars];
    [self _constructLabels];
    if ([self.dataSource respondsToSelector:@selector(numberOfVerticalSegments)]) {
        [self _contructYAxisLabels];
        [self _positionYAxisLabels];
    }
    [self _positionBars];
    [self _positionLabels];
}

- (BOOL)_hasBars {
    return ![self.bars mk_isEmpty];
}

- (void)_constructBars {
    NSInteger count = [self.dataSource numberOfBars];
    id items = [NSMutableArray arrayWithCapacity:count];
    for (NSInteger idx = 0; idx < count; idx++) {
        GKBar *item = [GKBar create];
        if ([self barColor]) item.foregroundColor = [self barColor];
        [items addObject:item];
    }
    self.bars = items;
}

- (void)_removeBars {
    [self.bars mk_each:^(id item) {
        [item removeFromSuperview];
    }];
}

- (void)_positionBars {
    CGFloat y = [self _barStartY];

    __block CGFloat x = [self _barStartX];
    [self.bars mk_each:^(GKBar *item) {
        item.frame = CGRectMake(x, y, _barWidth, _barHeight);
        [self addSubview:item];
        x += [self _barSpace];
    }];
}

- (CGFloat)_barStartX {
    CGFloat result = self.width;
    CGFloat item = [self _barSpace];
    NSInteger count = [self.dataSource numberOfBars];

    result = result - (item * count) + self.marginBar;
    result = (result / 2);
    return result;
}

- (CGFloat)_barSpace {
    return (self.barWidth + self.marginBar);
}

- (CGFloat)_barStartY {
    return (self.height - self.barHeight);
}

- (BOOL)_hasLabels {
    return ![self.labels mk_isEmpty];
}

- (void)_constructLabels {

    NSInteger count = [self.dataSource numberOfBars];
    id items = [NSMutableArray arrayWithCapacity:count];
    for (NSInteger idx = 0; idx < count; idx++) {

        CGRect frame = CGRectMake(0, 0, kDefaultLabelWidth, kDefaultLabelHeight);
        UILabel *item = [[UILabel alloc] initWithFrame:frame];
        item.textAlignment = NSTextAlignmentCenter;
        item.font = [UIFont fontWithName:@"STHeitiTC-Light" size:10];
        item.textColor = [UIColor whiteColor];
        item.text = [self.dataSource titleForBarAtIndex:idx];

        [items addObject:item];
    }
    self.labels = items;
}


- (void)_removeLabels {
    [self.labels mk_each:^(id item) {
        [item removeFromSuperview];
    }];
}

- (void)_positionLabels {

    __block NSInteger idx = 0;
    [self.bars mk_each:^(GKBar *bar) {

        CGFloat labelWidth = kDefaultLabelWidth;
        CGFloat labelHeight = kDefaultLabelHeight;
        CGFloat startX = bar.x - ((labelWidth - self.barWidth) / 2);
        CGFloat startY = (self.height - labelHeight + labelHeight*sin(M_PI / 8));
        //        CGFloat startY = (self.height - labelHeight);

        UILabel *label = [self.labels objectAtIndex:idx];
        label.x = startX;
        label.y = startY;
        [label setTransform:CGAffineTransformMakeRotation(M_PI / 8)];
        [self addSubview:label];

        bar.y -= labelHeight + 5;
        idx++;
    }];
}

- (UIBezierPath *)_bezierPathWith:(CGFloat)value {
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineCapStyle = kCGLineCapRound;
    path.lineJoinStyle = kCGLineJoinRound;
    path.lineWidth = 3.0f;
    return path;
}

- (CAShapeLayer *)_layerWithPath:(UIBezierPath *)path {
    CAShapeLayer *item = [CAShapeLayer layer];
    item.fillColor = [[UIColor blackColor] CGColor];
    item.lineCap = kCALineCapRound;
    item.lineJoin  = kCALineJoinRound;
    item.lineWidth = 5.0f;
    //    item.strokeColor = [self.foregroundColor CGColor];
    item.strokeColor = [[UIColor redColor] CGColor];
    item.strokeEnd = 1;
    return item;
}

- (void)_drawGridLines:(NSInteger) indexCount {
    UIGraphicsBeginImageContext(self.frame.size);

    UIBezierPath *path = [self _bezierPathWith:0];
    CAShapeLayer *layer = [self _layerWithPath:path];
    [layer setValue:[NSNumber numberWithInteger:-1] forKey:@"indexTag"];
    layer.strokeColor = [UIColor whiteColor].CGColor;
    layer.lineWidth = 0.5f;

    [self.layer insertSublayer:layer atIndex:0];

    CGFloat heightDifference = self.barHeight / indexCount;
    CGFloat horizontalGridLineLength = [self.dataSource numberOfBars] * [self _barSpace] + self.marginBar*2;
    CGFloat yOffset = [self _barStartY] - kDefaultLabelHeight - 5;
    for (int step = 0; step <= indexCount; step++)
    {
        [path moveToPoint:CGPointMake([self _barStartX] - 0.5 * self.marginBar, yOffset)];
        [path addLineToPoint:CGPointMake(horizontalGridLineLength, yOffset)];
        yOffset+=heightDifference;
    }

    layer.path = path.CGPath;
    self.gridLayer = layer;
    UIGraphicsEndImageContext();
}

- (void) _contructYAxisLabels
{
    NSInteger count = [self.dataSource numberOfVerticalSegments];
    id items = [NSMutableArray arrayWithCapacity:count];
    for (NSInteger idx = 0; idx < count; idx++) {
        NSString *itemString = [self.dataSource stringForVerticalSegmentAtIndex:idx];
        UIFont *font = [UIFont fontWithName:@"STHeitiTC-Light" size:10];
        CGRect frame = CGRectMake(0, 0, [itemString sizeWithAttributes:@{NSFontAttributeName:font}].width, kDefaultLabelHeight);
        UILabel *item = [[UILabel alloc] initWithFrame:frame];
        item.textAlignment = NSTextAlignmentCenter;
        item.font = font;
        item.textColor = [UIColor whiteColor];
        item.text = [self.dataSource stringForVerticalSegmentAtIndex:idx];

        [items addObject:item];
    }
    self.verticalLabels = items;
}

- (void) _positionYAxisLabels
{
    CGFloat heightDifference = self.barHeight / [self.dataSource numberOfVerticalSegments];
    CGFloat startX = -6;
    CGFloat startY = [self _barStartY] - kDefaultLabelHeight *1.5 - 5;
    CGFloat yOffset = 0;
    for (UILabel *label in self.verticalLabels) {
        label.x = startX;
        label.y = startY+yOffset;
        yOffset += heightDifference;
        [self addSubview:label];
    }
}

- (void)_drawBars {
    __block NSInteger idx = 0;
    id source = self.dataSource;
    [self.bars mk_each:^(GKBar *item) {

        if ([source respondsToSelector:@selector(animationDurationForBarAtIndex:)]) {
            item.animationDuration = [source animationDurationForBarAtIndex:idx];
        }

        if ([source respondsToSelector:@selector(colorForBarAtIndex:)]) {
            item.foregroundColor = [source colorForBarAtIndex:idx];
        }

        if ([source respondsToSelector:@selector(colorForBarBackgroundAtIndex:)]) {
            item.backgroundColor = [source colorForBarBackgroundAtIndex:idx];
        }

        item.percentage = [[source valueForBarAtIndex:idx] doubleValue];
        idx++;
    }];
}

- (void)reset {
    [self.bars mk_each:^(GKBar *item) {
        [item reset];
    }];
}

@end
