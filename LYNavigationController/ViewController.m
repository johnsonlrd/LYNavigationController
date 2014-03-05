//
//  ViewController.m
//  LYNavigationController
//
//  Created by Liu Yue on 3/5/14.
//  Copyright (c) 2014 devliu.com. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

- (IBAction)popToRoot:(UIBarButtonItem *)sender;
- (IBAction)popToFirst:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UILabel *numLabel;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    int index = [self.navigationController.viewControllers indexOfObject:self];
    self.numLabel.text = [@(index) stringValue];
    CGFloat h = arc4random() % 256 / 256.f;
    CGFloat s = arc4random() % 128 / 256.f + 0.5;
    CGFloat v = arc4random() % 128 / 256.f + 0.5f;
    
    self.view.backgroundColor = [UIColor colorWithHue:h saturation:s brightness:v alpha:1];
    
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)popToRoot:(UIBarButtonItem *)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)popToFirst:(UIButton *)sender {
    if (self.navigationController.viewControllers.count > 2) {
        UIViewController *vc = [self.navigationController.viewControllers objectAtIndex:1];
        [self.navigationController popToViewController:vc animated:YES];
    }
}
@end
