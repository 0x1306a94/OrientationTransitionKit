//
//  LandscapeViewController.m
//  Sample
//
//  Created by KK on 2026/6/28.
//

#import "LandscapeViewController.h"

@import OrientationTransitionKit;

@interface LandscapeViewController () <OTKTransitionToContextProvider>
@property (nonatomic, strong) UIView *playerContainerView;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *userInfoButton;
@property (nonatomic, assign) BOOL shouldHideHomeIndicator;
@end

@implementation LandscapeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.blackColor;

    _playerContainerView = [UIView new];
    _playerContainerView.backgroundColor = UIColor.blackColor;
    _playerContainerView.translatesAutoresizingMaskIntoConstraints = NO;

    _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _closeButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.55];
    _closeButton.layer.cornerRadius = 6;
    _closeButton.clipsToBounds = YES;
    [_closeButton setTitle:@"退出全屏" forState:UIControlStateNormal];
    [_closeButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _closeButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    _closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_closeButton addTarget:self action:@selector(closeButtonTapped) forControlEvents:UIControlEventTouchUpInside];

    _userInfoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _userInfoButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.55];
    _userInfoButton.layer.cornerRadius = 6;
    _userInfoButton.clipsToBounds = YES;
    [_userInfoButton setTitle:@"用户主页" forState:UIControlStateNormal];
    [_userInfoButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _userInfoButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    _userInfoButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_userInfoButton addTarget:self action:@selector(userInfoButtonTapped) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:_playerContainerView];
    [self.view addSubview:_closeButton];
    [self.view addSubview:_userInfoButton];

    [NSLayoutConstraint activateConstraints:@[
        [_playerContainerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_playerContainerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_playerContainerView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [_playerContainerView.heightAnchor constraintEqualToAnchor:self.view.heightAnchor],

        [_closeButton.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:20],
        [_closeButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
        [_closeButton.widthAnchor constraintEqualToConstant:96],
        [_closeButton.heightAnchor constraintEqualToConstant:44],

        [_userInfoButton.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-20],
        [_userInfoButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
        [_userInfoButton.widthAnchor constraintEqualToConstant:96],
        [_userInfoButton.heightAnchor constraintEqualToConstant:44],
    ]];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationLandscapeRight;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return self.shouldHideHomeIndicator;
}

- (void)closeButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)userInfoButtonTapped {
    if (self.didTapUserInfoHandler != nil) {
        self.didTapUserInfoHandler(self);
    }
}

- (void)setHomeIndicatorHidden:(BOOL)hidden {
    self.shouldHideHomeIndicator = hidden;
    [self setNeedsUpdateOfHomeIndicatorAutoHidden];
}

- (UIViewController *)transitionToContextProviderViewController:(id<OTKTransitionToContextProvider>)contextProvider {
    return self;
}

- (CGRect)transitionToContextProviderTransitionFrame:(id<OTKTransitionToContextProvider>)contextProvider in:(UIView *)containerView {
    return [containerView convertRect:self.playerContainerView.bounds fromView:self.playerContainerView];
}

- (void)transitionToContextProviderPrepareTransitionView:(id<OTKTransitionToContextProvider>)contextProvider transitionView:(UIView *)transitionView {
    [self moveTransitionContentToContainerView:transitionView];
}

- (void)transitionToContextProviderFinishTransitionView:(id<OTKTransitionToContextProvider>)contextProvider {
    [self moveTransitionContentToContainerView:self.playerContainerView];
}

- (void)transitionToContextProviderTransitionWillEnter:(id<OTKTransitionToContextProvider>)contextProvider from:(id<OTKTransitionFromContextProvider>)fromContextProvider {
    [self setHomeIndicatorHidden:YES];
}

- (void)transitionToContextProviderTransitionDidEnter:(id<OTKTransitionToContextProvider>)contextProvider from:(id<OTKTransitionFromContextProvider>)fromContextProvider {
    [self setHomeIndicatorHidden:YES];
}

- (void)transitionToContextProviderTransitionWillExit:(id<OTKTransitionToContextProvider>)contextProvider from:(id<OTKTransitionFromContextProvider>)fromContextProvider {
    [self setHomeIndicatorHidden:YES];
}

- (void)transitionToContextProviderTransitionDidExit:(id<OTKTransitionToContextProvider>)contextProvider from:(id<OTKTransitionFromContextProvider>)fromContextProvider {
    [self setHomeIndicatorHidden:NO];
}

- (void)moveTransitionContentToContainerView:(UIView *)containerView {
    UIView *transitionContentView = self.transitionContentView;
    if (transitionContentView == nil) {
        return;
    }

    [transitionContentView removeFromSuperview];
    transitionContentView.transform = CGAffineTransformIdentity;
    transitionContentView.frame = containerView.bounds;
    transitionContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [containerView addSubview:transitionContentView];
}

@end
