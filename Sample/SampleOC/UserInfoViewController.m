//
//  UserInfoViewController.m
//  Sample
//
//  Created by KK on 2026/6/28.
//

#import "UserInfoViewController.h"

@implementation UserInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.greenColor;

    UILabel *testLabel = [UILabel new];
    testLabel.font = [UIFont systemFontOfSize:30 weight:UIFontWeightMedium];
    testLabel.text = @"Test";
    testLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:testLabel];
    [testLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [testLabel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = YES;
}

@end
