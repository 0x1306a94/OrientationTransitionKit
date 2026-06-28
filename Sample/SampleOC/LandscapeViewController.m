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

- (void)closeButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)userInfoButtonTapped {
    if (self.didTapUserInfoHandler != nil) {
        self.didTapUserInfoHandler(self);
    }
}

- (UIViewController *)transitionToContextProviderViewController {
    return self;
}

- (CGRect)transitionToContextProviderTransitionFrameIn:(UIView *)containerView {
    return [containerView convertRect:self.playerContainerView.bounds fromView:self.playerContainerView];
}

- (void)transitionToContextProviderPrepareTransitionView:(UIView *)transitionView {
    [self moveTransitionContentToContainerView:transitionView];
}

- (void)transitionToContextProviderFinishTransitionView {
    [self moveTransitionContentToContainerView:self.playerContainerView];
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
