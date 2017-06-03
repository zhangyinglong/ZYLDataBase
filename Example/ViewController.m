//
//  ViewController.m
//  Example
//
//  Created by zhang yinglong on 2017/6/1.
//  Copyright © 2017年 zhang yinglong. All rights reserved.
//

#import "ViewController.h"
#import <ZYLDataBase/ZYLDataBase.h>
#import "User.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *uidField;
    
@property (weak, nonatomic) IBOutlet UITextField *nameField;
    
@property (weak, nonatomic) IBOutlet UITextView *output;
    
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // 初始化数据库，并自动检测升级
    DatabaseServiece *service = [DatabaseServiece shared];
    
    // 检测数据库是否有升级，可手动升级
    [service runMigrations];
    
    _output.textAlignment = NSTextAlignmentCenter;
    
    NSArray *total = [User findAll];
    User *user = total.firstObject;
    if ( user ) {
        _uidField.text = [NSString stringWithFormat:@"%@", @(user.uid)];
        _nameField.text = user.name;
    }
    [self show:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// add a record
- (IBAction)add:(id)sender {
    if ( ![_uidField.text isEqualToString:@""] && ![_nameField.text isEqualToString:@""] ) {
        User *user = [[User alloc] init];
        user.uid = [_uidField.text integerValue];
        user.name = _nameField.text;
        [user save];
        
        // 显示结果
        [self show:nil];
    }
}
    
// delete a record
- (IBAction)remove:(id)sender {
    if ( ![_uidField.text isEqualToString:@""] && ![_nameField.text isEqualToString:@""] ) {
        uint64_t uid = [_uidField.text integerValue];
        User *user = (User *)[[[User alloc] init] setwhere:@{@"uid":@(uid)}];
        NSArray *result = [user select];
        for (User *u in result) {
            [u deleteSelf];
        }
        
        // 显示结果
        [self show:nil];
    }
}
    
- (IBAction)show:(id)sender {
    NSArray *total = [User findAll];
    NSMutableString *text = [[NSMutableString alloc] initWithCapacity:total.count];
    for (User *user in total) {
        [text appendFormat:@"%@\n", user];
    }
    if ( text.length > 0 ) {
        _output.text = text;
    } else {
        _output.text = @"数据库中没有记录";
    }
}

@end
