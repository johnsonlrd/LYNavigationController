//
//  LYNavigationController.m
//  LYNavigationController
//
//  Created by Liu Yue on 3/5/14.
//  Copyright (c) 2014 devliu.com. All rights reserved.
//

#import "LYNavigationController.h"
#import "AppDelegate.h"

#define IMAGE_SCALE .95
#define DEFAULT_ALPHA 0.75

@interface LYNavigationController () <UIGestureRecognizerDelegate>
{
    CGPoint _beginCenter;
}

@property (nonatomic, strong) NSMutableArray *previewImages;
@property (nonatomic, strong) UIImageView *previewImage;
@property (nonatomic, strong) UIView *alphaView;

@end

@implementation LYNavigationController

- (UIImage *)imageFromWindow
{
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    UIGraphicsBeginImageContext(window.bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [window.layer renderInContext:context];
    UIImage *snapShot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snapShot;
}

- (void)handlePan:(UIPanGestureRecognizer *)ges
{
    switch (ges.state) {
        case UIGestureRecognizerStateBegan:
        {
            _beginCenter = ges.view.center;
            
            self.previewImage = [[UIImageView alloc] initWithFrame:self.view.bounds];
            self.previewImage.image = [self.previewImages lastObject];
            
            self.alphaView = [[UIView alloc] initWithFrame:self.previewImage.bounds];
            self.alphaView.backgroundColor = [UIColor blackColor];
            
            [self.view.superview insertSubview:self.previewImage belowSubview:self.view];
            [self.view.superview insertSubview:self.alphaView aboveSubview:self.previewImage];
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGPoint p = [ges translationInView:self.view];
            if (p.x > 0) {
                self.view.center = CGPointMake(_beginCenter.x + p.x, _beginCenter.y);
                self.alphaView.alpha = DEFAULT_ALPHA - DEFAULT_ALPHA * p.x / 320.f;
                CGFloat scale = IMAGE_SCALE + (1 - IMAGE_SCALE) * (p.x / 320.f);
                self.previewImage.transform = CGAffineTransformScale(CGAffineTransformIdentity, scale, scale);
            }
        }
            break;
        case  UIGestureRecognizerStateCancelled:
            break;
        case UIGestureRecognizerStateEnded:
        {
            BOOL popTriggered = NO;
            CGPoint p = [ges translationInView:ges.view];
            CGPoint velocity = [ges velocityInView:ges.view];
            if (p.x + velocity.x * 0.2 > CGRectGetWidth(self.view.frame) / 2.0) {
                popTriggered = YES;
            }
            
            if (popTriggered) {
                
                [UIView animateWithDuration:0.5 * (1 - p.x / 320.f) animations:^{
                    self.view.center = CGPointMake(_beginCenter.x + 320, _beginCenter.y);
                    self.alphaView.alpha = 0.f;
                    self.previewImage.transform = CGAffineTransformIdentity;
                } completion:^(BOOL finished) {
                    [self.previewImage removeFromSuperview];
                    [self.alphaView removeFromSuperview];
                    self.previewImage = nil;
                    self.alphaView = nil;
                    ges.view.center = _beginCenter;
                    [self.previewImages removeLastObject];
                    [super popViewControllerAnimated:NO];
                }];
                
            } else {
                [UIView animateWithDuration:0.5 * p.x / 320 animations:^{
                    self.view.center = _beginCenter;
                    self.previewImage.transform = CGAffineTransformScale(CGAffineTransformIdentity, IMAGE_SCALE, IMAGE_SCALE);
                    self.alphaView.alpha = DEFAULT_ALPHA;
                } completion:^(BOOL finished) {
                    [self.previewImage removeFromSuperview];
                    [self.alphaView removeFromSuperview];
                    self.previewImage = nil;
                    self.alphaView = nil;
                }];
            }
            
            
        }
            break;
        case UIGestureRecognizerStateFailed:
            break;
        default:
            break;
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer
{
    return self.previewImages.count > 0;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        panGesture.delegate = self;
        [self.view addGestureRecognizer:panGesture];
        self.previewImages = [NSMutableArray array];
    });
   
    UIImage *snapShot = [self imageFromWindow];
    [self.previewImages addObject:snapShot];
    
    __block UIImageView *snapShotView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    snapShotView.image = snapShot;
    __block UIView *maskView = [[UIView alloc] initWithFrame:self.view.bounds];
    maskView.backgroundColor = [UIColor blackColor];
    maskView.alpha = 0.f;
    
    __block UIView *backgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    backgroundView.backgroundColor = [UIColor blackColor];
    
    [super pushViewController:viewController animated:animated];
    
    UIImage *toViewSnapShot = [self imageFromWindow];
    __block UIImageView *toView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    toView.image = toViewSnapShot;
    toView.frame = CGRectOffset(toView.frame, 320, 0);
    [self.view addSubview:backgroundView];
    [self.view addSubview:snapShotView];
    [self.view addSubview:maskView];
    [self.view addSubview:toView];
    
    [UIView animateWithDuration:.5 animations:^{
        toView.frame = self.view.frame;
        snapShotView.transform = CGAffineTransformScale(CGAffineTransformIdentity, IMAGE_SCALE, IMAGE_SCALE);
        maskView.alpha = DEFAULT_ALPHA;
    } completion:^(BOOL finished) {
        [toView removeFromSuperview];
        [maskView removeFromSuperview];
        [snapShotView removeFromSuperview];
        [backgroundView removeFromSuperview];
        
        toView = nil;
        maskView = nil;
        snapShotView = nil;
        backgroundView = nil;
    }];
}

- (void)animationPopToViewController:(UIViewController *)toViewController
{
    UIImage *fromSnapshot = [self imageFromWindow];
    __block UIImageView *fromSnapshotView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    fromSnapshotView.image = fromSnapshot;
    
    UIImage *toSnapshot = [self.previewImages objectAtIndex:[self.viewControllers indexOfObject:toViewController]];
    __block UIImageView *toSnapshotView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    toSnapshotView.image = toSnapshot;
    toSnapshotView.transform = CGAffineTransformScale(CGAffineTransformIdentity, IMAGE_SCALE, IMAGE_SCALE);
    
    __block UIView *maskView = [[UIView alloc] initWithFrame:self.view.bounds];
    maskView.backgroundColor = [UIColor blackColor];
    maskView.alpha = DEFAULT_ALPHA;
    
    __block UIView *backgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    backgroundView.backgroundColor = [UIColor blackColor];
    
    [self.view addSubview:backgroundView];
    [self.view addSubview:toSnapshotView];
    [self.view addSubview:maskView];
    [self.view addSubview:fromSnapshotView];
    
    [UIView animateWithDuration:.5 animations:^{
        fromSnapshotView.frame = CGRectOffset(fromSnapshotView.frame, 320, 0);
        maskView.alpha = 0;
        toSnapshotView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [fromSnapshotView removeFromSuperview];
        [maskView removeFromSuperview];
        [toSnapshotView removeFromSuperview];
        [backgroundView removeFromSuperview];
        fromSnapshotView = nil;
        maskView = nil;
        toSnapshotView = nil;
        backgroundView = nil;
    }];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    if (self.previewImages.count > 0) {
        UIViewController *toViewController = [self.viewControllers objectAtIndex:self.viewControllers.count - 2];
        [self animationPopToViewController:toViewController];
    }
    
    [self.previewImages removeLastObject];
    return [super popViewControllerAnimated:NO];
}

- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (self.previewImages.count > 0) {
        [self animationPopToViewController:viewController];
    }
    
    NSArray *array = [super popToViewController:viewController animated:animated];
    [self.previewImages removeObjectsInRange:NSMakeRange(self.viewControllers.count-1, array.count)];
    return array;
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated
{
    if (self.previewImages.count > 0) {
        [self animationPopToViewController:[self.viewControllers firstObject]];
    }
    
    [self.previewImages removeAllObjects];
    return [super popToRootViewControllerAnimated:animated];
}

@end
