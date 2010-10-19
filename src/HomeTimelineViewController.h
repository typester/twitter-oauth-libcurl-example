#import "common.h"

@interface HomeTimelineViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    NSArray* tweets_;
    UITableView* table_;
}

@property (nonatomic, retain) NSArray* tweets;
@property (nonatomic, retain) IBOutlet UITableView* table;

@end
