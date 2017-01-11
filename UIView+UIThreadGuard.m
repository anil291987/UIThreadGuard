//
//  UIView+UIThreadGuard.m
//  LayerDrawingAndAnimation
//
//  Created by Anil Upadhyay on 1/11/17.
//  Copyright (c) 2017 Anil Upadhyay. All rights reserved.
//

#import "UIView+UIThreadGuard.h"
#include <objc/runtime.h>
void swizzle(NSString *originalMethod, NSString *swizzledMethod, Class view){
    SEL originalSelector = NSSelectorFromString(originalMethod);
    SEL swizzledSelector = NSSelectorFromString(swizzledMethod);
    
    Method originalMethod1 = class_getInstanceMethod(view, originalSelector);
    Method swizzledMethod1 = class_getInstanceMethod(view, swizzledSelector);
    
    BOOL didAddMethod = class_addMethod(view, originalSelector, method_getImplementation(swizzledMethod1), method_getTypeEncoding(swizzledMethod1));
    
    if (didAddMethod) {
        class_replaceMethod(view, swizzledSelector, method_getImplementation(originalMethod1), method_getTypeEncoding(originalMethod1));
    } else {
        method_exchangeImplementations(originalMethod1, swizzledMethod1);
    }
}
@implementation UIView (UIThreadGuard)
#if DEBUG
+ (void)load {
}
+ (void)initialize {
    
    if (![self isSubclassOfClass:[UIResponder class]]) {
        return;
    }
    
    NSDictionary * methods = @{
                   @"setNeedsLayout": @"guardSetNeedsLayout",
                   @"setNeedsDisplay": @"guardSetNeedsDisplay",
                   @"setNeedsDisplayInRect:": @"guardSetNeedsDisplayInRect:"
                   };
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
    for (NSString *key in methods.allKeys) {
        swizzle(key, methods[key], self);
    }
    });
}

-(void) guardSetNeedsLayout {
    [self checkThread];
    [self guardSetNeedsLayout];
}

-(void)  guardSetNeedsDisplay {
    [self checkThread];
    [self guardSetNeedsDisplay];
}

-(void)  guardSetNeedsDisplayInRect:(CGRect) rect {
    [self checkThread];
    [self guardSetNeedsDisplayInRect:rect];
}
//If not on main thread, assert the app. From the left side thread stack view, you can easily find which line has problem
-(void) checkThread{
    NSAssert([NSThread isMainThread], @"You changed UI element not on main thread");
}
#endif
@end
