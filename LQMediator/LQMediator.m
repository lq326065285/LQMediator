//
//  CTModiator.m
//  ComponentDemo
//
//  Created by 李强 on 2017/3/14.
//  Copyright © 2017年 李强. All rights reserved.
//

#import "LQModiator.h"

@interface LQMediator ()

@property (nonatomic,strong) NSMutableDictionary * cachedTarget;

@end

@implementation LQMediator

+(instancetype)shareInstance{
    static CTModiator * modiator = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        modiator = [[CTModiator alloc] init];
    });
    return modiator;
}

/*
 scheme://[target]/[action]?[params]
 
 url sample:
 aaa://targetA/actionB?id=1234
 */
-(id)performActionWithUrl:(NSURL *)url comletion:(void(^)(NSDictionary *))completion{
    NSMutableDictionary * params = [[NSMutableDictionary alloc] init];
    NSString * urlString = [url query];
    for(NSString * param in [urlString componentsSeparatedByString:@"&"]){
        NSArray * elts = [param componentsSeparatedByString:@"="];
        [params setObject:elts.lastObject forKey:elts.firstObject];
    }
    
    NSString * actionName = [url.path stringByReplacingOccurrencesOfString:@"/" withString:@""];
    if ([actionName hasPrefix:@"native"]) {
        return @(NO);
    }
    
    id result = [self performTarget:url.host action:actionName params:params shouldCacheTarget:NO];
    if (completion) {
        if (result) {
            completion(@{@"result":result});
        }else{
            completion(nil);
        }
    }
    return result;
}

-(id)performTarget:(NSString *)targetName action:(NSString *)actionName params:(NSDictionary *)params shouldCacheTarget:(BOOL)shouldCacheTarget{
    NSString * targetClassString = [NSString stringWithFormat:@"Target_%@",targetName];
    NSString * actionString = [NSString stringWithFormat:@"Target_%@",actionName];
    Class targetClass;
    NSObject * target = self.cachedTarget[targetName];
    if (target == nil) {
        targetClass = NSClassFromString(targetClassString);
        target = [[targetClass alloc] init];
    }
    
    SEL action = NSSelectorFromString(actionName);
    if (target == nil) {
        return nil;
    }
    
    if (shouldCacheTarget) {
        self.cachedTarget[targetClassString] = target;
    }
    

    if ([target respondsToSelector:action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [target performSelector:action withObject:params];;
#pragma clang diagnostic pop
    }else{
        actionString = [NSString stringWithFormat:@"Action_%@WithParams:",actionName];
        action = NSSelectorFromString(actionString);
        if ([target respondsToSelector:action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            return [target performSelector:action withObject:params];
#pragma clang diagnostic po
        }else{
            SEL action = NSSelectorFromString(@"notFound:");
            if ([target respondsToSelector:action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                return [target performSelector:action withObject:params];
#pragma clang diagnostic pop
            }else{
                [self.cachedTarget removeObjectForKey:targetClassString];
                return nil;
            }
        }
    }
}

#pragma mark - getter setter
-(NSMutableDictionary *)cachedTarget{
    if (!_cachedTarget) {
        _cachedTarget = [[NSMutableDictionary alloc] init];
    }
    return _cachedTarget;
}

@end
