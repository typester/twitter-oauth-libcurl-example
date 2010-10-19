#import "RootViewController.h"
#import "HomeTimelineViewController.h"
#import "OAuth.h"
#import "NSString+URLEncoding.h"

@interface RootViewController (Private)
-(void)releaseIBOutlets;
@end

@implementation RootViewController

@synthesize signinButton = signinButton_;
@synthesize homeTimelineButton = homeTimelineButton_;
@synthesize statusLabel = statusLabel_;
@synthesize loadingView = loadingView_;

-(void)viewDidLoad {
    // check authentication
    [super viewDidLoad];
}

-(void)viewDidUnload {
    [self releaseIBOutlets];
    [super viewDidUnload];
}

-(void)viewWillAppear:(BOOL)animated {
    NSUserDefaults* d = [NSUserDefaults standardUserDefaults];
    NSDictionary* access_token = [d dictionaryForKey:@"access_token"];

    if (nil == access_token) {
        self.homeTimelineButton.hidden = YES;
        self.statusLabel.text = @"Status: not signed in";
    }
    else {
        self.signinButton.hidden = YES;
        self.homeTimelineButton.hidden = NO;
        self.statusLabel.text = [NSString stringWithFormat:@"Status: signed in as %@", [d stringForKey:@"screen_name"]];
    }

    [super viewWillAppear:animated];
}

-(void)dealloc {
    [self releaseIBOutlets];
    [super dealloc];
}

-(void)releaseIBOutlets {
    self.signinButton = nil;
    self.homeTimelineButton = nil;
    self.statusLabel = nil;
    self.loadingView = nil;
}

-(IBAction)onPushSigninButton:(id)sender {
    self.loadingView.hidden = NO;

    [OAuth getRequestTokenForCallbackURL:@"twitteroauthexample://oauthcallback"
                              onComplete:^(OAuth* res){
        if (nil != res.error) {
            UIAlertView* alert = [[UIAlertView alloc]
                                     initWithTitle:@"Network Error"
                                           message:res.error
                                          delegate:nil
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil];
            [alert show];
            [alert release];
        }
        else {
            NSDictionary* token = [res.content URLEncodedDictionary];

            if (nil != token &&
                nil != [token objectForKey:@"oauth_token"] &&
                nil != [token objectForKey:@"oauth_token_secret"]) {

                NSDictionary* request_token = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                     [token objectForKey:@"oauth_token"], @"token",
                                                                     [token objectForKey:@"oauth_token_secret"], @"secret",
                                                            nil];
                NSUserDefaults* d = [NSUserDefaults standardUserDefaults];
                [d setObject:request_token forKey:@"request_token"];

                [[UIApplication sharedApplication]
                    openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://twitter.com/oauth/authorize?oauth_token=%@",
                                                           [request_token objectForKey:@"token"]]]];
            }
            else {
                UIAlertView* alert = [[UIAlertView alloc]
                                         initWithTitle:@"API Error"
                                               message:res.content
                                              delegate:nil
                                         cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil];
                [alert show];
                [alert release];
            }
        }

        self.loadingView.hidden = YES;
    }];
}

-(IBAction)onPushHomeTimelineButton:(id)sender {
    HomeTimelineViewController* next = [[HomeTimelineViewController alloc] initWithNibName:@"HomeTimelineView" bundle:nil];
    [self.navigationController pushViewController:next animated:YES];
    [next release];
}

@end
