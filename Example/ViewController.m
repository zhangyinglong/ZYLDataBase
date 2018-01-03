//
//  ViewController.m
//  Example
//
//  Created by zhang yinglong on 2017/6/1.
//  Copyright © 2017年 zhang yinglong. All rights reserved.
//

#import "ViewController.h"
#import <ZYLDataBase/ZYLDataBase.h>
#import "DBServiece.h"
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
    
    // 必须在初始化数据库之前设置是否支持加密，默认开启
    [DBServiece secureEntry:YES];
    
    // 初始化数据库，并自动检测升级
    DBServiece *service = [DBServiece shared];
    
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
    // sql语句直接搜索
//    NSArray *total = [User findWithSql:@"select * from User where uid='123'"];
//    NSArray *total = [User findWithSql:@"select * from User where uid=?" withParameters:@[@(123)]];
//    NSArray *total = [User findWithSqlWithParameters:@"select * from User where uid=?", @"123", nil];
    
    // 查找所有记录
//    NSArray *total = [User findAll];
    
//    // 清空所有表数据
//    [User deleteAll];
    
    // 条件搜索
//    NSArray *total = [User findByColumn:@"uid" value:@(100)];
    
    // 条件搜索
//    User *user = [[User alloc] init];
//    [user resetAll];                                        // 重置查询条件
//    user = [user field:@"uid,name"];                        // 设置搜索域
//    user = [user whereRaw:@"uid" value:@{@"uid":@(100)}];   // 设置where条件
//    user = [user limit:0 size:10];                           // 设置返回记录范围(0-10条记录)
//    user = [user order:@"uid"];                             // 设置排序条件
//    user = [user group:@"gender"];                          // 设置分组条件
//    NSArray *total = [user select];
    
//    [user update:@{ @"gender":@(2) }];

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
