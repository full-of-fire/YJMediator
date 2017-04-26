//
//  YJMediator.h
//  IIMediaNews
//
//  Created by yj on 17/3/9.
//  Copyright © 2017年 iimedia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YJMediator : NSObject

+ (instancetype)sharedMediator;

/**
 通过target-action 本地调用不同模块组件

 @param targetName        组件名字
 @param actionName        组件的方法名字
 @param params            参数
 @param shouldCacheTarget 是否缓冲对象

 @return 返回actionName方法的结果
 */
- (id)yj_performTarget:(NSString*)targetName action:(NSString*)actionName params:(NSDictionary*)params shouldCacheTarget:(BOOL)shouldCacheTarget;



// 远程App调用入口
- (id)yj_performActionWithUrl:(NSURL *)url completion:(void(^)(NSDictionary *info))completion;

- (void)yj_releaseCachedTargetWithTargetName:(NSString*)targetName;

@end
