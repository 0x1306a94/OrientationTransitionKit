//
//  HomeViewController.m
//  SampleOC
//
//  Created by KK on 2026/6/28.
//

#import "HomeViewController.h"

#import "LandscapeViewController.h"
#import "UserInfoViewController.h"

@import OrientationTransitionKit;

@interface HomeViewController () <OTKTransitionFromContextProvider>
@property (nonatomic, strong) UIView *playerContainerView;
@property (nonatomic, strong) UIImageView *playerView;
@property (nonatomic, strong) UIStackView *buttonStackView;
@property (nonatomic, strong) UIButton *landscapeButton;
@property (nonatomic, strong) UIButton *positionButton;
@property (nonatomic, strong) NSLayoutConstraint *playerContainerViewTopLayoutConstraint;
@property (nonatomic, strong) NSLayoutConstraint *playerContainerViewCenterLayoutConstraint;
@property (nonatomic, strong) OTKTransitionCoordinator *orientationTransitionCoordinator;
@property (nonatomic, strong) LandscapeViewController *landscapeViewController;
@property (nonatomic, copy) void (^pendingExitFullscreenTask)(void);
@property (nonatomic, assign) BOOL shouldHideHomeIndicator;
@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _playerContainerView = [UIView new];
    _playerContainerView.backgroundColor = UIColor.blackColor;
    _playerContainerView.translatesAutoresizingMaskIntoConstraints = NO;

    _playerView = [UIImageView new];
    _playerView.backgroundColor = UIColor.orangeColor;
    _playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    _buttonStackView = [UIStackView new];
    _buttonStackView.translatesAutoresizingMaskIntoConstraints = NO;
    _buttonStackView.axis = UILayoutConstraintAxisHorizontal;
    _buttonStackView.spacing = 20;

    UIButtonConfiguration *positionButtonConfiguration = [UIButtonConfiguration filledButtonConfiguration];
    positionButtonConfiguration.contentInsets = NSDirectionalEdgeInsetsMake(5, 10, 5, 10);
    positionButtonConfiguration.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    positionButtonConfiguration.attributedTitle = [[NSAttributedString alloc] initWithString:@"顶部" attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:18 weight:UIFontWeightMedium]}];
    _positionButton = [UIButton buttonWithConfiguration:positionButtonConfiguration primaryAction:nil];
    [_positionButton addTarget:self action:@selector(positionButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

    UIButtonConfiguration *landscapeButtonConfiguration = [UIButtonConfiguration filledButtonConfiguration];
    landscapeButtonConfiguration.contentInsets = NSDirectionalEdgeInsetsMake(5, 10, 5, 10);
    landscapeButtonConfiguration.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    landscapeButtonConfiguration.attributedTitle = [[NSAttributedString alloc] initWithString:@"全屏" attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:18 weight:UIFontWeightMedium]}];
    _landscapeButton = [UIButton buttonWithConfiguration:landscapeButtonConfiguration primaryAction:nil];
    _landscapeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_landscapeButton addTarget:self action:@selector(landscapeButtonTapped) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:_playerContainerView];
    [_playerContainerView addSubview:_playerView];
    [self.view addSubview:_buttonStackView];
    [_buttonStackView addArrangedSubview:_positionButton];
    [_buttonStackView addArrangedSubview:_landscapeButton];

    _playerContainerViewTopLayoutConstraint = [_playerContainerView.topAnchor constraintEqualToAnchor:self.view.topAnchor];
    _playerContainerViewCenterLayoutConstraint = [_playerContainerView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-50];
    [NSLayoutConstraint activateConstraints:@[
        [_playerContainerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_playerContainerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        _playerContainerViewCenterLayoutConstraint,
        [_playerContainerView.heightAnchor constraintEqualToAnchor:_playerContainerView.widthAnchor multiplier:3.0 / 4.0],

        [_buttonStackView.topAnchor constraintEqualToAnchor:_playerContainerView.bottomAnchor constant:30],
        [_buttonStackView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    ]];

    UILabel *testLabel = [UILabel new];
    testLabel.font = [UIFont systemFontOfSize:30 weight:UIFontWeightMedium];
    testLabel.text = @"Test";
    testLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_playerView addSubview:testLabel];
    [testLabel.centerXAnchor constraintEqualToAnchor:_playerView.centerXAnchor].active = YES;
    [testLabel.centerYAnchor constraintEqualToAnchor:_playerView.centerYAnchor].active = YES;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    if (self.playerView.superview == self.playerContainerView) {
        self.playerView.frame = self.playerContainerView.bounds;
    }
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return self.shouldHideHomeIndicator;
}

- (void)positionButtonTapped:(UIButton *)sender {
    sender.selected = !sender.selected;

    UIButtonConfiguration *configuration = [UIButtonConfiguration filledButtonConfiguration];
    configuration.contentInsets = NSDirectionalEdgeInsetsMake(5, 10, 5, 10);
    configuration.cornerStyle = UIButtonConfigurationCornerStyleCapsule;

    self.playerContainerViewCenterLayoutConstraint.active = NO;
    self.playerContainerViewTopLayoutConstraint.active = NO;

    if (sender.selected) {
        configuration.attributedTitle = [[NSAttributedString alloc] initWithString:@"中心" attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:18 weight:UIFontWeightMedium]}];
        self.playerContainerViewTopLayoutConstraint.active = YES;
    } else {
        configuration.attributedTitle = [[NSAttributedString alloc] initWithString:@"顶部" attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:18 weight:UIFontWeightMedium]}];
        self.playerContainerViewCenterLayoutConstraint.active = YES;
    }
    sender.configuration = configuration;

    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)landscapeButtonTapped {
    if (self.landscapeViewController != nil) {
        return;
    }

    LandscapeViewController *landscapeViewController = [LandscapeViewController new];
    landscapeViewController.transitionContentView = self.playerView;

    __weak typeof(self) weakSelf = self;
    landscapeViewController.didTapUserInfoHandler = ^(LandscapeViewController *viewController) {
        weakSelf.pendingExitFullscreenTask = ^{
            [weakSelf showUserInfo];
        };
        [viewController dismissViewControllerAnimated:YES completion:nil];
    };

    OTKDefaultTransitionAnimationProvider *animationProvider = [[OTKDefaultTransitionAnimationProvider alloc] initWithDuration:0.25];
    OTKTransitionCoordinator *transitionCoordinator = [[OTKTransitionCoordinator alloc] initFromContextProvider:self toContextProvider:landscapeViewController fromInterfaceOrientation:UIInterfaceOrientationPortrait toInterfaceOrientation:UIInterfaceOrientationLandscapeRight animationProvider:animationProvider];

    self.landscapeViewController = landscapeViewController;
    self.orientationTransitionCoordinator = transitionCoordinator;

    landscapeViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    landscapeViewController.transitioningDelegate = transitionCoordinator;

    [self presentViewController:landscapeViewController animated:YES completion:nil];
}

- (void)showUserInfo {
    [self.navigationController pushViewController:[UserInfoViewController new] animated:YES];
}

- (void)setHomeIndicatorHidden:(BOOL)hidden {
    self.shouldHideHomeIndicator = hidden;
    [self setNeedsUpdateOfHomeIndicatorAutoHidden];
}

- (UIViewController *)transitionFromContextProviderViewController:(id<OTKTransitionFromContextProvider>)contextProvider {
    return self;
}

- (CGRect)transitionFromContextProviderTransitionFrame:(id<OTKTransitionFromContextProvider>)contextProvider in:(UIView *)containerView {
    return [containerView convertRect:self.playerContainerView.bounds fromView:self.playerContainerView];
}

- (void)transitionFromContextProviderPrepareTransitionView:(id<OTKTransitionFromContextProvider>)contextProvider transitionView:(UIView *)transitionView {
    [self movePlayerViewToContainerView:transitionView];
}

- (void)transitionFromContextProviderFinishTransitionView:(id<OTKTransitionFromContextProvider>)contextProvider {
    [self movePlayerViewToContainerView:self.playerContainerView];
}

- (void)transitionFromContextProviderTransitionWillEnter:(id<OTKTransitionFromContextProvider>)contextProvider to:(id<OTKTransitionToContextProvider>)toContextProvider {
    [self setHomeIndicatorHidden:YES];
}

- (void)transitionFromContextProviderTransitionDidEnter:(id<OTKTransitionFromContextProvider>)contextProvider to:(id<OTKTransitionToContextProvider>)toContextProvider {
    [self setHomeIndicatorHidden:NO];
}

- (void)transitionFromContextProviderTransitionWillExit:(id<OTKTransitionFromContextProvider>)contextProvider to:(id<OTKTransitionToContextProvider>)toContextProvider {
    [self setHomeIndicatorHidden:YES];
}

- (void)transitionFromContextProviderTransitionDidExit:(id<OTKTransitionFromContextProvider>)contextProvider to:(id<OTKTransitionToContextProvider>)toContextProvider {
    [self setHomeIndicatorHidden:NO];
    self.orientationTransitionCoordinator = nil;
    self.landscapeViewController = nil;

    if (self.pendingExitFullscreenTask != nil) {
        self.pendingExitFullscreenTask();
        self.pendingExitFullscreenTask = nil;
    }
}

- (void)movePlayerViewToContainerView:(UIView *)containerView {
    [self.playerView removeFromSuperview];
    self.playerView.transform = CGAffineTransformIdentity;
    self.playerView.frame = containerView.bounds;
    self.playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [containerView addSubview:self.playerView];
}

@end
