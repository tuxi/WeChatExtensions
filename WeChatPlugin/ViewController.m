//
//  ViewController.m
//  WeChatPlugin
//
//  Created by Swae on 2017/10/7.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIAlertController *alc = [UIAlertController alertControllerWithTitle:@"hello world" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alc addAction:[UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleDefault handler:NULL]];
    [alc addAction:[UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:NULL]];
    [self presentViewController:alc animated:YES completion:NULL];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
