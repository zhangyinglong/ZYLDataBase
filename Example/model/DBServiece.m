//
//  DBServiece.m
//  Example
//
//  Created by zhang yinglong on 2017/6/7.
//  Copyright © 2017年 zhang yinglong. All rights reserved.
//

#import "DBServiece.h"
#import "User.h"

@implementation DBServiece

static DBServiece *_shared_ = nil;

+ (DBServiece *)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared_ = [[DBServiece alloc] init];
    });
    return _shared_;
}

- (void)runMigrations {
    @try {
        [self beginTransaction];
        
        // Turn on Foreign Key support
        [self executeSql:@"PRAGMA foreign_keys = ON"];
        
        NSArray *tableNames = [self tableNames];
        if (![tableNames containsObject:@"ApplicationProperties"]) {
            [self createApplicationPropertiesTable];
        }
        
        if ([self databaseVersion] < 2) {
            // 升级 User 数据
            [User updateAll];
            
            // 升级 数据库版本
            [self setDatabaseVersion:2];
        }
        
        [self commit];
    }
    @catch (NSException *exception) {
        // 升级失败回滚事务
        [self rollback];
    }
}

@end
