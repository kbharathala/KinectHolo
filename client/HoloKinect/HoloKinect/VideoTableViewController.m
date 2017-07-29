//
//  VideoTableViewController.m
//  HoloKinect
//
//  Created by Krishna Bharathala on 7/29/17.
//  Copyright © 2017 Krishna Bharathala. All rights reserved.
//

#import "VideoTableViewController.h"
#import "VideoPlayerViewController.h"
#import "ARKitViewController.h"

@interface VideoTableViewController ()

@end

@implementation VideoTableViewController

-(id) init {
    self = [super init];
    if (self) {
        self.title = @"KinectHolo";
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [UIView new];
    self.navigationController.navigationBar.backgroundColor =
        [UIColor colorWithRed:255.0/256 green:0/255 blue:255.0/255 alpha:1.0];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    
    // self.view.backgroundColor = [UIColor colorWithRed:153.0/256 green:50.0/256 blue:204.0/256 alpha:1.0];
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    //[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];

    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    
    cell.textLabel.text = @"kbharathala";
    cell.detailTextLabel.text = @"10 minutes ago";
    
    // image stuff
    cell.imageView.image = [UIImage imageNamed:@"SampleProfPic"];
    cell.imageView.layer.cornerRadius = cell.frame.size.height/2;
    cell.imageView.clipsToBounds = YES;

    
    cell.backgroundColor = [UIColor whiteColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    VideoPlayerViewController *playerVC = [[VideoPlayerViewController alloc] init];
//    [self.navigationController pushViewController:playerVC animated:YES];
    
    ARKitViewController *arVC = [[ARKitViewController alloc] init];
    [self.navigationController pushViewController:arVC animated:YES];
}

@end
