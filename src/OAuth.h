#import "common.h"

@interface OAuth : NSObject {
    NSMutableData* readBuf_;
    NSString* content_;
    NSString* error_;
}

@property (nonatomic, retain) NSMutableData* readBuf;
@property (nonatomic, copy) NSString* content;
@property (nonatomic, copy) NSString* error;

+(OAuth*)oauth;

+(BOOL)getRequestTokenForCallbackURL:(NSString*)callbackURL
                          onComplete:(void (^)(OAuth*))callback;

+(BOOL)getAccessTokenWithRequestToken:(NSDictionary*)request_token
                             verifier:(NSString*)verifier
                           onComplete:(void (^)(OAuth*))callback;

+(NSString*)getAuthHeaderForMethod:(NSString*)method URL:(NSString*)url params:(NSDictionary*)params;

+(BOOL)getHomeTimelineParams:(NSDictionary*)params onComplete:(void (^)(OAuth*))callback;
+(BOOL)tweetParams:(NSDictionary*)params onComplete:(void (^)(OAuth*))callback;

@end
