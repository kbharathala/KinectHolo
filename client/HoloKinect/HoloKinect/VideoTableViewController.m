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
#import "NSObject+MKBlockTimer.h"

#import <ProtocolBuffers/ProtocolBuffers.h>
#import <SVProgressHUD/SVProgressHUD.h>

@interface VideoTableViewController ()

@property (nonatomic, strong) NSMutableArray *videoArray;

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
    
    // [self updateTable];
}

- (void) updateTable {
    
    NSData* raw_data =
        [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://127.0.0.1:5000/api/get_videos/"]];
    if (!raw_data) {
        [SVProgressHUD showErrorWithStatus:@"Please turn on the server"];
        return;
    }

    // __block Person* person;
    //    NSLog(@"proto content size %@",[NSByteCountFormatter stringFromByteCount:raw_data.length countStyle:NSByteCountFormatterCountStyleMemory]);
    //
    //    [NSObject logTime:^{
    //        person = [Person parseFromData:raw_data];
    //         NSLog(@"%ld",(long)person.personId);
    //    } withPrefix:@"builing proto objects"];
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
