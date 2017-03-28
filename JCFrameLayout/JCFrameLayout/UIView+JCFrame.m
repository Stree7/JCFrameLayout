//
//  UIView+JCFrame.m
//  JCFrameLayout
//
//  Created by abc on 17/3/27.
//  Copyright © 2017年 jackcat. All rights reserved.
//

#import "UIView+JCFrame.h"
#import <objc/runtime.h>

@implementation UIView (JCFrame)

- (void)setJc_x_value:(CGFloat)value{
    CGRect frame = self.frame;
    frame.origin.x = value;
    self.frame = frame;
}
- (CGFloat)jc_x_value{
    return self.frame.origin.x;
}

- (void)setJc_y_value:(CGFloat)value{
    CGRect frame = self.frame;
    frame.origin.y = value;
    self.frame = frame;
}
- (CGFloat)jc_y_value{
    return self.frame.origin.y;
}

- (void)setJc_width_value:(CGFloat)value{
    CGRect frame = self.frame;
    frame.size.width = value;
    self.frame = frame;
}
- (CGFloat)jc_width_value{
    return self.frame.size.width;
}

- (void)setJc_height_value:(CGFloat)value{
    CGRect frame = self.frame;
    frame.size.height = value;
    self.frame = frame;
}
- (CGFloat)jc_height_value{
    return self.frame.size.height;
}

- (void)setJc_centerX_value:(CGFloat)value{
    CGPoint center = self.center;
    center.x = value;
    self.center = center;
}
- (CGFloat)jc_centerX_value{
    return self.center.x;
}

- (void)setJc_centerY_value:(CGFloat)value{
    CGPoint center = self.center;
    center.y = value;
    self.center = center;
}
- (CGFloat)jc_centerY_value{
    return self.center.y;
}

- (NSMutableArray *)jc_frames{
    static char key;
    NSMutableArray *array = (NSMutableArray*)objc_getAssociatedObject(self, &key);
    if (!array) {
        array = [NSMutableArray array];
        objc_setAssociatedObject(self, &key, array, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return array;
}
@end
