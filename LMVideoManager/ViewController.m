//
//  ViewController.m
//  LMVideoManager
//
//  Created by 张利民 on 2017/8/9.
//  Copyright © 2017年 张利民. All rights reserved.
//

#import "ViewController.h"
#import "LMVideoViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:@"视频" forState:UIControlStateNormal];
    btn.frame = CGRectMake(100, 100, 100, 44);
    [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
    btn.layer.cornerRadius = 10;
    btn.layer.borderWidth = 1;
    btn.layer.borderColor = [UIColor lightGrayColor].CGColor;
    btn.clipsToBounds = YES;
    [self.view addSubview:btn];
    
}

-(void)btnAction:(UIButton *)btn {
    
    LMVideoViewController *vc = [[LMVideoViewController alloc] init];
    [self.navigationController pushViewController:vc animated:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
