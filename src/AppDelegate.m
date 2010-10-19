#import "AppDelegate.h"
#import "OAuth.h"
#import "AuthViewController.h"
#import "NSString+URLEncoding.h"

@implementation AppDelegate

#pragma mark -
#pragma mark Application lifecycle

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [window makeKeyAndVisible];

    return YES;
}

-(void)dealloc {
    [window release];
    [super dealloc];
}

-(BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    LOG(@"handleOpenURL: %@", [[url query] URLEncodedDictionary]);

    if ([[url host] isEqualToString:@"oauthcallback"]) {
        NSUserDefaults* d = [NSUserDefaults standardUserDefaults];
        NSDictionary* request_token = [d objectForKey:@"request_token"];

        if (nil != request_token) {
            NSDictionary *dict = [[url query] URLEncodedDictionary];
            if (nil != [dict objectForKey:@"oauth_token"] &&
                nil != [dict objectForKey:@"oauth_verifier"]) {

                AuthViewController* authView = [[AuthViewController alloc] initWithNibName:@"AuthView" bundle:nil];
                [window.rootViewController presentModalViewController:authView animated:NO];
                [authView release];

                [OAuth getAccessTokenWithRequestToken:request_token
                                             verifier:[dict objectForKey:@"oauth_verifier"]
                                           onComplete:^(OAuth* res){

                    if (nil != res.error) {
                        LOG(@"Error: %@", res.error);
                    }
                    else {
                        NSDictionary* token = [res.content URLEncodedDictionary];
                        if (nil != [token objectForKey:@"oauth_token"] &&
                            nil != [token objectForKey:@"oauth_token_secret"]) {

                            LOG(@"access_token: %@", token);

                            NSDictionary* access_token = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                                  [token objectForKey:@"oauth_token"], @"token",
                                                                                  [token objectForKey:@"oauth_token_secret"], @"secret", nil];
                            [d setObject:access_token forKey:@"access_token"];
                            [d setObject:[token objectForKey:@"screen_name"] forKey:@"screen_name"];
                            [d removeObjectForKey:@"request_token"];

                            // authentication completed
                            [window.rootViewController dismissModalViewControllerAnimated:NO];
                        }
                    }
                }];
            }
        }
    }

    return YES;
}

@end
