//
//  _JavascriptBridgeProxy.m
//  
//
//  Created by 吴哲 on 2023/8/7.
//

#import "_JavascriptBridgeProxy.h"

@implementation _JavascriptBridgeProxy
{
    id<_JavascriptBridgeProxyInterceptor> __weak _interceptor;
    id __weak _target;
}

- (instancetype)initWithTarget:(id)target interceptor:(id<_JavascriptBridgeProxyInterceptor>)interceptor
{
    self = [super init];
    if (self) {
        _target = target;
        _interceptor = interceptor;
    }
    return self;
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    /// 拦截器方法交由拦截器执行
    if ([self interceptsSelector:aSelector]) {
      return _interceptor;
    } else {
        id target = _target;
        if (target) {
            return [target respondsToSelector:aSelector] ? target : nil;
        } else {
            _interceptor = nil;
            return nil;
        }
    }
}

- (void)forwardInvocation:(NSInvocation *)invocation {
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *methodSignature = nil;
    /// 拦截器方法交由拦截器执行 获取拦截器方法签名
    if ([self interceptsSelector:aSelector]) {
      methodSignature = [[_interceptor class] instanceMethodSignatureForSelector:aSelector];
    } else {
      methodSignature = [[_target class] instanceMethodSignatureForSelector:aSelector];
    }
    return methodSignature ?: [NSMethodSignature signatureWithObjCTypes:"@^v^c"];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([self interceptsSelector:aSelector]) {
      return [_interceptor respondsToSelector:aSelector];
    } else {
      return [_target respondsToSelector:aSelector];
    }
}

- (BOOL)isEqual:(id)object {
    return [_target isEqual:object];
}

- (NSUInteger)hash {
    return [_target hash];
}

- (Class)superclass {
    return [_target superclass];
}

- (Class)class {
    return [_target class];
}

- (BOOL)isKindOfClass:(Class)aClass {
    return [_target isKindOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass {
    return [_target isMemberOfClass:aClass];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    id target = _target;
    if (target) {
      return [target conformsToProtocol:aProtocol];
    } else {
      return [super conformsToProtocol:aProtocol];
    }
}

- (BOOL)isProxy {
    return YES;
}

- (NSString *)description {
    return [_target description];
}

- (NSString *)debugDescription {
    return [_target debugDescription];
}

- (BOOL)interceptsSelector:(SEL)aSelector
{
  return NO;
}
@end
