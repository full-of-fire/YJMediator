//
//  YJMediator.m
//  IIMediaNews
//
//  Created by yj on 17/3/9.
//  Copyright © 2017年 iimedia. All rights reserved.
//

#import "YJMediator.h"
#import <objc/runtime.h>

@interface YJMediator ()

@property (strong,nonatomic) NSMutableDictionary *cachedTarget;

@end

@implementation YJMediator

+ (instancetype)sharedMediator {

    static YJMediator *instacne;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        instacne = [[YJMediator alloc] init];
    });
    
    return instacne;
}


/*
 scheme://[target]/[action]?[params]
 
 url sample:
 aaa://targetA/actionB?id=1234
 */
- (id)yj_performActionWithUrl:(NSURL *)url completion:(void (^)(NSDictionary *))completion {

    //1、首先解析参数
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSString *queryString = url.query;
    
    for (NSString *keyValue in [queryString componentsSeparatedByString:@"&"]) {
        
        NSArray *arr  = [keyValue componentsSeparatedByString:@"="];
        
        if(arr.count<2) continue;
        [params setObject:[arr lastObject] forKey:[arr firstObject]];
        
    }
    
    // 这里这么写主要是出于安全考虑，防止黑客通过远程方式调用本地模块。这里的做法足以应对绝大多数场景，如果要求更加严苛，也可以做更加复杂的安全逻辑。
    NSString *actionName = [url.path stringByReplacingOccurrencesOfString:@"/" withString:@""];
    if ([actionName hasPrefix:@"native"]) {
        return @(NO);
    }
    
    id result =  [self yj_performTarget:url.host action:actionName params:params shouldCacheTarget:NO];
    
    if (completion) {
        
        if (result) {
            
            completion(@{@"result":result});
        }else{
        
            completion(nil);
        }
    }
    
    
    return result;
}


- (id)yj_performTarget:(NSString*)targetName action:(NSString*)actionName params:(NSDictionary*)params shouldCacheTarget:(BOOL)shouldCacheTarget {

    if(targetName.length == 0 || targetName == nil) return nil;
    
    Class targetClass;
    NSObject *target = self.cachedTarget[targetName];
    if (target == nil) {
        
        targetClass = NSClassFromString(targetName);
        target = [[targetClass alloc] init];
    }
    if (shouldCacheTarget) {
        
        self.cachedTarget[targetName] = target;
    }
    
    SEL action = NSSelectorFromString(actionName);
    
    if ([target respondsToSelector:action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [target performSelector:action withObject:params];
#pragma clang diagnostic pop
    }else{
    
        //如果target是swift对象
        actionName = [NSString stringWithFormat:@"%@WithParams:",actionName];
        action = NSSelectorFromString(actionName);
        if ([target respondsToSelector:action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            return [target performSelector:action withObject:params];
#pragma clang diagnostic pop
        }else {
        
            //这里处理没响应的地方，暂时简化
            [self.cachedTarget removeObjectForKey:targetName];
            return nil;
        }
        
    }
    
    
}


- (void)yj_releaseCachedTargetWithTargetName:(NSString*)targetName {

    [self.cachedTarget removeObjectForKey:targetName];
}


- (NSMutableDictionary*)cachedTarget {
    
    if (_cachedTarget  == nil) {
        
        _cachedTarget = [NSMutableDictionary dictionary];
    }
    return _cachedTarget;
}
@end
