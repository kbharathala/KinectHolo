//
//  ARKitViewController.m
//  HoloKinect
//
//  Created by Krishna Bharathala on 7/29/17.
//  Copyright © 2017 Krishna Bharathala. All rights reserved.
//

#import "ARKitViewController.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "ASScreenRecorder.h"

typedef struct PointCloudModel
{
    float x, y, z, r, g, b;
} PointCloudModel;

@interface ARKitViewController () <ARSCNViewDelegate>

@property (nonatomic, strong) ARSCNView *sceneView;
@property (nonatomic, strong) SCNScene *scene;
@property (nonatomic, strong) UILabel *label;

@property (nonatomic) NSUInteger *count;

@property (nonatomic) NSTimer *renderTimer;

@property (nonatomic, strong) UIButton *playVideo;
@property (nonatomic, strong) UIButton *closeViewButton;
@property (nonatomic, strong) UILabel *tutorialView;
@property (nonatomic, strong) UIButton *emojiButton;
//@property (nonatomic, strong) UIButton *rotateCameraButton;

@property (nonatomic) SCNNode *pointcloudNode;

@property (nonatomic) float xcenter;
@property (nonatomic) float ycenter;
@property (nonatomic) float zcenter;

@property(nonatomic) BOOL buttonPressed;

@property (nonatomic, strong) SCNNode *particle;

@property (nonatomic) BOOL isRecording;
@property (nonatomic, strong) ASScreenRecorder *recorder;

@property (nonatomic, strong) UIView *stickerOverlay;

@property (nonatomic, strong) Message *currModel;
@property (nonatomic, strong) NSArray *models;

@property (nonatomic) BOOL isObjectPlaced;

@end

@implementation ARKitViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.currModel = nil;
    
    self.count = 0;
    
    float sum_x = 0.0;
    float sum_y = 0.0;
    float sum_z = 0.0;
    
    self.models = [[NSArray alloc] initWithObjects:@"krishna", @"natasha", @"brijen_frame", @"avi", nil];
    
    NSMutableArray *frames = self.message.framesArray;
    
    PointCloudModel pointCloudVertices[40000+10];
    
    for (int i = 0; i < 40000; i++) {
        
        PointCloudModel vertex;
        
        int testing_algorithm = i;
        
        vertex.x = ([[[frames firstObject] pointsArray] objectAtIndex:testing_algorithm].x / 14.0);
        vertex.y = [[[frames firstObject] pointsArray] objectAtIndex:testing_algorithm].y / -14.0;
        vertex.z = ([[[frames firstObject] pointsArray] objectAtIndex:testing_algorithm].z / 14.0);
        
        vertex.r = [[[frames firstObject] pointsArray] objectAtIndex:testing_algorithm].r / 255.0;
        vertex.g = [[[frames firstObject] pointsArray] objectAtIndex:testing_algorithm].g / 255.0;
        vertex.b = [[[frames firstObject] pointsArray] objectAtIndex:testing_algorithm].b / 255.0;
        
        sum_x += vertex.x;
        sum_y += vertex.y;
        sum_z += vertex.z;
        
        pointCloudVertices[i] = vertex;
        
    }
    
    self.xcenter = sum_x / 40000;
    self.ycenter = sum_y / 40000;
    self.zcenter = sum_z / 40000;
    
    self.buttonPressed = NO;
    
    // setting up the sceneView
    self.sceneView = [[ARSCNView alloc] initWithFrame:self.view.frame];
    self.sceneView.delegate = self;
    [self.view addSubview: self.sceneView];
    
    UIView *overlayView = [[UIView alloc] initWithFrame:self.view.frame];
    [overlayView setUserInteractionEnabled:NO];
    [overlayView setBackgroundColor:[UIColor colorWithWhite:0.3 alpha:0.3]];
    [self.view addSubview: overlayView];
    
    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe:)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:rightSwipe];
    
    SCNMaterial *particleMaterial = [SCNMaterial new];
    particleMaterial.diffuse.contents = [UIColor colorWithRed:125/255.0 green:125/255.0 blue:125/255.0 alpha:1];
    
    //TODO
    // convert array to point cloud data (position and color)
    NSData *pointCloudData = [NSData dataWithBytes:&pointCloudVertices length:sizeof(pointCloudVertices)];
    
    //    // create vertex source
    SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithData:pointCloudData
                                                                       semantic:SCNGeometrySourceSemanticVertex
                                                                    vectorCount:40000
                                                                floatComponents:YES
                                                            componentsPerVector:3
                                                              bytesPerComponent:sizeof(float)
                                                                     dataOffset:offsetof(PointCloudModel, x)
                                                                     dataStride:sizeof(PointCloudModel)];
    
    // create color source
    SCNGeometrySource *colorSource = [SCNGeometrySource geometrySourceWithData:pointCloudData
                                                                      semantic:SCNGeometrySourceSemanticColor
                                                                   vectorCount:40000
                                                               floatComponents:YES
                                                           componentsPerVector:3
                                                             bytesPerComponent:sizeof(float)
                                                                    dataOffset:offsetof(PointCloudModel, r)
                                                                    dataStride:sizeof(PointCloudModel)];
    
    // create element
    SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:nil
                                                                primitiveType:SCNGeometryPrimitiveTypePoint
                                                               primitiveCount:40000
                                                                bytesPerIndex:sizeof(int)];
    
    // create geometry
    SCNGeometry *pointcloudGeometry = [SCNGeometry geometryWithSources:@[ vertexSource, colorSource] elements:@[ element]];
    
    SCNNode *pointcloudNode = [SCNNode nodeWithGeometry:pointcloudGeometry];
    //     pointcloudGeometry.firstMaterial.shaderModifiers = @{SCNShaderModifierEntryPointGeometry : @"gl_PointSize = 0.0000000000005"};
    // pointcloudNode.geometry = pointcloudGeometry;
    pointcloudNode.position = SCNVector3Make(0, 0, 0);
    pointcloudNode.pivot = SCNMatrix4MakeRotation((CGFloat) -1 * M_PI,0, (CGFloat) M_PI * 1.5, 0);
    
    //    SCNGeometry *particleGeometry = [SCNSphere sphereWithRadius:0.003];
    //    particleGeometry.firstMaterial = particleMaterial;
    
    self.particle = pointcloudNode;
    self.particle.position = SCNVector3Make(0, 0, 0);
    [self.sceneView.scene.rootNode addChildNode:self.particle];
    
    [self.view setMultipleTouchEnabled:YES];
    
    self.recorder = [ASScreenRecorder sharedInstance];
    self.isRecording = NO;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    
    if (!self.isObjectPlaced) {
        [self.playVideo setUserInteractionEnabled:YES];
        [self.tutorialView removeFromSuperview];
        [self setIsObjectPlaced:YES];
    }
    
    UITouch *touch = touches.allObjects.firstObject;
    NSArray<ARHitTestResult *> *results =
    [self.sceneView hitTest: [touch locationInView:self.sceneView] types:ARHitTestResultTypeFeaturePoint];
    
    ARHitTestResult *hitFeature = results.lastObject;
    SCNMatrix4 hitTransform = SCNMatrix4FromMat4(hitFeature.worldTransform);
    
    SCNVector3 hitPosition = SCNVector3Make(hitTransform.m41, hitTransform.m42, hitTransform.m43);
    
    self.particle.position = hitPosition;
    
    if (self.currModel) {
        [self makeModelCloud];
    } else {
        NSLog(@"ARE WE HERE");
        if (self.buttonPressed) {
            SCNAction *fadeParticle = [SCNAction fadeOpacityTo:0.0 duration:0.00f];
            [self.particle runAction:fadeParticle];
            NSLog(@"button pressed");
            [self movePointCloud];
            self.pointcloudNode.position = SCNVector3Make(self.particle.position.x, self.particle.position.y, self.particle.position.z);
        }
    }

    NSLog(@"New Particle Positioning: %f %f %f", hitPosition.x, hitPosition.y, hitPosition.z);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Setting up the navigation bar
    [self.navigationController.navigationBar setHidden:YES];
    self.navigationController.navigationItem.backBarButtonItem = nil;
    
    // starting the session
    ARWorldTrackingSessionConfiguration *configuration = [ARWorldTrackingSessionConfiguration new];
    configuration.planeDetection = ARPlaneDetectionHorizontal;
    configuration.worldAlignment = ARWorldAlignmentGravityAndHeading;
    [self.sceneView.session runWithConfiguration:configuration];
    
    self.playVideo = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.playVideo setFrame: CGRectMake(0, 0, 80, 80)];
    [self.playVideo setCenter:CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height * 20 / 21)];
    [self.playVideo setImage:[UIImage imageNamed:@"circle"] forState:UIControlStateNormal];
    self.playVideo.backgroundColor = [UIColor clearColor];
    [self.playVideo addTarget:self action:@selector(playVideoPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.playVideo];
    [self.playVideo setUserInteractionEnabled:NO];
    
    self.closeViewButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.closeViewButton setFrame: CGRectMake(20, 30, 20, 20)];
    [self.closeViewButton setImage:[UIImage imageNamed:@"cross"] forState:UIControlStateNormal];
    self.closeViewButton.backgroundColor = [UIColor clearColor];
    [self.closeViewButton addTarget:self action:@selector(closeViewPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.closeViewButton];
    
    self.tutorialView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width + 100, 40)];
    [self.tutorialView setTextColor:[UIColor whiteColor]];
    [self.tutorialView setText:@"Drop a sticker to get started"];
    [self.tutorialView setTextAlignment:NSTextAlignmentCenter];
    [self.tutorialView setCenter:CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2)];
    [self.tutorialView setFont: [UIFont fontWithName:@"AvenirNext-Regular" size:18.0]];
    [self.tutorialView setUserInteractionEnabled:NO];
    [self.view addSubview: self.tutorialView];
    
    //    self.rotateCameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    //    [self.rotateCameraButton setFrame: CGRectMake(self.view.frame.size.width - 60, 30, 30, 30)];
    //    // [self.closeViewButton setCenter:CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height * 20 / 21)];
    //    [self.rotateCameraButton setImage:[UIImage imageNamed:@"rotateCamera"] forState:UIControlStateNormal];
    //    self.rotateCameraButton.backgroundColor = [UIColor clearColor];
    //    [self.rotateCameraButton addTarget:self action:@selector(closeViewPressed) forControlEvents:UIControlEventTouchUpInside];
    //    [self.view addSubview:self.rotateCameraButton];
    
    self.emojiButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.emojiButton setFrame: CGRectMake(self.view.frame.size.width - 60, 20, 40, 40)];
    [self.emojiButton setImage:[UIImage imageNamed:@"emoji"] forState:UIControlStateNormal];
    self.emojiButton.backgroundColor = [UIColor clearColor];
    [self.emojiButton addTarget:self action:@selector(emojiButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.emojiButton];
    
}

- (void) handleTimer:(NSTimer *)timer {
    [self resetPointCloud];
    // Hanlde the timed event.
}

- (void)didSwipe:(UISwipeGestureRecognizer*) swipe {
    
    if (swipe.direction == UISwipeGestureRecognizerDirectionRight) {
        [self stopRecorder];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.sceneView.scene removeAllParticleSystems];
    [self.sceneView.session pause];
}

- (void)resetPointCloud {
    //    self.pointcloudNode.position = self.particle.position;
    SCNAction *fadeParticle = [SCNAction fadeOpacityTo:0.0 duration:0.05f];
    [self.pointcloudNode runAction:fadeParticle];
    [self makePointCloud];
}

-(void)movePointCloud {
    //    self.pointcloudNode.position = self.particle.position;
    SCNAction *fadeParticle = [SCNAction fadeOpacityTo:0.0 duration:0.0f];
    [self.pointcloudNode runAction:fadeParticle];
    [self makePointCloud];
}

- (void)makeModelCloud
{
    
    
    NSMutableArray *frames = self.currModel.framesArray;
    
    NSUInteger numPoints;
    
    if (40000 < [[self.currModel.framesArray firstObject].pointsArray count]) {
        numPoints = 40000;
    } else {
        numPoints = [[self.currModel.framesArray firstObject].pointsArray count];
    }
    
    PointCloudModel pointCloudVertices[numPoints+10];
    
    NSLog(@"%lu", [[self.currModel.framesArray firstObject].pointsArray count]);
    for (int i = 0; i < numPoints; i++) {
        
        PointCloudModel vertex;
        
        vertex.x = ([[[frames firstObject] pointsArray] objectAtIndex:i].x / 14.0);
        vertex.y = [[[frames firstObject] pointsArray] objectAtIndex:i].y / -14.0;
        vertex.z = [[[frames firstObject] pointsArray] objectAtIndex:i].z / 14.0;
        
        vertex.r = [[[frames firstObject] pointsArray] objectAtIndex:i].r / 255.0;
        vertex.g = [[[frames firstObject] pointsArray] objectAtIndex:i].g / 255.0;
        vertex.b = [[[frames firstObject] pointsArray] objectAtIndex:i].b / 255.0;
        
        pointCloudVertices[i] = vertex;
    }
    
    // convert array to point cloud data (position and color)
    NSData *pointCloudData = [NSData dataWithBytes:&pointCloudVertices length:sizeof(pointCloudVertices)];
    
    //    // create vertex source
    SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithData:pointCloudData
                                                                       semantic:SCNGeometrySourceSemanticVertex
                                                                    vectorCount:numPoints
                                                                floatComponents:YES
                                                            componentsPerVector:3
                                                              bytesPerComponent:sizeof(float)
                                                                     dataOffset:offsetof(PointCloudModel, x)
                                                                     dataStride:sizeof(PointCloudModel)];
    
    // create color source
    SCNGeometrySource *colorSource = [SCNGeometrySource geometrySourceWithData:pointCloudData
                                                                      semantic:SCNGeometrySourceSemanticColor
                                                                   vectorCount:numPoints
                                                               floatComponents:YES
                                                           componentsPerVector:3
                                                             bytesPerComponent:sizeof(float)
                                                                    dataOffset:offsetof(PointCloudModel, r)
                                                                    dataStride:sizeof(PointCloudModel)];
    
    // create element
    SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:nil
                                                                primitiveType:SCNGeometryPrimitiveTypePoint
                                                               primitiveCount:numPoints
                                                                bytesPerIndex:sizeof(int)];
    
    // create geometry
    SCNGeometry *pointcloudGeometry = [SCNGeometry geometryWithSources:@[ vertexSource, colorSource] elements:@[ element]];
    
    SCNNode *pointcloudNode = [SCNNode nodeWithGeometry:pointcloudGeometry];
    pointcloudNode.position = SCNVector3Make(self.particle.position.x, self.particle.position.y, self.particle.position.z);
    pointcloudNode.pivot = SCNMatrix4MakeRotation((CGFloat) -1 * M_PI,0, (CGFloat) M_PI * 1.5, 0);

    [self.sceneView.scene.rootNode addChildNode:pointcloudNode];
}

- (void)makePointCloud
{
    
    NSUInteger numPoints;
    
    if (40000 < [[self.message.framesArray objectAtIndex:self.count].pointsArray count]) {
        numPoints = 40000;
    } else {
        numPoints = [[self.message.framesArray objectAtIndex:self.count].pointsArray count];
    }
        
    PointCloudModel pointCloudVertices[40000+10];
    NSMutableArray *frames = self.message.framesArray;
    
    NSLog(@"%lu", [[self.message.framesArray objectAtIndex:self.count].pointsArray count]);
    float sum_x = 0.0;
    float sum_y = 0.0;
    float sum_z = 0.0;
    for (int i = 0; i < numPoints; i++) {
        
        PointCloudModel vertex;
        
        int testing_algorithm = i;
        
        vertex.x = ([[[frames objectAtIndex:self.count] pointsArray] objectAtIndex:testing_algorithm].x / 14.0);
        vertex.y = [[[frames objectAtIndex:self.count] pointsArray] objectAtIndex:testing_algorithm].y / -14.0;
        vertex.z = [[[frames objectAtIndex:self.count] pointsArray] objectAtIndex:testing_algorithm].z / 14.0;
        
        sum_x += vertex.x;
        sum_y += vertex.y;
        sum_z += vertex.z;
        
        vertex.r = [[[frames objectAtIndex:self.count] pointsArray] objectAtIndex:testing_algorithm].r / 255.0;
        vertex.g = [[[frames objectAtIndex:self.count] pointsArray] objectAtIndex:testing_algorithm].g / 255.0;
        vertex.b = [[[frames objectAtIndex:self.count] pointsArray] objectAtIndex:testing_algorithm].b / 255.0;
        
        if (i%1000 == 0) {
            NSLog(@"Location: %f, %f, %f\n Color: %f, %f, %f", vertex.x, vertex.y, vertex.z, vertex.r, vertex.g, vertex.b);
        }
        
        pointCloudVertices[i] = vertex;
    }
    
    self.count = self.count + 1;
    
    if (self.count >= self.message.framesArray_Count) {
        self.count = 0;
    }
    
    self.xcenter = sum_x / numPoints;
    self.ycenter = sum_y / numPoints;
    self.zcenter = sum_z / numPoints;
    
    
    // convert array to point cloud data (position and color)
    NSData *pointCloudData = [NSData dataWithBytes:&pointCloudVertices length:sizeof(pointCloudVertices)];
    
    //    // create vertex source
    SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithData:pointCloudData
                                                                       semantic:SCNGeometrySourceSemanticVertex
                                                                    vectorCount:numPoints
                                                                floatComponents:YES
                                                            componentsPerVector:3
                                                              bytesPerComponent:sizeof(float)
                                                                     dataOffset:offsetof(PointCloudModel, x)
                                                                     dataStride:sizeof(PointCloudModel)];
    
    // create color source
    SCNGeometrySource *colorSource = [SCNGeometrySource geometrySourceWithData:pointCloudData
                                                                      semantic:SCNGeometrySourceSemanticColor
                                                                   vectorCount:numPoints
                                                               floatComponents:YES
                                                           componentsPerVector:3
                                                             bytesPerComponent:sizeof(float)
                                                                    dataOffset:offsetof(PointCloudModel, r)
                                                                    dataStride:sizeof(PointCloudModel)];
    
    // create element
    SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:nil
                                                                primitiveType:SCNGeometryPrimitiveTypePoint
                                                               primitiveCount:numPoints
                                                                bytesPerIndex:sizeof(int)];
    
    // create geometry
    SCNGeometry *pointcloudGeometry = [SCNGeometry geometryWithSources:@[ vertexSource, colorSource] elements:@[ element]];
    
    self.pointcloudNode = [SCNNode nodeWithGeometry:pointcloudGeometry];
//    self.pointcloudNode.position = self.particle.position;
    self.pointcloudNode.pivot = SCNMatrix4MakeRotation((CGFloat) -1 * M_PI,0, (CGFloat) M_PI * 1.5, 0);
    
    [self.sceneView.scene.rootNode addChildNode:self.pointcloudNode];
    
}

-(void) playVideoPressed {
    
    [self.playVideo setImage:[UIImage imageNamed:@"redCircle"] forState:UIControlStateNormal];
    [self.playVideo setUserInteractionEnabled:NO];
    
    self.renderTimer = [NSTimer scheduledTimerWithTimeInterval:0.05f target:self selector:@selector(handleTimer:) userInfo:nil repeats:YES];
    
    self.buttonPressed = YES;
    NSLog(@"button is pressed");
    
    SCNAction *fadeParticle = [SCNAction fadeOpacityTo:0.0 duration:0.00f];
    [self.particle runAction:fadeParticle];
    
    [self makePointCloud];
    //    self.pointcloudNode.position = self.particle.position;
    
    
    [self.recorder startRecording];
    self.isRecording = YES;
    
    [NSTimer scheduledTimerWithTimeInterval:10.0
                                     target:self
                                   selector:@selector(stopRecorder)
                                   userInfo:nil
                                    repeats:NO];
}

-(void) stopRecorder {
    if (self.isRecording) {
        [self.renderTimer invalidate];
        [self.recorder stopRecordingWithCompletion:^{
            NSLog(@"Finished recording");
        }];
        [SVProgressHUD showSuccessWithStatus:@"saved to disk!"];
    }
    [self.navigationController popViewControllerAnimated:YES];
    
}

-(void) closeViewPressed {
    if (self.isRecording) {
        [self.recorder stopRecordingWithCompletion:^{
            NSLog(@"Finished recording");
        }];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

-(void) emojiButtonPressed {
    self.stickerOverlay = [[UIView alloc] initWithFrame:self.view.frame];
    [self.stickerOverlay setBackgroundColor:[UIColor colorWithWhite:0.1 alpha:0.9]];
    [self.view addSubview: self.stickerOverlay];
    
    UIButton *closeStickerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeStickerButton setFrame: CGRectMake(20, 30, 20, 20)];
    [closeStickerButton setImage:[UIImage imageNamed:@"cross"] forState:UIControlStateNormal];
    closeStickerButton.backgroundColor = [UIColor clearColor];
    [closeStickerButton addTarget:self action:@selector(closeStickerPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.stickerOverlay addSubview:closeStickerButton];
    
    UIButton *firstUser = [UIButton buttonWithType:UIButtonTypeCustom];
    [firstUser setFrame:CGRectMake(0, 0, 80, 80)];
    [firstUser setCenter:CGPointMake(self.view.frame.size.width/5, 120)];
    [firstUser setImage:[UIImage imageNamed:@"krishna"] forState:UIControlStateNormal];
    firstUser.layer.cornerRadius = 40;
    firstUser.clipsToBounds = YES;
    [firstUser addTarget:self action:@selector(firstUserStickerPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.stickerOverlay addSubview:firstUser];
    
    UIButton *secondUser = [UIButton buttonWithType:UIButtonTypeCustom];
    [secondUser setFrame:CGRectMake(0, 0, 80, 80)];
    [secondUser setCenter:CGPointMake(self.view.frame.size.width/2, 120)];
    [secondUser setImage:[UIImage imageNamed:@"Natasha"] forState:UIControlStateNormal];
    secondUser.layer.cornerRadius = 40;
    secondUser.clipsToBounds = YES;
    [secondUser addTarget:self action:@selector(secondUserStickerPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.stickerOverlay addSubview:secondUser];
    
    UIButton *thirdUser = [UIButton buttonWithType:UIButtonTypeCustom];
    [thirdUser setFrame:CGRectMake(0, 0, 80, 80)];
    [thirdUser setCenter:CGPointMake(4 * self.view.frame.size.width/5, 120)];
    [thirdUser setImage:[UIImage imageNamed:@"Brijen"] forState:UIControlStateNormal];
    thirdUser.layer.cornerRadius = 40;
    thirdUser.clipsToBounds = YES;
    [thirdUser addTarget:self action:@selector(thirdUserStickerPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.stickerOverlay addSubview:thirdUser];
    
    UIButton *fourthUser = [UIButton buttonWithType:UIButtonTypeCustom];
    [fourthUser setFrame:CGRectMake(0, 0, 80, 80)];
    [fourthUser setCenter:CGPointMake(self.view.frame.size.width/5, 220)];
    [fourthUser setImage:[UIImage imageNamed:@"Avi"] forState:UIControlStateNormal];
    fourthUser.layer.cornerRadius = 40;
    fourthUser.clipsToBounds = YES;
    [fourthUser addTarget:self action:@selector(fourthUserStickerPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.stickerOverlay addSubview:fourthUser];
}

- (void) closeStickerPressed {
    [self.stickerOverlay removeFromSuperview];
}

- (void) firstUserStickerPressed {
    
    NSString *filepath = [[NSBundle mainBundle] pathForResource:[self.models objectAtIndex:0] ofType:@"hologram"];
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:filepath];
    
    self.currModel = [Message parseFromData:data error:nil];
    [self closeStickerPressed];
}

- (void) secondUserStickerPressed {
    NSString *filepath = [[NSBundle mainBundle] pathForResource:[self.models objectAtIndex:1] ofType:@"hologram"];
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:filepath];
    
    self.currModel = [Message parseFromData:data error:nil];
    [self closeStickerPressed];
}

- (void) thirdUserStickerPressed {
    NSString *filepath = [[NSBundle mainBundle] pathForResource:[self.models objectAtIndex:2] ofType:@"hologram"];
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:filepath];
    
    self.currModel = [Message parseFromData:data error:nil];
    [self closeStickerPressed];
}

- (void) fourthUserStickerPressed {
    NSString *filepath = [[NSBundle mainBundle] pathForResource:[self.models objectAtIndex:3] ofType:@"hologram"];
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:filepath];
    
    self.currModel = [Message parseFromData:data error:nil];
    [self closeStickerPressed];
}

@end


