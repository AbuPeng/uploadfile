//
//  PPNetWorking.h
//  王鹏
//
//  Created by 王鹏 on 16/2/15.
//
//

#import <Foundation/Foundation.h>

@interface NSString (URLEncodingAdditions)
- (NSString *)URLEncodedString;
- (NSString *)URLDecodedString;
@end


@protocol PPNetWorkingDelegate <NSObject>

- (void)netWorkingSuccessDelegate:(id)resultValue;
- (void)netWorkingFailDelegate:(id)errorValue;

@end

@interface PPNetWorking : NSObject
@property(nonatomic, assign)id<PPNetWorkingDelegate> delegate;
/**
 * POST 请求NSURLSession
 */
- (void)PostRequestWithUrlNetWork:(NSString *)url Controller:(NSString *)controller action:(NSString *)action parameter:(NSDictionary *)parameter resultBlock:(void(^)(id resultValue))resultBlock errorBlock:(void(^)(id errorCode))errorBlock;

/**
 * GET 请求NSURLSession
 */
- (void)GetRequestWithUrlNetWork:(NSString *)url Controller:(NSString *)controller action:(NSString *)action parameter:(NSDictionary *)parameter resultBlock:(void(^)(id resultValue))resultBlock errorBlock:(void(^)(id errorCode))errorBlock;
@end
