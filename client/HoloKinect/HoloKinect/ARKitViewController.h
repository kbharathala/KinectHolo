//
//  ARKitViewController.h
//  HoloKinect
//
//  Created by Krishna Bharathala on 7/29/17.
//  Copyright © 2017 Krishna Bharathala. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>
#import <ARKit/ARKit.h>
#import "Message.pbobjc.h"

@interface ARKitViewController : UIViewController

@property (nonatomic, strong) Message *message;
-(id) initWithMessage:(Message *) message;

@end
