//
//  DatabaseServiece.m
//  DistributTools
//
//  Created by zhangyinglong on 16/1/16.
//  Copyright © 2016年 ChinaHR. All rights reserved.
//

#import "DatabaseServiece.h"
#import "BaseModel.h"

#define kEnableDataBaseLog  NO
//#define kEnableDataBaseLog  YES

@interface DatabaseServiece ()

// Migration steps - v1
-(void)createApplicationPropertiesTable;

@end

@implementation DatabaseServiece

static DatabaseServiece *sharedDatabaseServiece = nil;

+ (DatabaseServiece *)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDatabaseServiece = [[DatabaseServiece alloc] init];
    });
    return sharedDatabaseServiece;
}

- (instancetype)init {
    return [self initWithMigrations];
}

- (instancetype)initWithMigrations {
    self = [self initWithMigrations:kEnableDataBaseLog];
    if (!self) { return nil; }

    return self;
}

- (instancetype)initWithMigrations:(BOOL)loggingEnabled {
    self = [super initWithFileName:[NSString stringWithFormat:@"%@Database.sqlite3", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]]];
    if (!self) { return nil; }

    [self setLogging:loggingEnabled];
    [self runMigrations];
    [BaseModel setDatabase:self];

    return self;
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

//        if ([self databaseVersion] < 2) {
//            // Migrations for database version 1 will run here
//            [self setDatabaseVersion:2];
//        }

        /*
         * To upgrade to version 3 of the DB do

         if ([self databaseVersion] < 3) {
         // ...
         [self setDatabaseVersion:3];
         }
         
         *
         */
        
        [self commit];
    }
    @catch (NSException *exception) {
        NSLog(@"exception = %@", exception);
        [self rollback];
    }
}

#pragma mark - Migration Steps

- (void)createApplicationPropertiesTable {
    [self executeSql:@"create table ApplicationProperties (primaryKey integer primary key autoincrement, name text, value integer)"];
    [self executeSql:@"insert into ApplicationProperties (name, value) values('databaseVersion', 1)"];
}

#pragma mark - Convenience Methods

- (void)updateApplicationProperty:(NSString *)propertyName value:(id)value {
    [self executeSqlWithParameters:@"UPDATE ApplicationProperties SET value = ? WHERE name = ?", value, propertyName, nil];
}

- (id)getApplicationProperty:(NSString *)propertyName {
    NSArray *rows = [self executeSqlWithParameters:@"SELECT value FROM ApplicationProperties WHERE name = ?", propertyName, nil];

    if ([rows count] == 0) {
        return nil;
    }

    id object = [[rows lastObject] objectForKey:@"value"];
    if ([object isKindOfClass:[NSString class]]) {
        object = [NSNumber numberWithInteger:[(NSString *)object integerValue]];
    }
    return object;
}

- (void)setDatabaseVersion:(NSUInteger)newVersionNumber {
    return [self updateApplicationProperty:@"databaseVersion" value:[NSNumber numberWithUnsignedInteger:newVersionNumber]];
}

- (NSUInteger)databaseVersion {
    return [[self getApplicationProperty:@"databaseVersion"] unsignedIntegerValue];
}

@end
