//
//  Database.h
//  DistributTools
//
//  Created by zhangyinglong on 16/1/16.
//  Copyright © 2016年 ChinaHR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

typedef NS_ENUM(NSInteger, TransactionKind) {
    TransactionKindDeferred,
    TransactionKindImmediate,
    TransactionKindExclusive
};

typedef NS_ENUM(NSInteger, TransactionCompletion) {
    TransactionCompletionCommit,
    TransactionCompletionRollback
};

@interface Database : NSObject {
    sqlite3 *database;
}

@property (nonatomic, copy) NSString *pathToDatabase;
@property (nonatomic, assign) BOOL logging;
@property (nonatomic, strong) dispatch_queue_t databaseQueue;

- (instancetype)initWithPath:(NSString *)filePath;
- (instancetype)initWithFileName:(NSString *)fileName;
- (NSArray *)executeSql:(NSString *)sql withParameters:(NSArray *)parameters;
- (NSArray *)executeSql:(NSString *)sql withParameters:(NSArray *)parameters withClassForRow:(Class)rowClass;
- (NSArray *)executeSql:(NSString *)sql;
- (NSArray *)executeSqlWithParameters:(NSString *)sql, ...;
- (NSArray *)tableNames;
- (void)beginTransaction;
- (void)commit;
- (void)rollback;
- (NSArray *)columnsForTableName:(NSString *)tableName;
- (NSUInteger)lastInsertRowId;

@end
