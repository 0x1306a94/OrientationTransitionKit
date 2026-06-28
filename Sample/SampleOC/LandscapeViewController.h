//
//  LandscapeViewController.h
//  Sample
//
//  Created by KK on 2026/6/28.
//

#import "BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@import OrientationTransitionKit;

@interface LandscapeViewController : BaseViewController <OTKTransitionToContextProvider>

@property (nonatomic, weak, nullable) UIView *transitionContentView;
@property (nonatomic, copy, nullable) void (^didTapUserInfoHandler)(LandscapeViewController *viewController);

@end

NS_ASSUME_NONNULL_END
