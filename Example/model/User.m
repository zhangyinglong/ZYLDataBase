//
//  User.m
//  Example
//
//  Created by zhang yinglong on 2017/6/1.
//  Copyright © 2017年 zhang yinglong. All rights reserved.
//

#import "User.h"

@implementation User

- (NSString *)description {
    return [NSString stringWithFormat:@"[id=%@, name=%@]", @(_uid), _name];
}
    
@end
