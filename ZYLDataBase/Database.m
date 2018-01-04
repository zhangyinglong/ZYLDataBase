//
//  Database.m
//  DistributTools
//
//  Created by zhangyinglong on 16/1/16.
//  Copyright © 2016年 zhangyinglong. All rights reserved.
//

#import "Database.h"
#import <sqlite3.h>

static BOOL _secureEntry_ = YES;

@interface Database () {
    sqlite3 *database;
}

- (void)open;
- (void)raiseSqliteException:(NSString *)errorMessage;
- (NSArray *)columnNamesForStatement:(sqlite3_stmt *)statement;
- (NSArray *)columnTypesForStatement:(sqlite3_stmt *)statement;
- (void)copyValuesFromStatement:(sqlite3_stmt *)statement toRow:(id)row queryInfo:(NSDictionary *)queryInfo columnTypes:(NSArray *)columnTypes columnNames:(NSArray *)columnNames;
- (int)columnTypeToInt:(NSString *)columnType;
- (int)typeForStatement:(sqlite3_stmt *)statement column:(int)column;
- (id)valueFromStatement:(sqlite3_stmt *)statement column:(int)column queryInfo:(NSDictionary *)queryInfo columnTypes:(NSArray *)columnTypes;
- (NSArray *)tables;
- (void)bindArguments:(NSArray *)arguments toStatement:(sqlite3_stmt *)statement queryInfo:(NSDictionary *)queryInfo;

@end

@implementation Database

+ (void)secureEntry:(BOOL)enable {
    _secureEntry_ = enable;
}

#pragma mark - Init Methods

- (instancetype)initWithPath:(NSString *)filePath {
    if (self = [super init]) {
        self.pathToDatabase = filePath;
        self.databaseQueue = dispatch_queue_create("com.database.engine", DISPATCH_QUEUE_CONCURRENT);
        [self open];
    }
    return self;
}

- (instancetype)initWithFileName:(NSString *)fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

    return [self initWithPath:[documentsDirectory stringByAppendingPathComponent:fileName]];
}

#pragma mark - SQLite Methods

- (NSArray *)executeSql:(NSString *)sql
         withParameters:(NSArray *)parameters
        withClassForRow:(Class )rowClass {
    NSMutableDictionary *queryInfo = [NSMutableDictionary dictionary];
    [queryInfo setObject:sql forKey:@"sql"];

    if (parameters == nil) {
        parameters = [NSArray array];
    }

    // Now add the parameters to queryInfo
    [queryInfo setObject:parameters forKey:@"parameters"];

    NSMutableArray *rows = [NSMutableArray array];

    __weak typeof(self) weakSelf = self;
    dispatch_sync(self.databaseQueue, ^{
        if (weakSelf.logging) {
            NSLog(@"SQL: %@ \n parameters: %@", sql, parameters);
        }

        sqlite3_stmt * statement = nil;
        @try {
            if (sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
                [weakSelf bindArguments:parameters toStatement:statement queryInfo:queryInfo];

                BOOL needsToFetchColumnTypesAndNames = YES;
                NSArray *columnTypes = nil;
                NSArray *columnNames = nil;

                while (sqlite3_step(statement) == SQLITE_ROW) {
                    if (needsToFetchColumnTypesAndNames) {
                        columnTypes = [weakSelf columnTypesForStatement:statement];
                        columnNames = [weakSelf columnNamesForStatement:statement];
                        needsToFetchColumnTypesAndNames = NO;
                    }

                    id row = [[rowClass alloc] init];
                    [weakSelf copyValuesFromStatement:statement toRow:row queryInfo:queryInfo columnTypes:columnTypes columnNames:columnNames];
                    [rows addObject:row];
                }
            } else {
                [weakSelf raiseSqliteException:[[NSString stringWithFormat:@"Failed to execute statement: '%@', parameters: '%@' with message: ", sql, parameters] stringByAppendingString:@"%S"]];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"exception = %@", exception);
        }
        @finally {
            sqlite3_finalize(statement);
        }
    });
    
    return rows;
}

- (NSArray *)executeSql:(NSString *)sql
         withParameters:(NSArray *)parameters {
    return [self executeSql:sql withParameters:parameters withClassForRow:[NSMutableDictionary class]];
}

- (NSArray *)executeSql:(NSString *)sql {
    return [self executeSql:sql withParameters:nil];
}

- (NSArray *)executeSqlWithParameters:(NSString *)sql, ... {
    va_list argumentList;
    va_start(argumentList, sql);
    NSMutableArray *arguments = [NSMutableArray array];
    id argument;

    while ((argument = va_arg(argumentList, id))) {
        [arguments addObject:argument];
    }

    va_end(argumentList);
    return [self executeSql:sql withParameters:arguments];
}

- (void)close {
    __weak typeof(self) weakSelf = self;
    dispatch_sync(self.databaseQueue, ^{
        if (sqlite3_close(database) != SQLITE_OK) {
            [weakSelf raiseSqliteException:@"Failed to close database with message '%S'."];
        }
    });
}

- (NSArray *)tableNames {
    return [[self tables] valueForKey:@"name"];
}

- (void)beginTransaction {
    [self executeSql:@"BEGIN IMMEDIATE TRANSACTION;"];
}

- (void)commit {
    [self executeSql:@"COMMIT TRANSACTION;"];
}

- (void)rollback {
    [self executeSql:@"ROLLBACK TRANSACTION;"];
}

- (NSArray *)columnsForTableName:(NSString *)tableName {
    NSArray *results = [self executeSql:[NSString stringWithFormat:@"pragma table_info(%@)", tableName]];
    return [results valueForKey:@"name"];
}

- (NSUInteger)lastInsertRowId {
    return (NSUInteger)sqlite3_last_insert_rowid(database);
}

#pragma mark - Private Methods

-(void)open {
    NSLog(@"sqlite3 lib version: %s", sqlite3_libversion());
    
    dispatch_sync(self.databaseQueue, ^{
        if ( _secureEntry_ ) {
            if (sqlite3_threadsafe() > 0) {
                int retCode = sqlite3_config(SQLITE_CONFIG_SERIALIZED);
                if (retCode == SQLITE_OK) {
                    NSLog(@"Can now use sqlite on multiple threads, using the same connection");
                } else {
                    NSLog(@"setting sqlite thread safe mode to serialized failed!!! return code: %d", retCode);
                }
            } else {
                NSLog(@"Your SQLite database is not compiled to be threadsafe.");
            }
            
            // opens database, creating the file if it does not already exist
            if (sqlite3_open([self.pathToDatabase UTF8String], &database) == SQLITE_OK) {
                const char* key = [@"WWW.04401.COM.CN" UTF8String];
                sqlite3_key(database, key, (int)strlen(key));
                if (sqlite3_exec(database, (const char*) "SELECT count(*) FROM sqlite_master;", NULL, NULL, NULL) == SQLITE_OK) {
                    NSLog(@"password is correct, or, database has been initialized!");
                } else {
                    NSLog(@"incorrect password!");
                    sqlite3_close(database);
                }
            } else {
                NSLog(@"Failed to open database");
                sqlite3_close(database);
            }
        } else {
            // config sqlite to work with the same connection on multiple threads
            if (sqlite3_config(SQLITE_CONFIG_SERIALIZED) == SQLITE_OK) {
                NSLog(@"Can now use sqlite on multiple threads, using the same connection");
            } else {
                NSLog(@"UNABLE to use sqlite on multiple threads, using the same connection");
            }
            
            // opens database, creating the file if it does not already exist
            if (sqlite3_open([self.pathToDatabase UTF8String], &database) != SQLITE_OK) {
                sqlite3_close(database);
                [self raiseSqliteException:@"Failed to open database with message '%S'."];
            }
        }
    });
}

- (void)raiseSqliteException:(NSString *)errorMessage {
    [NSException raise:@"DatabaseSQLiteException" format:errorMessage, sqlite3_errmsg16(database)];
}

- (NSArray *)columnNamesForStatement:(sqlite3_stmt *)statement {
    int columnCount = sqlite3_column_count(statement);
    NSMutableArray *columnNames = [NSMutableArray array];
    for (int i=0; i < columnCount; i++) {
        [columnNames addObject:[NSString stringWithUTF8String:sqlite3_column_name(statement, i)]];
    }
    return columnNames;
}

- (NSArray *)columnTypesForStatement:(sqlite3_stmt *)statement {
    int columnCount = sqlite3_column_count(statement);
    NSMutableArray *columnTypes = [NSMutableArray array];
    for (int i=0; i < columnCount; i++) {
        [columnTypes addObject:[NSNumber numberWithInt:[self typeForStatement:statement column:i]]];
    }
    return columnTypes;
}

- (int)typeForStatement:(sqlite3_stmt *)statement column:(int)column {
    const char* columnType = sqlite3_column_decltype(statement, column);

    if (columnType != NULL) {
        return [self columnTypeToInt:[[NSString stringWithUTF8String:columnType] uppercaseString]];
    }

    return sqlite3_column_type(statement, column);
}

- (int)columnTypeToInt:(NSString *)columnType {
    if ([columnType isEqualToString:@"INTEGER"]) {
        return SQLITE_INTEGER;
    } else if ([columnType isEqualToString:@"REAL"]) {
        return SQLITE_FLOAT;
    } else if ([columnType isEqualToString:@"TEXT"]) {
        return SQLITE_TEXT;
    } else if ([columnType isEqualToString:@"BLOB"]) {
        return SQLITE_BLOB;
    } else if ([columnType isEqualToString:@"NULL"]) {
        return SQLITE_NULL;
    }
    return SQLITE_TEXT;
}

- (void)copyValuesFromStatement:(sqlite3_stmt *)statement
                          toRow:(id)row
                      queryInfo:(NSDictionary *)queryInfo
                    columnTypes:(NSArray *)columnTypes
                    columnNames:(NSArray *)columnNames {

    int columnCount = sqlite3_column_count(statement);

    for (int i=0; i<columnCount; i++) {
        id value = [self valueFromStatement:statement column:i queryInfo:queryInfo columnTypes:columnTypes];

        if (value != nil) {
            [row setValue:value forKey:[columnNames objectAtIndex:i]];
        }
    }
}

- (id)valueFromStatement:(sqlite3_stmt *)statement
                  column:(int)column
               queryInfo:(NSDictionary *)queryInfo
             columnTypes:(NSArray *)columnTypes {
    int columnType = [[columnTypes objectAtIndex:column] intValue];

    /*
     * force conversion to the declared type using sql conversions; this saves
     * some problems with NSNull being assigned to non-object values
     */
    if (columnType == SQLITE_INTEGER) {
        return [NSNumber numberWithInt:sqlite3_column_int(statement, column)];
    } else if (columnType == SQLITE_FLOAT) {
        return [NSNumber numberWithDouble:sqlite3_column_double(statement, column)];
    } else if (columnType == SQLITE_TEXT) {
        const char* text = (const char *) sqlite3_column_text(statement, column);
        if (text != nil) {
            return [NSString stringWithUTF8String:text];
        } else {
            return @"";
        }
    } else if (columnType == SQLITE_BLOB) {
        // create an NSData object with the same size as the blob
        return [NSData dataWithBytes:sqlite3_column_blob(statement, column) length:sqlite3_column_bytes(statement, column)];
    } else if (columnType == SQLITE_NULL) {
        return nil;
    }

    NSLog(@"Unrecognized SQL column type: %i for sql %@", columnType, [queryInfo objectForKey:@"sql"]);
    return nil;
}

- (NSArray *)tables {
    return [self executeSql:@"SELECT * FROM sqlite_master WHERE type = 'table'"];
}

- (void)bindArguments:(NSArray *)arguments
          toStatement:(sqlite3_stmt *)statement
            queryInfo:(NSDictionary *)queryInfo {
    int expectedArguments = sqlite3_bind_parameter_count(statement);

    if(expectedArguments != [arguments count]){
        return;
    }
    NSAssert2(expectedArguments == [arguments count], @"Number of bound parameters does not match for sql: %@ parameters '%@'", [queryInfo objectForKey:@"sql"], [queryInfo objectForKey:@"parameters"]);

    for (int i=1; i<=expectedArguments; i++) {
        id argument = [arguments objectAtIndex:i-1];
        if([argument isKindOfClass:[NSString class]])
            sqlite3_bind_text(statement, i, [argument UTF8String], -1, SQLITE_TRANSIENT);
        else if([argument isKindOfClass:[NSData class]])
            sqlite3_bind_blob(statement, i, [argument bytes], (int)[argument length], SQLITE_TRANSIENT);
        else if([argument isKindOfClass:[NSDate class]])
            sqlite3_bind_double(statement, i, [argument timeIntervalSince1970]);
        else if([argument isKindOfClass:[NSNumber class]])
            sqlite3_bind_double(statement, i, [argument doubleValue]);
        else if([argument isKindOfClass:[NSNull class]])
            sqlite3_bind_null(statement, i);
        else {
            sqlite3_finalize(statement);
            [NSException raise:@"Unrecognized object type" format:@"Active record doesn't know how to handle object:'%@' bound to sql: %@ position: %i", argument, [queryInfo objectForKey:@"sql"], i];
        }
    }
}

#pragma mark - Memory Management

- (void)dealloc {
    [self close];
}

@end
