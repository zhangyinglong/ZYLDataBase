# ZYLDataBase
--

ZYLDataBase 是一套使用run-time实现ORM机制的sqlite数据库封装接口层。

# Features
--

* 支持数据库加密
* 使用run-time实现ORM机制
* 支持数据库版本升级，事务化sql操作

# SQLCipher
--

本框架依赖于 [SQLCipher](https://github.com/sqlcipher/sqlcipher) ，其编译方式和普通版本的[SQLite](https://www.sqlite.org/index.html)大致一样，需要注意三点：
>1. 编译参数需定义 **SQLITE_HAS_CODEC** 和 **SQLITE_TEMP_STORE=2**；
>2. 编译过程还需链接 **libcrypto**，针对 iOS 工程只需要引入**Security.framework** 即可
>3. 为支持iPhone真机和模拟器，需要各自编译**ARMV7**和**x86_64**格式，并使用命令 **lipo** 合并成一整个静态库文件
>`lipo -create lib1.a lib2.a -output lib3.a`

# Usage
--

1. 需要存储到 **sqlite** 数据库中的数据结果都需要继承 `BaseModel`

2. 数据库初始化

	```
	// 初始化数据库，并自动检测升级
    DatabaseServiece *service = [DatabaseServiece shared];
   ```

3. 数据库版本升级（需继承 `DatabaseServiece` 类）
	
	```
	// 检测数据库是否有升级，可手动升级
    [service runMigrations];
   ```
   各个数据表项具体升级操作，在 `runMigrations` 方法中实现，举个例子：
   
   旧版本数据结构 `User` 中定义如下：
   
   ```
  	@interface User : BaseModel

	@property (nonatomic, assign) uint64_t uid;
    
	@property (nonatomic, copy) NSString *name;    
    
	@end
   ```
	映射至表 `User`，各属性分别对应表中的字段
   
	| primaryKey  | uid  | name |
	|:----------: |:----:| :---:|
	| 1           | 1000 | 张三  |
	| 2           | 2000 | 李四  |
	| 3           | 3000 | 王麻  |

   新版本 `User` 增加一个属性 `gender` 定义
   
   ```
  	@interface User : BaseModel

	@property (nonatomic, assign) uint64_t uid;
    
	@property (nonatomic, copy) NSString *name; 
	
	@property (nonatomic, assign) NSInteger gender;   
    
	@end
   ```
   此时需要对对数据库进行升级操作，重写 `runMigrations` 方法即可：
   
   ```
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
   ```
	
4. 数据基本操作
	
	数据库中每一张表对应一个 **object class**
	每一条记录都对应一个 **object** 实例
	
	```
	// 增加记录
	User *user = [User new]; // new出来的对象此时未存储至数据库，save之后即存储完毕
	
	// 更新记录
	[user update:@{ @"gender":@(2) }];
	
	// 保存记录
	[user save];
	
	// 删除记录（如果数据库中存在则删除，不存在则不做任何处理）
	[user deleteSelf];
	
	// 修改记录
	[user update:@{ @"gender":@(2) }];
	
	// 存储记录至数据库
	[user save];
	
	// 查找记录
	// sql语句直接搜索
   [User findWithSql:@"select * from User where uid='123'"];
   [User findWithSql:@"select * from User where uid=?" withParameters:[@(123)]];
	[User findWithSqlWithParameters:@"select * from User where uid=?", @"123", nil];
	
	// 条件搜索
	[User findByColumn:@"uid" value:@(100)];
	
	[user resetAll];                                        // 重置查询条件
	user = [user field:@"uid,name"];                        // 设置搜索域
	user = [user whereRaw:@"uid" value:@{@"uid":@(100)}];   // 设置where条件
	user = [user limit:0 size:10];                          // 设置返回记录范围(0-10条记录)
	user = [user order:@"uid"];                             // 设置排序条件
	user = [user group:@"gender"];                          // 设置分组条件
	NSArray *total = [user select];
	
	// 一些常用操作
	[User findAll]; // 查找所有记录
	[User updateAll]; // 数据表升级
	[User deleteAll]; // 清空所有表数据
	
	```
5. 默认开启数据库加密功能
	
	```
	// 必须在初始化数据库之前设置是否支持加密，默认开启
    [DBServiece secureEntry:NO];
	```

# Installation
--

#### CocoaPods
1. 将 cocoapods 更新至最新版本；
2. 在 Podfile 中添加 pod 'ZYLDataBase'；
3. 执行 pod install 或 pod update；
4. 导入 \<ZYLDataBase/ZYLDataBase.h\>。

#### Carthage
1. 在 Cartfile 中添加 `github "zhangyinglong/ZYLDataBase"`；
2. 执行 `carthage update --platform ios` 并将生成的 framework 添加到你的工程；
3. 导入 \<ZYLDataBase/ZYLDataBase.h\>。

# License
--

MIT License

Copyright (c) 2017 zhangyinglong

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.