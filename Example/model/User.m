//
//  User.m
//  Example
//
//  Created by zhang yinglong on 2017/6/1.
//  Copyright © 2017年 zhang yinglong. All rights reserved.
//

#import "User.h"
#import <objc/runtime.h>

@implementation User

// for debug
- (NSString *)description {
    NSMutableString *result = [NSMutableString stringWithFormat:@"%@={", NSStringFromClass(self.class)];
    NSMutableArray *propertyNamesArray = [NSMutableArray array];
    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList(self.class, &propertyCount);
    for (unsigned int i = 0; i < propertyCount; ++i) {
        objc_property_t property = properties[i];
        const char * name = property_getName(property);
        NSString *key = [NSString stringWithUTF8String:name];
        id value = [self valueForKey:key];
        if ( i == (propertyCount - 1) ) {
            [result appendFormat:@"%@=%@", key, value];
        } else {
            [result appendFormat:@"%@=%@,", key, value];
        }
        [propertyNamesArray addObject:[NSString stringWithUTF8String:name]];
    }
    free(properties);
    [result appendString:@"}"];
    return result;
}

@end
