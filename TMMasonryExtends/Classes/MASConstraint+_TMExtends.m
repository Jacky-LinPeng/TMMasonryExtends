//
//  MASConstraint+_TMExtends.m
//  Masonry
//
//  Created by XiaobinLin on 2019/9/4.
//

#import "MASConstraint+_TMExtends.h"
#import <objc/runtime.h>

#define TMSwizzling(originalSelector, swizzledSelector) \
    { \
        Class class = [self class]; \
        Method originalMethod = class_getInstanceMethod(class, originalSelector); \
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector); \
        BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod)); \
        if (didAddMethod) { \
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod)); \
        } else { \
            method_exchangeImplementations(originalMethod, swizzledMethod); \
        } \
    }

@implementation MASConstraint (_TMExtends)
@dynamic layoutConstant;
@dynamic hasBeenInstalled;
@dynamic updateExisting;
@dynamic childConstraints;

- (CGFloat)_tm_originalConstant
{
    return [objc_getAssociatedObject(self, _cmd) floatValue];
}

- (void)set_tm_originalConstant:(CGFloat)originalConstant
{
    objc_setAssociatedObject(self, @selector(_tm_originalConstant), @(originalConstant), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)_tm_installWhenHiddenFlag
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)set_tm_installWhenHiddenFlag:(BOOL)tm_installWhenHiddenFlag
{
    objc_setAssociatedObject(self, @selector(_tm_installWhenHiddenFlag), @(tm_installWhenHiddenFlag), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)_tm_installWhenShowFlag
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)set_tm_installWhenShowFlag:(BOOL)tm_installWhenShowFlag
{
    objc_setAssociatedObject(self, @selector(_tm_installWhenShowFlag), @(tm_installWhenShowFlag), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)_tm_viewHidden
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)set_tm_viewHidden:(BOOL)tm_viewHidden
{
    objc_setAssociatedObject(self, @selector(_tm_viewHidden), @(tm_viewHidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)tm_updateConstantViewHidden:(BOOL)hidden
{
    self.layoutConstant = hidden ? 0 : self._tm_originalConstant;
}

- (void)tm_checkInstallViewHidden:(BOOL)hidden
{
    self._tm_viewHidden = hidden;
    
    if (self._tm_installWhenHiddenFlag && self._tm_viewHidden) {
        self.updateExisting = YES;
        [self install];
    } else if (self._tm_installWhenShowFlag && !self._tm_viewHidden) {
        self.updateExisting = YES;
        [self install];
    } else if (self._tm_installWhenShowFlag || self._tm_installWhenHiddenFlag) {
        [self tm_tryUninstall];
    }
}

- (void)tm_tryUninstall
{
    if ([self respondsToSelector:@selector(hasBeenInstalled)]) {
        if ([self hasBeenInstalled]) {
            [self uninstall];
        } else {
            [self deactivate];
        }
    } else {
        [self uninstall];
    }
}

@end


@interface MASLayoutConstraint (TMExtends)

- (BOOL)tm_layoutConstraintSimilarTo:(MASLayoutConstraint *)layoutConstraint;

@end

@implementation MASLayoutConstraint (TMExtends)

- (BOOL)tm_layoutConstraintSimilarTo:(MASLayoutConstraint *)existingConstraint {
    MASLayoutConstraint *layoutConstraint = self;

    if (![existingConstraint isKindOfClass:MASLayoutConstraint.class]) return NO;
    if (existingConstraint.firstItem != layoutConstraint.firstItem) return NO;
    if (existingConstraint.secondItem != layoutConstraint.secondItem) return NO;
    if (existingConstraint.firstAttribute != layoutConstraint.firstAttribute) return NO;
    if (existingConstraint.secondAttribute != layoutConstraint.secondAttribute) return NO;
    if (existingConstraint.relation != layoutConstraint.relation) return NO;
    if (existingConstraint.multiplier != layoutConstraint.multiplier) return NO;
    if (existingConstraint.priority != layoutConstraint.priority) return NO;

    return YES;
}

@end


@implementation MASViewConstraint (_TMExtends)
@dynamic layoutConstraint;
@dynamic layoutPriority;
@dynamic layoutRelation;
@dynamic layoutMultiplier;

+ (void)load
{
    TMSwizzling(@selector(install), @selector(tm_install));
}

- (void)tm_install
{
    if (self._tm_installWhenShowFlag || self._tm_installWhenHiddenFlag) {
        if (self._tm_installWhenShowFlag && !self._tm_viewHidden) {
            [self tm_install];
        } else if (self._tm_installWhenHiddenFlag && self._tm_viewHidden) {
            [self tm_install];
        }
    } else {
        [self tm_install];
    }
}

- (BOOL)tm_layoutConstraintSimilarTo:(MASViewConstraint *)constraint
{
    MASLayoutConstraint *selfLayoutConstraint = [self tm_layoutConstraint];
    MASLayoutConstraint *otherLayoutConstraint = [constraint tm_layoutConstraint];
    return [selfLayoutConstraint tm_layoutConstraintSimilarTo:otherLayoutConstraint];
}

- (MASLayoutConstraint *)tm_layoutConstraint
{
    if (self.layoutConstraint) {
        return self.layoutConstraint;
    }
    
    MAS_VIEW *firstLayoutItem = self.firstViewAttribute.item;
    NSLayoutAttribute firstLayoutAttribute = self.firstViewAttribute.layoutAttribute;
    MAS_VIEW *secondLayoutItem = self.secondViewAttribute.item;
    NSLayoutAttribute secondLayoutAttribute = self.secondViewAttribute.layoutAttribute;

    // alignment attributes must have a secondViewAttribute
    // therefore we assume that is refering to superview
    // eg make.left.equalTo(@10)
    if (!self.firstViewAttribute.isSizeAttribute && !self.secondViewAttribute) {
        secondLayoutItem = self.firstViewAttribute.view.superview;
        secondLayoutAttribute = firstLayoutAttribute;
    }
    
    MASLayoutConstraint *layoutConstraint
        = [MASLayoutConstraint constraintWithItem:firstLayoutItem
                                        attribute:firstLayoutAttribute
                                        relatedBy:self.layoutRelation
                                           toItem:secondLayoutItem
                                        attribute:secondLayoutAttribute
                                       multiplier:self.layoutMultiplier
                                         constant:self.layoutConstant];
    
    layoutConstraint.priority = self.layoutPriority;
    return layoutConstraint;
}

@end
