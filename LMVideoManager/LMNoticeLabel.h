//
//  LMNoticeLabel.h
//  LMLogin
//
//  Created by 60az on 16/11/17.
//  Copyright © 2016年 60az. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LMNoticeLabel : UIView
/** 
 *  功能：提示框
 *  用法： [self.view addSubView:[LMNoticeLabel message:@"我是测试文字" delaySecond:2.0]];
 *  param
 *  message: 要显示的文字信息
 *  second:  显示文字的时间
 */
+(instancetype)message:(NSString *)message delaySecond:(CGFloat)second;
@end
