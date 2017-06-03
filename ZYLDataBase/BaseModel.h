//
//  BaseModel.h
//  DistributTools
//
//  Created by zhangyinglong on 16/1/16.
//  Copyright © 2016年 ChinaHR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"

@interface BaseModel : NSObject {
    NSUInteger primaryKey;
    BOOL savedInDatabase;
}

@property (nonatomic) NSUInteger primaryKey;
@property (nonatomic) BOOL savedInDatabase;

+ (void)setDatabase:(Database *)newDatabase;
+ (Database *)database;

- (void)resetAll;
- (BaseModel*)table:(NSString *)table;
- (BaseModel*)field:(id)field;
- (BaseModel*)limit:(NSUInteger)start size:(NSUInteger)size;
- (BaseModel*)order:(NSString *)order;
- (BaseModel*)group:(NSString *)group;
- (BaseModel*)whereRaw:(NSString *)str value:(NSDictionary *)map;
- (BaseModel*)setwhere:(NSDictionary *)map;
- (NSArray *)select;
- (NSUInteger)getCount;

- (void)update:(NSDictionary *)data;
- (void)beforeUpdate:(NSDictionary *)data;
- (void)afterUpdate:(NSDictionary *)data;

- (void)save;
- (void)beforeSave;
- (void)afterSave;

- (void)deleteSelf;
- (void)beforeDeleteSelf;
- (void)afterDeleteSelf;

- (void)delete;
- (void)beforeDelete;
- (void)afterDelete;

+ (void)afterFind:(NSArray **)results;
+ (void)beforeFindSql:(NSString **)sql parameters:(NSArray **)parameters;
+ (NSArray *)findWithSql:(NSString *)sql withParameters:(NSArray *)parameters;
+ (NSArray *)findWithSqlWithParameters:(NSString *)sql, ...;
+ (NSArray *)findWithSql:(NSString *)sql;
+ (NSArray *)findByColumn:(NSString *)column value:(id)value;
+ (NSArray *)findByColumn:(NSString *)column unsignedIntegerValue:(NSUInteger)value;
+ (NSArray *)findByColumn:(NSString *)column integerValue:(NSInteger)value;
+ (NSArray *)findByColumn:(NSString *)column doubleValue:(double)value;
+ (id)find:(NSUInteger)primaryKey;
+ (NSArray *)findAll;
+ (void)deleteAll;
- (BOOL)isTableExist;
- (void)createTable;

@end
