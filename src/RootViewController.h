#import "common.h"

@interface RootViewController : UIViewController {
    UIButton* signinButton_;
    UIButton* homeTimelineButton_;
    UITextField* tweetField_;
    UIButton* tweetButton_;
    UILabel* statusLabel_;
    UIView* loadingView_;
}

@property (nonatomic, retain) IBOutlet UIButton* signinButton;
@property (nonatomic, retain) IBOutlet UIButton* homeTimelineButton;
@property (nonatomic, retain) IBOutlet UITextField* tweetField;
@property (nonatomic, retain) IBOutlet UIButton* tweetButton;
@property (nonatomic, retain) IBOutlet UILabel* statusLabel;
@property (nonatomic, retain) IBOutlet UIView* loadingView;

-(IBAction)onPushSigninButton:(id)sender;
-(IBAction)onPushHomeTimelineButton:(id)sender;
-(IBAction)onPushTweetButton:(id)sender;

@end
