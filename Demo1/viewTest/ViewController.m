//
//  ViewController.m
//  viewTest
//
//  Created by 周潇 on 2016/11/5.
//  Copyright © 2016年 zx. All rights reserved.
//

#import "ViewController.h"

#define screenSize [UIScreen mainScreen].bounds.size

#define backHei 200

@interface ViewController ()<UIScrollViewDelegate>


@property(nonatomic,weak)UIScrollView * backS;
@property(nonatomic,weak)UIScrollView * frontS;

@end

@implementation ViewController



#pragma mark - 核心代码
/*
 * 思路：
 * 1. 两个scrollView嵌套
 * 2. 当前面的scrollView滑到顶部，无法再滑动，不会监听滑动，而是传递到后面的ScrollView上
 * 3. 将后面显示的内容放到后面scrollView的contentInset区域
 * 4. 当后面scrollView监听到didScroll事件时，根据偏移量判断：如果后面的内容出现了，禁用前面scrollView的scrollEnabeld，保证后面显示内容出现时，再滑动前面scrollView时还是运行后面scrollView的事件，能滑动回去，而不是滑动前面scrollView的内容；当后面的内容完全被前面的scrollView覆盖时，启用前面的scrollView的可滑动
 */
- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIScrollView * backS = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    backS.contentSize = CGSizeMake(screenSize.width, screenSize.height);
    [self.view addSubview:backS];
    backS.backgroundColor = [UIColor redColor];

    backS.bounces = NO;
    backS.delegate = self;
    self.backS = backS;
    
    backS.showsVerticalScrollIndicator = NO;
    backS.contentInset = UIEdgeInsetsMake(backHei, 0, 0, 0);
    
 
    
    
    UIScrollView * frontS = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];
    frontS.contentSize = CGSizeMake(screenSize.width, 5000);
    [backS addSubview:frontS];
    frontS.backgroundColor = [UIColor yellowColor];
    frontS.bounces = NO; 
    frontS.delegate = self;
    
    self.frontS = frontS;
    
    
    UIView * v = [[UIView alloc] initWithFrame:CGRectMake(0, -backHei, screenSize.width, backHei)];
    v.backgroundColor = [UIColor blueColor];
    [backS addSubview:v];
    UILabel * lbl = [[UILabel alloc] initWithFrame:v.bounds];
    lbl.text = @"显示";
    lbl.textAlignment = NSTextAlignmentCenter;
    [v addSubview:lbl];
    
    
    
   
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if ([scrollView isEqual:self.backS]) {
        if (scrollView.contentOffset.y < 0) {
            
            self.frontS.scrollEnabled = NO;
        }
        else{
            self.frontS.scrollEnabled = YES;
        }
        
    }
}




@end
