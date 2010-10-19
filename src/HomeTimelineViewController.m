#import "HomeTimelineViewController.h"
#import "OAuth.h"
#import "JSON.h"

@interface HomeTimelineViewController (Private)
-(void)initialize;
-(void)releaseIBOutlets;
@end

@implementation HomeTimelineViewController

@synthesize tweets = tweets_;
@synthesize table = table_;

-(void)initialize {
    self.tweets = [NSArray array];
}

-(id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle {
    if (self = [super initWithNibName:nibName bundle:nibBundle]) {
        [self initialize];
    }
    return self;
}

-(void)awakeFromNib {
    [self initialize];
    [super awakeFromNib];
}

-(void)viewDidLoad {
    NSUserDefaults* d = [NSUserDefaults standardUserDefaults];
    NSDictionary* access_token = [d dictionaryForKey:@"access_token"];

    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                                             access_token, @"token",
                                         nil];

    [OAuth getHomeTimelineParams:params onComplete:^(OAuth* res) {
        if (nil != res.error) {
            LOG(@"error: %@", res.error);
        }
        else {
            LOG(@"res: %@", res.content);

            NSArray* tweets = [res.content JSONValue];
            self.tweets = tweets;

            [self.table reloadData];
        }
    }];

    self.table.delegate = self;
    self.table.dataSource = self;

    [super viewDidLoad];
}

-(void)viewDidUnload {
    [self releaseIBOutlets];
    [super viewDidUnload];
}

-(void)dealloc {
    [self releaseIBOutlets];
    self.tweets = nil;
    [super dealloc];
}

-(void)releaseIBOutlets {
    self.table.delegate = nil;
    self.table.dataSource = nil;
    self.table = nil;
}

-(NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)section {
    return [self.tweets count];
}

-(UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)i {
    static NSString* IDENT = @"TWEET_CELL";

    UITableViewCell* cell = [t dequeueReusableCellWithIdentifier:IDENT];
    if (nil == cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:IDENT] autorelease];
    }

    NSDictionary* tweet = [self.tweets objectAtIndex:i.row];
    NSDictionary* user = [tweet objectForKey:@"user"];

    cell.textLabel.text = [user objectForKey:@"name"];
    cell.detailTextLabel.text = [tweet objectForKey:@"text"];

    return cell;
}

@end
