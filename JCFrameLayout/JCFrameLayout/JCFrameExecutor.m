//
//  JCFrameExecutor.m
//  JCFrameLayout
//
//  Created by abc on 17/3/29.
//  Copyright © 2017年 jackcat. All rights reserved.
//

#import "JCFrameExecutor.h"

#import "UIView+JCFrame.h"

#import "JCFrameExecutorMethods.h"

#define SET_LEFT {\
JCFrame *left = [self filterFrameIn:frames frameType:(JCFrameTypeLeft)];\
setLeftByLeftFrame(view, left);\
}

#define SET_TOP {\
JCFrame *top = [self filterFrameIn:frames frameType:(JCFrameTypeTop)];\
setTopByTopFrame(view, top);\
}

#define SET_RIGHT {\
JCFrame *right = [self filterFrameIn:frames frameType:(JCFrameTypeRight)];\
setRightByRightFrame(view, right);\
}

#define SET_BOTTOM  {\
JCFrame *bottom = [self filterFrameIn:frames frameType:(JCFrameTypeBottom)];\
setBottomByBottomFrame(view, bottom);\
}

#define SET_LEFT_RIGHT {\
CGFloat leftX = 0;\
CGFloat rightX = 0;\
{\
    JCFrame *left = [self filterFrameIn:frames frameType:(JCFrameTypeLeft)];\
    if (left.hasRelateAttr) {\
        if (left.frameAttr.relateFrameType == JCFrameTypeLeft) {\
            leftX = left.frameAttr.relateView.jc_x_value;\
        }else if (left.frameAttr.relateFrameType == JCFrameTypeCenterX) {\
            leftX = left.frameAttr.relateView.jc_centerX_value;\
        }else if (left.frameAttr.relateFrameType == JCFrameTypeRight) {\
            leftX = left.frameAttr.relateView.jc_right_value;\
        }\
        leftX = leftX * left.multiplier + ((NSNumber*)left.offset).doubleValue;\
    }else{\
        leftX = ((NSNumber*)left.value).doubleValue;\
    }\
    left.jc_equalTo(leftX);\
    view.jc_x_value = leftX;\
}\
{\
    JCFrame *right = [self filterFrameIn:frames frameType:(JCFrameTypeRight)];\
    if (right.hasRelateAttr) {\
        if (right.frameAttr.relateFrameType == JCFrameTypeLeft) {\
            rightX = right.frameAttr.relateView.jc_y_value;\
        }else if (right.frameAttr.relateFrameType == JCFrameTypeCenterX) {\
            rightX = right.frameAttr.relateView.jc_centerY_value;\
        }else if (right.frameAttr.relateFrameType == JCFrameTypeRight) {\
            rightX = right.frameAttr.relateView.jc_bottom_value;\
        }\
        rightX = rightX * right.multiplier + ((NSNumber*)right.offset).doubleValue;\
    }else{\
        rightX = view.superview.jc_width_value + ((NSNumber*)right.value).doubleValue;\
    }\
}\
view.jc_width_value = rightX/*右边X*/ - leftX/*左边X*/;\
}

#define SET_TOP_BOTTOM {\
CGFloat topY = 0;\
CGFloat bottomY = 0;\
{\
    JCFrame *top = [self filterFrameIn:frames frameType:(JCFrameTypeTop)];\
    if (top.hasRelateAttr) {\
        if (top.frameAttr.relateFrameType == JCFrameTypeTop) {\
            topY = top.frameAttr.relateView.jc_y_value;\
        }else if (top.frameAttr.relateFrameType == JCFrameTypeCenterY) {\
            topY = top.frameAttr.relateView.jc_centerY_value;\
        }else if (top.frameAttr.relateFrameType == JCFrameTypeBottom) {\
            topY = top.frameAttr.relateView.jc_bottom_value;\
        }\
        topY = topY * top.multiplier + ((NSNumber*)top.offset).doubleValue;\
    }else{\
        topY = ((NSNumber*)top.value).doubleValue;\
    }\
    top.jc_equalTo(topY);\
    view.jc_y_value = topY;\
}\
{\
    JCFrame *bottom = [self filterFrameIn:frames frameType:(JCFrameTypeBottom)];\
    if (bottom.hasRelateAttr) {\
        if (bottom.frameAttr.relateFrameType == JCFrameTypeTop) {\
            bottomY = bottom.frameAttr.relateView.jc_x_value;\
        }else if (bottom.frameAttr.relateFrameType == JCFrameTypeCenterY) {\
            bottomY = bottom.frameAttr.relateView.jc_centerY_value;\
        }else if (bottom.frameAttr.relateFrameType == JCFrameTypeBottom) {\
            bottomY = bottom.frameAttr.relateView.jc_bottom_value;\
        }\
        bottomY = bottomY * bottom.multiplier + ((NSNumber*)bottom.offset).doubleValue;\
    }else{\
        bottomY = view.superview.jc_height_value/*父容器高度*/ + ((NSNumber*)bottom.value).doubleValue/*底边距*/;\
    }\
}\
view.jc_height_value = bottomY - topY;\
}

#define SET_CENTER_X {\
JCFrame *centerX = [self filterFrameIn:frames frameType:(JCFrameTypeCenterX)];\
setCenterXByCenterXFrame(view, centerX);\
}

#define SET_CENTER_Y {\
JCFrame *centerY = [self filterFrameIn:frames frameType:(JCFrameTypeCenterY)];\
setCenterYByCenterYFrame(view, centerY);\
}

#define SET_WIDTH {\
JCFrame *width = [self filterFrameIn:frames frameType:(JCFrameTypeWidth)];\
setWidthByWidthFrame(view, width);\
}

#define SET_HEIGHT {\
JCFrame *height = [self filterFrameIn:frames frameType:(JCFrameTypeHeight)];\
setHeightByHeightFrame(view, height);\
}

#define SET_SIZE { \
JCFrame *size = [self filterFrameIn:frames frameType:(JCFrameTypeSize)]; \
setSizeBySizeFrame(view, size); \
}

#define SET_CENTER {\
JCFrame *center = [self filterFrameIn:frames frameType:(JCFrameTypeCenter)];\
setCenterByCenterFrame(view,center);\
}



@implementation JCFrameExecutor

//### 属性优先级设定
//
//  ####属性的分类
//      * 复合属性(Center、Size)
//      * 简单属性(除Center、Size之外的属性)
//      * 中心属性(CenterX、CenterY)
//      * 边界属性(Left、Top、Right、Bottom)
//      * 尺寸属性(With、Height)
//
//  ####优先级
//      1. 复合属性 > 简单属性
//      2. 中心属性 > 尺寸属性 > 边界属性
//      3. Left > Right
//      4. Top > Bottom
//
//  ####可能的情况
//      含有 center 和 size
//      1. center and size
//
//      只有 center
//      2. center and width and height
//
//      只有 size 和 (centerX 或 centerY)
//      3. centerX and centerY and size
//      4. centerX and top and size
//      5. centerX and bottom and size
//      6. centerY and left and size
//      7. centerY and right and size
//
//      只有 size
//      8. left and top and size
//      9. left and bottom and size
//      10. right and top and size
//      11. right and bottom and size

//      含有centerX 或 centerY
//      12. centerX and centerY and width and height
//      13. centerX and top and width and height
//      14. centerX and bottom and width and height
//      15. centerY and left and width and height
//      16. centerY and right and width and height

//      含有2条边界值，2个尺寸
//      17. left and top and width and height
//      18. left and bottom and width and height
//      19. right and top and width and height
//      20. right and bottom and width and height

//      含有3条边距值,1个尺寸值
//      21. left and right and top and height
//      22. left and right and bottom and height
//      23. left and top and bottom and width
//      24. right and top and bottom and width

//      含有4条边距值
//      25. left and right and top and bottom

+ (void)executeWithView:(UIView*)view frameTypes:(JCFrameType)frameTypes{
    
    //      1. center and size
    if ([self layoutByCenterAndSize:view frameTypes:frameTypes]) {
        return;
    }
    
    //      2. center and width and height
    if ([self layoutByCenterAndWidthAndHeight:view frameTypes:frameTypes]) {
        return;
    }
    
    //      3. centerX and centerY and size
    if ([self layoutByCenterXAndCenterYAndSize:view frameTypes:frameTypes]) {
        return;
    }
    
    //      4. centerX and top and size
    if ([self layoutByCenterXAndTopAndSize:view frameTypes:frameTypes]) {
        return;
    }
    
    //      5. centerX and bottom and size
    if ([self layoutByCenterXAndBottomAndSize:view frameTypes:frameTypes]) {
        return;
    }
    
    //      6. centerY and left and size
    if ([self layoutByCenterYAndLeftAndSize:view frameTypes:frameTypes]) {
        return;
    }
    
    
    //      7. centerY and right and size
    if ([self layoutByCenterYAndRightAndSize:view frameTypes:frameTypes]) {
        return;
    }
    
    //      8. left and top and size
    if ([self layoutByLeftAndTopAndSize:view frameTypes:frameTypes]) {
        return;
    }
    
    
    //      9. left and bottom and size
    if ([self layoutByLeftAndBottomAndSize:view frameTypes:frameTypes]) {
        return;
    }
    
    //      10. right and top and size
    if ([self layoutByRightAndTopAndSize:view frameTypes:frameTypes]) {
        return;
    }
    
    
    //      11. right and bottom and size
    if ([self layoutByRightAndBottomAndSize:view frameTypes:frameTypes]) {
        return;
    }
    
    //      12. centerX and centerY and width and height
    if ([self layoutByCenterXAndCenterYAndWidthAndHeight:view frameTypes:frameTypes]) {
        return;
    }
    
    //      13. centerX and top and width and height
    if ([self layoutByCenterXAndTopAndWidthAndHeight:view frameTypes:frameTypes]) {
        return;
    }
    
    //      14. centerX and bottom and width and height
    if ([self layoutByCenterXAndBottomAndWidthAndHeight:view frameTypes:frameTypes]) {
        return;
    }
    
    //      15. centerY and left and width and height
    if ([self layoutByCenterYAndLeftAndWidthAndHeight:view frameTypes:frameTypes]) {
        return;
    }
    
    //      16. centerY and right and width and height
    if ([self layoutByCenterYAndRightAndWidthAndHeight:view frameTypes:frameTypes]) {
        return;
    }
    
    //      含有2条边界值，2个尺寸
    //      17. left and top and width and height
    if ([self layoutByLeftAndTopAndWidthAndHeight:view frameTypes:frameTypes]) {
        return;
    }
    
    //      18. left and bottom and width and height
    if ([self layoutByLeftAndBottomAndWidthAndHeight:view frameTypes:frameTypes ]) {
        return;
    }
    
    //      19. right and top and width and height
    if ([self layoutByRightAndTopAndWidthAndHeight:view frameTypes:frameTypes]) {
        return;
    }
    
    //      20. right and bottom and width and height
    if ([self layoutByRightAndBottomAndWidthAndHeight:view frameTypes:frameTypes]) {
        return;
    }
    
    //      含有3条边距值,1个尺寸值
    //      21. left and right and top and height
    if ([self layoutByLeftAndRightAndTopAndHeight:view frameTypes:frameTypes]) {
        return;
    }
    
    //      22. left and right and bottom and height
    if ([self layoutByLeftAndRightAndBottomAndHeight:view frameTypes:frameTypes]) {
        return;
    }
    
    //      23. left and top and bottom and width
    if ([self layoutByLeftAndTopAndBottomAndWidth:view frameTypes:frameTypes]) {
        return;
    }
    
    //      24. right and top and bottom and width
    if ([self layoutByRightAndTopAndBottomAndWidth:view frameTypes:frameTypes]) {
        
        return;
    }
    
    //      含有4条边距值
    //      25. left and right and top and bottom
    if ([self layoutByLeftAndRightAndTopAndBottom:view frameTypes:frameTypes]) {
        
        return;
    }
}

#pragma mark - 含有 center 和 size
//      1. center and size
+ (BOOL)layoutByCenterAndSize:(UIView*)view frameTypes:(JCFrameType)frameTypes{

    if ((frameTypes & JCFrameTypeCenter)
        &&(frameTypes & JCFrameTypeSize)) {
        
        NSArray<JCFrame*>*frames = view.jc_frames;
        
        //1. 先size
        SET_SIZE
        
        //2. 后Center
        SET_CENTER
        
        return YES;
    }
    
    return NO;
}

#pragma mark - 只有 center
//      2. center and width and height
+ (BOOL)layoutByCenterAndWidthAndHeight:(UIView*)view frameTypes:(JCFrameType)frameTypes{

    if ((frameTypes & JCFrameTypeCenter)
        &&(frameTypes & JCFrameTypeWidth)
        &&(frameTypes & JCFrameTypeHeight)) {
        
        NSArray<JCFrame*>*frames = view.jc_frames;
        
        //1. 设置宽度
        SET_WIDTH
        
        //2. 设置高度
        SET_HEIGHT
        
        
        //3. 设置center
        SET_CENTER
        
        return YES;
    }
    return NO;
    
}

#pragma mark - 只有 size 和 (centerX 或 centerY)
//      3. centerX and centerY and size
+ (BOOL)layoutByCenterXAndCenterYAndSize:(UIView*)view frameTypes:(JCFrameType)frameTypes{
    
    if ((frameTypes & JCFrameTypeCenterX)
        &&(frameTypes & JCFrameTypeCenterY)
        &&(frameTypes & JCFrameTypeSize)) {
        
        NSArray<JCFrame*>*frames = view.jc_frames;
        
        //1. 设置size
        SET_SIZE
        
        //2. 设置centerX
        SET_CENTER_X
        
        //3. 设置centerY
        SET_CENTER_Y
        
        return YES;
    }
    
    return NO;
}

//      4. centerX and top and size
+ (BOOL)layoutByCenterXAndTopAndSize:(UIView*)view frameTypes:(JCFrameType)frameTypes{
    if ((frameTypes & JCFrameTypeCenterX)
        &&(frameTypes & JCFrameTypeTop)
        &&(frameTypes & JCFrameTypeSize)) {
        
        NSArray<JCFrame*>*frames = view.jc_frames;
        
        //1. size
        SET_SIZE
        
        //2. top
        SET_TOP
        
        //3. centerX
        SET_CENTER_X
        
        
        return YES;
    }

    return NO;
}

//      5. centerX and bottom and size
+ (BOOL)layoutByCenterXAndBottomAndSize:(UIView*)view frameTypes:(JCFrameType)frameTypes{NSArray<JCFrame*>*frames = view.jc_frames;
    if ((frameTypes & JCFrameTypeCenterX)
        &&(frameTypes & JCFrameTypeBottom)
        &&(frameTypes & JCFrameTypeSize)) {
        
        //1. size
        SET_SIZE
        
        //2. centerX
        SET_CENTER_X
        
        //3. bottom
       SET_BOTTOM
        
        return NO;
    }
    return NO;
}

//      6. centerY and left and size
+ (BOOL)layoutByCenterYAndLeftAndSize:(UIView*)view frameTypes:(JCFrameType)frameTypes{
    
    if ((frameTypes & JCFrameTypeCenterY)
        &&(frameTypes & JCFrameTypeLeft)
        &&(frameTypes & JCFrameTypeSize)) {
        
        NSArray<JCFrame*>*frames = view.jc_frames;
        
        //1. size
        SET_SIZE
        
        //2. centerY
        SET_CENTER_Y
        
        //3. left
        SET_LEFT
        
        return YES;
    }
    return NO;
}

//      7. centerY and right and size
+ (BOOL)layoutByCenterYAndRightAndSize:(UIView*)view frameTypes:(JCFrameType)frameTypes{NSArray<JCFrame*>*frames = view.jc_frames;
    
    if ((frameTypes & JCFrameTypeCenterY)
        &&(frameTypes & JCFrameTypeRight)
        &&(frameTypes & JCFrameTypeSize)) {
        
        //1. size
        SET_SIZE
        
        //2. centerY
        SET_CENTER_Y
        
        //3. right
        SET_RIGHT
        
        return YES;
    }
    
    return NO;
}

#pragma mark - 只有 size
//      8. left and top and size
+ (BOOL)layoutByLeftAndTopAndSize:(UIView*)view frameTypes:(JCFrameType)frameTypes{NSArray<JCFrame*>*frames = view.jc_frames;
    if ((frameTypes & JCFrameTypeLeft)
        &&(frameTypes & JCFrameTypeTop)
        &&(frameTypes & JCFrameTypeSize)) {
        
        //1. size
        SET_SIZE
        
        //2. left
        SET_LEFT
        
        //3. top
        SET_TOP
        
        return YES;
    }
    return NO;
}

//      9. left and bottom and size
+ (BOOL)layoutByLeftAndBottomAndSize:(UIView*)view frameTypes:(JCFrameType)frameTypes{NSArray<JCFrame*>*frames = view.jc_frames;
    
    if ((frameTypes & JCFrameTypeLeft)
        &&(frameTypes & JCFrameTypeBottom)
        &&(frameTypes & JCFrameTypeSize)) {
        
        //1. size
        SET_SIZE
        
        //2. left
        SET_LEFT
        
        //3. bottom
        SET_BOTTOM
        
        return YES;
    }
    return NO;
}

//      10. right and top and size
+ (BOOL)layoutByRightAndTopAndSize:(UIView*)view frameTypes:(JCFrameType)frameTypes{
    
    NSArray<JCFrame*>*frames = view.jc_frames;
    
    if ((frameTypes & JCFrameTypeRight)
        &&(frameTypes & JCFrameTypeTop)
        &&(frameTypes & JCFrameTypeSize)) {
        
        //1. size
        SET_SIZE
        
        //2. top
        SET_TOP
        
        //3. right
        SET_RIGHT
        return YES;
    }
    
    return NO;
}

//      11. right and bottom and size
+ (BOOL)layoutByRightAndBottomAndSize:(UIView*)view frameTypes:(JCFrameType)frameTypes{NSArray<JCFrame*>*frames = view.jc_frames;
    
    if ((frameTypes & JCFrameTypeRight)
        &&(frameTypes & JCFrameTypeBottom)
        &&(frameTypes & JCFrameTypeSize)) {
        
        //1. size
        SET_SIZE
        
        //2. right
        SET_RIGHT
        
        //3. bottom
        SET_BOTTOM
        
        return YES;
    }
    
    return NO;
}

#pragma mark - 含有centerX 或 centerY
//      12. centerX and centerY and width and height
+ (BOOL)layoutByCenterXAndCenterYAndWidthAndHeight:(UIView*)view frameTypes:(JCFrameType)frameTypes{
    NSArray<JCFrame*>*frames = view.jc_frames;
    
    if ((frameTypes & JCFrameTypeCenterX)
        &&(frameTypes & JCFrameTypeCenterY)
        &&(frameTypes & JCFrameTypeWidth)
        &&(frameTypes & JCFrameTypeHeight)) {
        
        //1. width
        SET_WIDTH
        
        //2. height
        SET_HEIGHT
        
        //3. centerX
        SET_CENTER_X
        
        //4. centerY
        SET_CENTER_Y
        
        return YES;
    }

    
    return NO;
}

//      13. centerX and top and width and height
+ (BOOL)layoutByCenterXAndTopAndWidthAndHeight:(UIView*)view frameTypes:(JCFrameType)frameTypes{
    NSArray<JCFrame*>*frames = view.jc_frames;
    
    if ((frameTypes & JCFrameTypeCenterX)
        &&(frameTypes & JCFrameTypeTop)
        &&(frameTypes & JCFrameTypeWidth)
        &&(frameTypes & JCFrameTypeHeight)) {
        
        //1. width
        SET_WIDTH
        
        //2. height
        SET_HEIGHT
        
        //3. centerX
        SET_CENTER_X
        
        //4. top
        SET_TOP
        
        return YES;
    }
    
    return NO;
}

//      14. centerX and bottom and width and height
+ (BOOL)layoutByCenterXAndBottomAndWidthAndHeight:(UIView*)view frameTypes:(JCFrameType)frameTypes{
    
    NSArray<JCFrame*>*frames = view.jc_frames;
    
    if ((frameTypes & JCFrameTypeCenterX)
        &&(frameTypes & JCFrameTypeBottom)
        &&(frameTypes & JCFrameTypeWidth)
        &&(frameTypes & JCFrameTypeHeight)) {
        
        //1. width
        SET_WIDTH
        
        //2. height
        SET_HEIGHT
        
        //3. centerX
        SET_CENTER_X
        
        //4. bottom
        SET_BOTTOM
        
        return YES;
    }
    
    return NO;
}

//      15. centerY and left and width and height
+ (BOOL)layoutByCenterYAndLeftAndWidthAndHeight:(UIView*)view frameTypes:(JCFrameType)frameTypes{
    
    NSArray<JCFrame*>*frames = view.jc_frames;
    
    if ((frameTypes & JCFrameTypeCenterY)
        &&(frameTypes & JCFrameTypeLeft)
        &&(frameTypes & JCFrameTypeWidth)
        &&(frameTypes & JCFrameTypeHeight)) {
        
        //1. width
        SET_WIDTH
        
        //2. height
        SET_HEIGHT
        
        //3. left
        SET_LEFT
        
        //4. centerY
        SET_CENTER_Y
        
        return YES;
    }
    
    return NO;
}

//      16. centerY and right and width and height
+ (BOOL)layoutByCenterYAndRightAndWidthAndHeight:(UIView*)view frameTypes:(JCFrameType)frameTypes{
    
    NSArray<JCFrame*>*frames = view.jc_frames;
    
    if ((frameTypes & JCFrameTypeCenterY)
        &&(frameTypes & JCFrameTypeRight)
        &&(frameTypes & JCFrameTypeWidth)
        &&(frameTypes & JCFrameTypeHeight)) {
        
        //1. width
        SET_WIDTH
        
        //2. height
        SET_HEIGHT
        
        //3. centerY
        SET_CENTER_Y
        
        //4. right
        SET_RIGHT
        
        return YES;
    }
    
    return NO;
}

#pragma mark - 含有2条边界值，2个尺寸的组合
//      17. left and top and width and height
+ (BOOL)layoutByLeftAndTopAndWidthAndHeight:(UIView*)view frameTypes:(JCFrameType)frameTypes{
    
    NSArray<JCFrame*>*frames = view.jc_frames;
    
    if ((frameTypes & JCFrameTypeLeft)
        &&(frameTypes & JCFrameTypeTop)
        &&(frameTypes & JCFrameTypeWidth)
        &&(frameTypes & JCFrameTypeHeight)) {
        
        //1. width
        SET_WIDTH
        
        //2. height
        SET_HEIGHT
        
        //3. top
        SET_TOP
        
        //4. left
        SET_LEFT
        
        return YES;
    }
    
    return NO;
}

//      18. left and bottom and width and height
+ (BOOL)layoutByLeftAndBottomAndWidthAndHeight:(UIView*)view frameTypes:(JCFrameType)frameTypes{
    NSArray<JCFrame*>*frames = view.jc_frames;
    
    if ((frameTypes & JCFrameTypeLeft)
        &&(frameTypes & JCFrameTypeBottom)
        &&(frameTypes & JCFrameTypeWidth)
        &&(frameTypes & JCFrameTypeHeight)) {
        
        //1. width
        SET_WIDTH
        
        //2. height
        SET_HEIGHT
        
        //3. bottom
        SET_BOTTOM
        
        //4. left
        SET_LEFT
        
        
        return YES;
    }
    
    return NO;
}

//      19. right and top and width and height
+ (BOOL)layoutByRightAndTopAndWidthAndHeight:(UIView*)view frameTypes:(JCFrameType)frameTypes{
    
    NSArray<JCFrame*>*frames = view.jc_frames;
    
    if ((frameTypes & JCFrameTypeRight)
        &&(frameTypes & JCFrameTypeTop)
        &&(frameTypes & JCFrameTypeWidth)
        &&(frameTypes & JCFrameTypeHeight)) {
        
        //1. width
        SET_WIDTH
        
        //2. height
        SET_HEIGHT
        
        //3. right
        SET_RIGHT
        
        //4. top
        SET_TOP
        
        return YES;
    }
    
    return NO;
}

//      20. right and bottom and width and height
+ (BOOL)layoutByRightAndBottomAndWidthAndHeight:(UIView*)view frameTypes:(JCFrameType)frameTypes{
    NSArray<JCFrame*>*frames = view.jc_frames;
    
    if ((frameTypes & JCFrameTypeRight)
        &&(frameTypes & JCFrameTypeBottom)
        &&(frameTypes & JCFrameTypeWidth)
        &&(frameTypes & JCFrameTypeHeight)) {
        
        //1. width
        SET_WIDTH
        
        //2. height
        SET_HEIGHT
        
        //3. right
        SET_RIGHT
        
        //4. bottom
        SET_BOTTOM
        
        return YES;
    }
    
    return NO;

}

#pragma mark - 含有3条边距值,1个尺寸值的组合
//      21. left and right and top and height
+ (BOOL)layoutByLeftAndRightAndTopAndHeight:(UIView*)view frameTypes:(JCFrameType)frameTypes{
    
    
    NSArray<JCFrame*>*frames = view.jc_frames;
    
    if ((frameTypes & JCFrameTypeLeft)
        &&(frameTypes & JCFrameTypeRight)
        &&(frameTypes & JCFrameTypeTop)
        &&(frameTypes & JCFrameTypeHeight)) {
        
        //1. height
        SET_HEIGHT
        
        //2. top
        SET_TOP
        
        //3. left and right
        SET_LEFT_RIGHT
        
        return YES;
    }
    
    return NO;

}

//      22. left and right and bottom and height
+ (BOOL)layoutByLeftAndRightAndBottomAndHeight:(UIView*)view frameTypes:(JCFrameType)frameTypes{
    
    NSArray<JCFrame*>*frames = view.jc_frames;
    
    if ((frameTypes & JCFrameTypeLeft)
        &&(frameTypes & JCFrameTypeRight)
        &&(frameTypes & JCFrameTypeBottom)
        &&(frameTypes & JCFrameTypeHeight)) {
        
        //1. height
        SET_HEIGHT
        
        //2. bottom
        SET_BOTTOM
        
        //3. left and right
        SET_LEFT_RIGHT
        
        return YES;
    }
    
    return NO;

}

//      23. left and top and bottom and width
+ (BOOL)layoutByLeftAndTopAndBottomAndWidth:(UIView*)view frameTypes:(JCFrameType)frameTypes{
    
    NSArray<JCFrame*>*frames = view.jc_frames;
    
    if ((frameTypes & JCFrameTypeLeft)
        &&(frameTypes & JCFrameTypeTop)
        &&(frameTypes & JCFrameTypeBottom)
        &&(frameTypes & JCFrameTypeWidth)) {
        
        //1. width
        SET_WIDTH
        
        //2. left
        SET_LEFT
        
        //3. top and bottom
        SET_TOP_BOTTOM
        
        return YES;
    }
    
    return NO;

}

//      24. right and top and bottom and width
+ (BOOL)layoutByRightAndTopAndBottomAndWidth:(UIView*)view frameTypes:(JCFrameType)frameTypes{
    NSArray<JCFrame*>*frames = view.jc_frames;
    
    if ((frameTypes & JCFrameTypeRight)
        &&(frameTypes & JCFrameTypeTop)
        &&(frameTypes & JCFrameTypeBottom)
        &&(frameTypes & JCFrameTypeWidth)) {
        
        //1. width
        SET_WIDTH
        
        //2. right
        SET_RIGHT
        
        //3. top and bottom
        SET_TOP_BOTTOM
        
        return YES;
    }

    
    return NO;

}

#pragma mark - 含有4条边距值
//      25. left and right and top and bottom
+ (BOOL)layoutByLeftAndRightAndTopAndBottom:(UIView*)view frameTypes:(JCFrameType)frameTypes{
    NSArray<JCFrame*>*frames = view.jc_frames;
    
    if ((frameTypes & JCFrameTypeLeft)
        &&(frameTypes & JCFrameTypeRight)
        &&(frameTypes & JCFrameTypeTop)
        &&(frameTypes & JCFrameTypeBottom)) {
        
        //1. left and right
        SET_LEFT_RIGHT
        
        //2. top and bottom
        SET_TOP_BOTTOM
        
        return YES;
    }

    
    return NO;

}

#pragma mark - 过滤的公共方法
+ (JCFrame*)filterFrameIn:(NSArray*)collection frameType:(JCFrameType)frameType{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(JCFrame *frame, id obj) {
        return frame.frameAttr.currentFrameType == frameType;
    }];
    NSArray *result = [collection filteredArrayUsingPredicate:predicate];
    JCFrame *frame = (result && result.count > 0) ? result.firstObject : nil;
    //将Frame的actived标记为YES
    frame.actived = YES;
    return frame;
}

@end
