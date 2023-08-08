//
//  _JavascriptBridgeProxy.h
//  
//
//  Created by 吴哲 on 2023/8/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol _JavascriptBridgeProxyInterceptor <NSObject>
@end

@interface _JavascriptBridgeProxy : NSObject

- (instancetype)initWithTarget:(nullable id)target
                   interceptor:(id<_JavascriptBridgeProxyInterceptor>)interceptor;

- (BOOL)interceptsSelector:(SEL)aSelector;
@end

NS_ASSUME_NONNULL_END
