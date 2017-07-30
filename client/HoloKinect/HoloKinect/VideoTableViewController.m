//
//  VideoTableViewController.m
//  HoloKinect
//
//  Created by Krishna Bharathala on 7/29/17.
//  Copyright © 2017 Krishna Bharathala. All rights reserved.
//

#import "VideoTableViewController.h"
#import "TableViewCell.h"
#import "ARKitViewController.h"

#import <SVProgressHUD/SVProgressHUD.h>
#import "Message.pbobjc.h"


@interface VideoTableViewController ()

@property (nonatomic, strong) NSMutableArray *videoArray;
@property (nonatomic, strong) Message *message;

@end

@implementation VideoTableViewController

-(id) init {
    self = [super init];
    if (self) {
        self.title = @"HoloChat";
        self.videoArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:NO];
    
    [self updateTable];
}

- (void) updateTable {
    
    
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"movie" ofType:@"hologram"];
    NSLog(@"%@", filepath);
    
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:filepath];
    NSLog(@"%lu", [data length]);
    
    self.message = [Message parseFromData:data error:&error];
    
    return;
    
//    [SVProgressHUD showWithStatus:@"Loading Holos"];
//
//    NSData* raw_data =
//        [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://127.0.0.1:5000/api/get_videos/"]];
//    if (!raw_data) {
//        [SVProgressHUD showErrorWithStatus:@"Our servers are down :("];
//        return;
//    }
//
//    Message *message = [[Message alloc] init];
//
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.tableView reloadData];
//        [SVProgressHUD dismiss];
//    });
    
    // Message parseFromData:<#(nonnull NSData *)#> error:<#(NSError * _Nullable __autoreleasing * _Nullable)#>

}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [UIView new];
    self.navigationController.navigationBar.barTintColor =
        [UIColor colorWithRed:188.0/255 green:0/255 blue:221.0/255 alpha:1.0];
    self.navigationController.navigationBar.translucent = NO;
    
    [self.navigationController.navigationBar
     setTitleTextAttributes: @{NSForegroundColorAttributeName : [UIColor whiteColor],
                               NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Regular" size:20.0]}];
    
    [self.tableView setSeparatorColor:[UIColor colorWithRed:240.0/255 green:240.0/255 blue:240.0/255 alpha:.5]];
    
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10;
    // return [self.videoArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 56;
}

- (TableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TableViewCell *cell =
        [[TableViewCell alloc] initWithCellInfo:@"kbharathala"
                                      timestamp:@"10 minutes ago"
                                        picture:[UIImage imageNamed:@"SampleProfPic"]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ARKitViewController *arVC = [[ARKitViewController alloc] init];
    arVC.message = self.message;
    [self.navigationController pushViewController:arVC animated:YES];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    }
}

@end
