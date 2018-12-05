//
//  ViewController.m
//  KTMetalTextTest
//
//  Created by tu jinqiu on 2018/12/4.
//  Copyright © 2018年 tu jinqiu. All rights reserved.
//

#import "ViewController.h"
#import "MetalRender.h"

@interface ViewController ()

@property(nonatomic, strong) MetalRender *render;
@property(nonatomic, strong) MTKView *mtkView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    self.mtkView = [[MTKView alloc] initWithFrame:[UIScreen mainScreen].bounds device:device];
    [self.view addSubview:self.mtkView];
    
    self.render = [[MetalRender alloc] initWithMTKView:self.mtkView];
    [self.render mtkView:self.mtkView drawableSizeWillChange:self.mtkView.drawableSize];
}


@end
