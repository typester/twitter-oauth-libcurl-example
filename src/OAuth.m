#import "OAuth.h"
#import "NSString+URLEncoding.h"
#import "NSData+Base64.h"

#include <curl/curl.h>
#include <openssl/rand.h>
#include <openssl/hmac.h>
#include <assert.h>

#ifndef OAUTH_CONSUMER_KEY
#define OAUTH_CONSUMER_KEY @"your oauth consumer key"
#endif

#ifndef OAUTH_CONSUMER_SECRET
#define OAUTH_CONSUMER_SECRET @"your oauth consumer secret"
#endif

static size_t curl_read_handler(void* ptr, size_t size, size_t nmemb, void* stream) {
    OAuth* api = (OAuth*)stream;
    [api.readBuf appendBytes:ptr length:size*nmemb];
    return size*nmemb;
}

static CURL* curl_init(NSObject* self) {
    CURL* curl = curl_easy_init();

    if (NULL != curl) {
        NSDictionary* info = [[NSBundle mainBundle] infoDictionary];
        if (info) {
            NSString* ver = [info objectForKey:@"CFBundleVersion"];
            NSString* product = [info objectForKey:@"CFBundleName"];
            NSString* ua = [NSString stringWithFormat:@"%@/%@", product, ver];
            curl_easy_setopt(curl, CURLOPT_USERAGENT, [ua UTF8String]);
        }

        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, curl_read_handler);
        curl_easy_setopt(curl, CURLOPT_FILE, self);
    }

    return curl;
}

@implementation OAuth

@synthesize readBuf = readBuf_;
@synthesize content = content_;
@synthesize error   = error_;

+(OAuth*)oauth {
    OAuth* api = [[OAuth alloc] init];
    if (api) {
        api.readBuf = [NSMutableData data];
        api.content = @"";
    }
    return [api autorelease];
}

-(void)dealloc {
    self.readBuf = nil;
    self.content = nil;
    self.error = nil;
    [super dealloc];
}

+(BOOL)getRequestTokenForCallbackURL:(NSString*)callbackURL onComplete:(void (^)(OAuth*))callback {
    // reset twitter tokens
    NSUserDefaults* d = [NSUserDefaults standardUserDefaults];
    [d removeObjectForKey:@"access_token"];
    [d removeObjectForKey:@"request_token"];

    NSString* url = @"http://twitter.com/oauth/request_token";
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                                             callbackURL, @"oauth_callback", nil];

    dispatch_queue_t mq = dispatch_get_main_queue();
    dispatch_queue_t q  = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    dispatch_async(q, ^{
        OAuth* api = [OAuth oauth];
        CURL* curl = curl_init(api);
        CURLcode res = 0;

        struct curl_slist* slist = NULL;
        slist = curl_slist_append(slist, "Expect:");
        slist = curl_slist_append(slist, "Content-Type: application/x-www-form-urlencoded");
        slist = curl_slist_append(slist, [[OAuth getAuthHeaderForMethod:@"POST" URL:url params:params] UTF8String]);
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, slist);

        curl_easy_setopt(curl, CURLOPT_URL, [url UTF8String]);
        curl_easy_setopt(curl, CURLOPT_POST, 1);
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, "");
        curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, 0);

        res = curl_easy_perform(curl);

        if (0 != res) {
            api.error = [NSString stringWithUTF8String:curl_easy_strerror(res)];
        }
        else {
            NSString* content = [[NSString alloc] initWithData:api.readBuf
                                                      encoding:NSUTF8StringEncoding];
            api.content = content;
            [content release];
        }

        curl_easy_cleanup(curl);

        dispatch_async(mq, ^{
            callback(api);
        });
    });

    return YES;
}

+(BOOL)getAccessTokenWithRequestToken:(NSDictionary*)request_token
                             verifier:(NSString*)verifier
                           onComplete:(void (^)(OAuth*))callback {

    NSString* url = @"http://twitter.com/oauth/access_token";
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                                             request_token, @"token",
                                             verifier,      @"oauth_verifier", nil];

    dispatch_queue_t mq = dispatch_get_main_queue();
    dispatch_queue_t q  = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    dispatch_async(q, ^{
        OAuth* api = [OAuth oauth];
        CURL* curl = curl_init(api);
        CURLcode res = 0;

        struct curl_slist* slist = NULL;
        slist = curl_slist_append(slist, "Expect:");
        slist = curl_slist_append(slist, "Content-Type: application/x-www-form-urlencoded");
        slist = curl_slist_append(slist, [[OAuth getAuthHeaderForMethod:@"POST" URL:url params:params] UTF8String]);
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, slist);

        curl_easy_setopt(curl, CURLOPT_URL, [url UTF8String]);
        curl_easy_setopt(curl, CURLOPT_POST, 1);
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, "");
        curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, 0);

        res = curl_easy_perform(curl);

        if (0 != res) {
            api.error = [NSString stringWithUTF8String:curl_easy_strerror(res)];
        }
        else {
            NSString* content = [[NSString alloc] initWithData:api.readBuf
                                                      encoding:NSUTF8StringEncoding];
            api.content = content;
            [content release];
        }

        curl_easy_cleanup(curl);

        dispatch_async(mq, ^{
            callback(api);
        });
    });

    return YES;
}

+(BOOL)getHomeTimelineParams:(NSDictionary*)params onComplete:(void (^)(OAuth*))callback {
    NSString* url = @"http://api.twitter.com/1/statuses/home_timeline.json";

    dispatch_queue_t mq = dispatch_get_main_queue();
    dispatch_queue_t q  = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    dispatch_async(q, ^{
        OAuth* api = [OAuth oauth];
        CURL* curl = curl_init(api);
        CURLcode res = 0;

        struct curl_slist* slist = NULL;
        slist = curl_slist_append(slist, "Expect:");
        slist = curl_slist_append(slist, "Content-Type: application/x-www-form-urlencoded");
        slist = curl_slist_append(slist, [[OAuth getAuthHeaderForMethod:@"GET" URL:url params:params] UTF8String]);
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, slist);

        curl_easy_setopt(curl, CURLOPT_URL, [url UTF8String]);

        res = curl_easy_perform(curl);

        if (0 != res) {
            api.error = [NSString stringWithUTF8String:curl_easy_strerror(res)];
        }
        else {
            NSString* content = [[NSString alloc] initWithData:api.readBuf
                                                      encoding:NSUTF8StringEncoding];
            api.content = content;
            [content release];
        }

        curl_easy_cleanup(curl);

        dispatch_async(mq, ^{
            callback(api);
        });
    });

    return YES;
}

+(BOOL)tweetParams:(NSDictionary*)params onComplete:(void (^)(OAuth*))callback {
    NSString* url = @"http://api.twitter.com/1/statuses/update.json";

    dispatch_queue_t mq = dispatch_get_main_queue();
    dispatch_queue_t q  = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    dispatch_async(q, ^{
        OAuth* api = [OAuth oauth];
        CURL* curl = curl_init(api);
        CURLcode res = 0;

        struct curl_slist* slist = NULL;
        slist = curl_slist_append(slist, "Expect:");
        slist = curl_slist_append(slist, "Content-Type: application/x-www-form-urlencoded");
        slist = curl_slist_append(slist, [[OAuth getAuthHeaderForMethod:@"POST" URL:url params:params] UTF8String]);
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, slist);

        NSString* content = [NSString stringWithFormat:@"status=%@", [[params objectForKey:@"status"] URLEncodedString]];
        LOG(@"content: %@", content);

        curl_easy_setopt(curl, CURLOPT_URL, [url UTF8String]);
        curl_easy_setopt(curl, CURLOPT_POST, 1);
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, [content UTF8String]);
        curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, strlen([content UTF8String]));

        res = curl_easy_perform(curl);

        if (0 != res) {
            api.error = [NSString stringWithUTF8String:curl_easy_strerror(res)];
        }
        else {
            NSString* content = [[NSString alloc] initWithData:api.readBuf
                                                      encoding:NSUTF8StringEncoding];
            api.content = content;
            [content release];
        }

        curl_easy_cleanup(curl);

        dispatch_async(mq, ^{
            callback(api);
        });
    });

    return YES;
}

+(NSString*)getAuthHeaderForMethod:(NSString*)method URL:(NSString*)url params:(NSDictionary*)params {
    NSNumber* epoch = [NSNumber numberWithInt:(int)[[NSDate date] timeIntervalSince1970]];

    unsigned char rand_buf[10];
    assert(1 == RAND_bytes(rand_buf, 10));
    NSString* rand = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                               rand_buf[0], rand_buf[1], rand_buf[2], rand_buf[3], rand_buf[4], rand_buf[5], rand_buf[6], rand_buf[7], rand_buf[8], rand_buf[9]];

    NSMutableDictionary* p = [NSMutableDictionary dictionaryWithDictionary:params];
    [p setObject:OAUTH_CONSUMER_KEY forKey:@"oauth_consumer_key"];
    [p setObject:rand forKey:@"oauth_nonce"];
    [p setObject:@"HMAC-SHA1" forKey:@"oauth_signature_method"];
    [p setObject:[epoch stringValue] forKey:@"oauth_timestamp"];
    [p setObject:@"1.0" forKey:@"oauth_version"];

    NSDictionary* token = nil;
    if (nil != [p objectForKey:@"token"]) {
        token = [p objectForKey:@"token"];
        [p removeObjectForKey:@"token"];
        [p setObject:[token objectForKey:@"token"] forKey:@"oauth_token"];
    }

    NSArray* oauth_keys = [[p allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

    NSMutableString* sig_base = [NSMutableString stringWithFormat:@"%@&%@&", method, [url URLEncodedString]];
    int f = 0;
    for (NSString* key in oauth_keys) {
        NSString* pair = [NSString stringWithFormat:@"%@=%@", [key URLEncodedString], [[p objectForKey:key] URLEncodedString]];
        if (f++)
            [sig_base appendFormat:@"%@%@", [@"&" URLEncodedString], [pair URLEncodedString]];
        else 
            [sig_base appendFormat:@"%@", [pair URLEncodedString]];
    }

    NSString* token_secret = [token objectForKey:@"secret"];
    NSUserDefaults* d = [NSUserDefaults standardUserDefaults];
    if (nil == token_secret) token_secret = [[d objectForKey:@"access_token"] objectForKey:@"secret"];
    if (nil == token_secret) token_secret = @"";

    NSString* key = [NSString stringWithFormat:@"%@&%@", [OAUTH_CONSUMER_SECRET URLEncodedString], [token_secret URLEncodedString]];
    unsigned char sig[40];
    unsigned int len;
    assert(NULL != HMAC(EVP_sha1(), [key UTF8String], [key length], (const unsigned char*)[sig_base UTF8String], [sig_base length], sig, &len));
    assert(20 == len);

    NSString* oauth_signature = [[NSData dataWithBytes:sig length:len] base64EncodedString];
    [p setObject:oauth_signature forKey:@"oauth_signature"];

    oauth_keys = [[p allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

    NSMutableString* auth_header = [NSMutableString stringWithString:@"Authorization: OAuth realm=\"\""];
    for (NSString* key in oauth_keys) {
        [auth_header appendFormat:@", %@=\"%@\"", [key URLEncodedString], [[p objectForKey:key] URLEncodedString]];
    }

    return [NSString stringWithString:auth_header];
}

@end
