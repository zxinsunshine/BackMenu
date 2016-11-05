//
//  ViewController.m
//  xiaozhuTest
//
//  Created by 周潇 on 2016/11/3.
//  Copyright © 2016年 zx. All rights reserved.
//

#import "ViewController.h"
#import <Masonry/Masonry.h>



// 方向枚举
typedef enum : NSUInteger {
    PanDirectionUp,
    PanDirectionDown
} PanDirection;


@interface ViewController ()<UITableViewDataSource,UITableViewDelegate,UIGestureRecognizerDelegate>


@property(nonatomic,weak)UITableView * table;
@property(nonatomic,weak)UIImageView * imgV;
@property(nonatomic,weak)UIPanGestureRecognizer * pan;
@property(nonatomic,assign)BOOL panDisenabled; // 手势失效标识，默认NO，不失效

@end

@implementation ViewController

static const CGFloat backHei = 200;



/*
 核心代码
 
 主要技术点：
 1. 手势冲突问题
 * 问题描述：
 * 所有的scrollView都滑动时都有一个panGesture手势，负责滚动，如果手动添加另外的手势，会有手势冲突问题，所以需要通过UIGestureRecognizerDelegate中的方法解决手势冲突问题
 * 解决方法：
 * 先用requireGestureRecognizerToFail:方法设置手势依赖，将自定义的手势优先级作为最高，然后设定一个全局标识，通过标识在gestureRecognizerShouldBegin:中判断是否开始手势，如果return NO，会向自定义手势发送一个UIGestureRecognizerStateFailed:信号，此时会执行scrollView自带的手势
 
 2. 临界点切换问题
 * 问题描述：
 * 手势冲突解决方法中，已经通过全局标识可以控制手势的执行先后问题，但是何时改变标识？
 * 当scrollView滑动到顶部时改变标识，滑动到顶部有两中情况：一是手动滑动到顶部，二是减速滑动到顶部，所以分别通过scrollViewDidScroll:,scrollViewDidEndDecelerating:监听是否到达顶部，一旦到达切换标识状态
 
 
 3. scrollView整体滑动问题
 * 问题描述：
 * scrollView整体会根据手势滑动，如果直接根据手势位置动态改动scrollView的位置，界面渲染量太多，会影响性能
 * 解决方法：
 * 手势开始滑动时，先将滑动的视图截图，然后隐藏原视图，滑动时平移截图，知道滑动终止时，删除截图，同时将原视图放置在终止的位置并显示
 
 4. 动态调整
 * 问题描述：
 * 自定义手势滑动出现背后的视图时，可能滑动动作没有让后面视图完全展示，此时需要根据滑动的终点位置判断用户行为，是需要完全展示呢，还是需要隐藏呢？
 * 解决方法：
 * 先设定一个邻域范围，手势滑动停止后，结合滑动方向以及滑动结束后的位置动画调整到最终位置
 
 5. 位置判断
 * 问题描述：
 * 拖动手势没有位置属性，需要自己手动判断
 * 解决方法：
 * 设定一个静态变量，记录上一次位置的值，当手势开始或者改变时通过当前位置和上次位置的相对位置判断方向
 
 
 */



#pragma mark - init set
- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGSize size = self.view.bounds.size;
    
    
    // 背后的视图设置
    UIImage * img = [UIImage imageNamed:@"1"];
    UIImageView * imgV = [[UIImageView alloc] initWithImage:img];
    [self.view addSubview:imgV];
    imgV.frame = CGRectMake(0, 0, size.width, backHei);
    
    
   
    // 前面的滚动视图设置
    UITableView * table = [[UITableView alloc] init];
    
    [self.view addSubview:table];
    table.bounces = NO;
    table.frame = CGRectMake(0, 0, size.width, size.height);
    table.delegate = self;
    table.dataSource = self;
    [table registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    self.table = table;
    
    
    // 给前面的滚动视图加手势
    UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [table addGestureRecognizer:pan];
    pan.delegate = self;
    self.pan = pan;
    // 设置手势依赖，当pan手势失效时才能执行table的pan（滑动）手势
    [table.panGestureRecognizer requireGestureRecognizerToFail:pan];
    

    
}


#pragma mark - gesture cope
// 拖拽手势处理
- (void)pan:(UIPanGestureRecognizer *)ges{
    // 记录前一次的手势位置
    static CGFloat preY = 0;
    static PanDirection direction;
    CGPoint pos = [ges locationInView:self.table];
    
    
    switch (ges.state) {
        case UIGestureRecognizerStateBegan:{
            // 开始记录手势位置
            preY = pos.y;
            
            // 截图，覆盖原视图，同时隐藏原视图
            UIImageView * imgV = [self getSnapshot:self.table];
            self.table.hidden = YES;
            [self.view addSubview:imgV];
            self.imgV = imgV;
            
            break;
        }
        case UIGestureRecognizerStateChanged:{
            
            // 根据滑动位置判断当前滑动方向
            direction = pos.y - preY > 0 ? PanDirectionDown : PanDirectionUp;
            
            // 计算截图的相对偏移量
            CGRect frame = self.imgV.frame;
            CGFloat offsetY = pos.y - preY + frame.origin.y;
            
            // 偏移不能超过一定范围
            if (offsetY > backHei) {
                offsetY = backHei;
                self.panDisenabled = NO;
            }
            if (offsetY < 0) {
                offsetY = 0;
                // 此时后面视图完全被table隐藏，table处于最前面，此时关闭pan手势
                self.panDisenabled = YES;
            }
            
            frame.origin.y = offsetY;
            
            // 跟随手势更新截图位置
            self.imgV.frame = frame;
            
            // 更新位置记录
            preY = pos.y;
            
            
            break;
        }
        case UIGestureRecognizerStateEnded:{
            
            // 拖拽完成，将frame更新到当前手势位置，同时消除截图
            self.table.frame = self.imgV.frame;
            [self.imgV removeFromSuperview];
            self.table.hidden = NO;
            
            // 根据终点位置调整一下最终位置
            [self adjustView:self.table forDirection:direction];
            
            
            break;
        }
        case UIGestureRecognizerStateFailed:
            NSLog(@"fail");
            
            break;
        default:
            break;
    }
}

// table手动滑动顶端时，开启手势
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    CGFloat offsetY = scrollView.contentOffset.y;
    
    if (offsetY == 0) {
        
        self.panDisenabled = NO;
        
    }
}

// 减速到顶端时，开启手势
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    CGFloat offsetY = scrollView.contentOffset.y;
    
    if (offsetY == 0) {
        
        self.panDisenabled = NO;
        
    }
}


// 根据手势失效标识决定是否让pan手势失效
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    
    
    if ([gestureRecognizer isEqual:self.pan]) {
        return !self.panDisenabled;
    }
    
    return YES;
}


// 调整位置
- (void)adjustView:(UIView *)view forDirection:(PanDirection)direction{
    
    CGFloat period = 50; // 调整范围
    CGFloat durTime = 0.25; // 动画时间
    CGFloat damp = 0.7; // 阻尼系数
    CGFloat velocity = 10; // 速度
    
    switch (direction) {
        case PanDirectionDown:{
            
            if (view.frame.origin.y < period) {
                [UIView animateWithDuration:durTime delay:0 usingSpringWithDamping:damp initialSpringVelocity:velocity options:UIViewAnimationOptionCurveLinear animations:^{
                   
                    CGRect frame = view.frame;
                    frame.origin.y = 0;
                    view.frame = frame;
                    
                } completion:^(BOOL finished) {
                    
                }];
            }
            else{
                [UIView animateWithDuration:durTime delay:0 usingSpringWithDamping:damp initialSpringVelocity:velocity options:UIViewAnimationOptionCurveLinear animations:^{
                    
                    CGRect frame = view.frame;
                    frame.origin.y = backHei;
                    view.frame = frame;
                    
                } completion:^(BOOL finished) {
                    
                }];
            }
            
            break;
        }
        case PanDirectionUp:{
            
            if (backHei - view.frame.origin.y < period) {
                [UIView animateWithDuration:durTime delay:0 usingSpringWithDamping:damp initialSpringVelocity:velocity options:UIViewAnimationOptionCurveLinear animations:^{
                    
                    CGRect frame = view.frame;
                    frame.origin.y = backHei;
                    view.frame = frame;
                    
                } completion:^(BOOL finished) {
                    
                }];
            }
            else{
                [UIView animateWithDuration:durTime delay:0 usingSpringWithDamping:damp initialSpringVelocity:velocity options:UIViewAnimationOptionCurveLinear animations:^{
                    
                    CGRect frame = view.frame;
                    frame.origin.y = 0;
                    view.frame = frame;
                    
                } completion:^(BOOL finished) {
                    
                }];
            }
            
        }
        default:
            break;
    }
    
}

// 获取截图
- (UIImageView *)getSnapshot:(UIView *)view{
    // 绘图
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageView * imgV = [[UIImageView alloc] initWithImage:image];
    imgV.frame = view.frame;
    
    return imgV;
}




#pragma mark - tableView delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"select");
}

#pragma mark - tableView datasoruce
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 200;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    cell.textLabel.text = @"sf";
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

@end
