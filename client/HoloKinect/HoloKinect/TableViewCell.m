//
//  TableViewCell.m
//  HoloKinect
//
//  Created by Natasha Narang on 7/29/17.
//  Copyright © 2017 Krishna Bharathala. All rights reserved.
//

#import "TableViewCell.h"

@implementation TableViewCell

- (id)initWithCellInfo:(NSString *)username_  timestamp:(NSString *)timestamp_ picture:(UIImage *)picture_
{
    
    //self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    
    self = [super init];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:picture_];
    [imageView setFrame:CGRectMake(8, 8, 40, 40)];
    imageView.layer.cornerRadius = 20;
    imageView.clipsToBounds = YES;
    [self addSubview:imageView];
    
    UILabel *usernameLabel = [[UILabel alloc] init];
    [usernameLabel setFrame:CGRectMake(56, 8, self.frame.size.width, 30)];
    [usernameLabel setText:username_];
    [usernameLabel setFont: [UIFont fontWithName:@"AvenirNext-Regular" size:14.0]];
    [self addSubview:usernameLabel];
    
    UILabel *timeStampLabel = [[UILabel alloc] init];
    [timeStampLabel setFrame:CGRectMake(56, 24, self.frame.size.width, 30)];
    [timeStampLabel setText:timestamp_];
    [timeStampLabel setFont: [UIFont fontWithName:@"AvenirNext-UltraLight" size:10.0]];
    [self addSubview:timeStampLabel];

    return self;
}


@end
