//
//  User.h
//  Example
//
//  Created by zhang yinglong on 2017/6/1.
//  Copyright © 2017年 zhang yinglong. All rights reserved.
//

#import <ZYLDataBase/ZYLDataBase.h>

@interface User : BaseModel

@property (nonatomic, assign) uint64_t uid;
    
@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *nickName;

@property (nonatomic, assign) NSInteger gender;

@end
