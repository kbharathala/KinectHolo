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

@property (nonatomic) int *count;

@property (nonatomic, strong) UIButton *playVideo;
@property (nonatomic, strong) UIButton *closeViewButton;
//@property (nonatomic, strong) UIButton *rotateCameraButton;

@property (nonatomic) float xcenter;
@property (nonatomic) float ycenter;
@property (nonatomic) float zcenter;

@property (nonatomic, strong) SCNNode *particle;

@property (nonatomic) BOOL isRecording;
@property (nonatomic, strong) ASScreenRecorder *recorder;


@property (nonatomic) BOOL isObjectPlaced;

@end

@implementation ARKitViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.count = 0;
    self.xcenter = 0.0;
    self.ycenter = 0.0;
    self.zcenter = 0.0;
    
    // setting up the sceneView
    self.sceneView = [[ARSCNView alloc] initWithFrame:self.view.frame];
    self.sceneView.delegate = self;
    [self.view addSubview: self.sceneView];
    
    // [self makePointCloud];
    
    //    [self setupLabel];

    //    [NSTimer scheduledTimerWithTimeInterval:0.05f target:self selector:@selector(handleTimer:) userInfo:nil repeats:YES];
    
    //    SCNNode *cubeNode = [SCNNode node];
    //    cubeNode.geometry = [SCNBox boxWithWidth:0.1 height:0.1 length:0.1 chamferRadius:0];
    //    cubeNode.position = SCNVector3Make(0, 0, -0.2);
    //
    //    [self.sceneView.scene.rootNode addChildNode:cubeNode];
    
    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe:)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:rightSwipe];
    
    SCNMaterial *particleMaterial = [SCNMaterial new];
    particleMaterial.diffuse.contents = [UIColor colorWithRed:125/255.0 green:125/255.0 blue:125/255.0 alpha:1];
    
    SCNGeometry *particleGeometry = [SCNSphere sphereWithRadius:0.003];
    particleGeometry.firstMaterial = particleMaterial;
    
    self.particle = [SCNNode nodeWithGeometry:particleGeometry];
    self.particle.position = SCNVector3Make(0, 0, 0);
    [self.sceneView.scene.rootNode addChildNode:self.particle];
    
    [self.view setMultipleTouchEnabled:YES];
    
    self.recorder = [ASScreenRecorder sharedInstance];
    self.isRecording = NO;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    if (!self.isObjectPlaced) {
         [self.sceneView addSubview:self.playVideo];
        [self setIsObjectPlaced:YES];
    }
   
    UITouch *touch = touches.allObjects.firstObject;
    NSArray<ARHitTestResult *> *results =
        [self.sceneView hitTest: [touch locationInView:self.sceneView] types:ARHitTestResultTypeFeaturePoint];
    
    ARHitTestResult *hitFeature = results.lastObject;
    SCNMatrix4 hitTransform = SCNMatrix4FromMat4(hitFeature.worldTransform);
    
    SCNVector3 hitPosition = SCNVector3Make(hitTransform.m41, hitTransform.m42, hitTransform.m43);
    
    self.particle.position = hitPosition;
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
    
    self.closeViewButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.closeViewButton setFrame: CGRectMake(20, 30, 20, 20)];
    // [self.closeViewButton setCenter:CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height * 20 / 21)];
    [self.closeViewButton setImage:[UIImage imageNamed:@"cross"] forState:UIControlStateNormal];
    self.closeViewButton.backgroundColor = [UIColor clearColor];
    [self.closeViewButton addTarget:self action:@selector(closeViewPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.closeViewButton];
    
//    self.rotateCameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    [self.rotateCameraButton setFrame: CGRectMake(self.view.frame.size.width - 60, 30, 30, 30)];
//    // [self.closeViewButton setCenter:CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height * 20 / 21)];
//    [self.rotateCameraButton setImage:[UIImage imageNamed:@"rotateCamera"] forState:UIControlStateNormal];
//    self.rotateCameraButton.backgroundColor = [UIColor clearColor];
//    [self.rotateCameraButton addTarget:self action:@selector(closeViewPressed) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:self.rotateCameraButton];
}

- (void) handleTimer:(NSTimer *)timer {
    // [self resetPointCloud];
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
    [self makePointCloud];
}

- (void)makePointCloud
{
    NSUInteger numPoints = 40000;
    
    PointCloudModel pointCloudVertices[numPoints+10];
    NSMutableArray *frames = self.message.framesArray;
    
    NSLog(@"%lu", [[self.message.framesArray firstObject].pointsArray count]);
    float sum_x = 0.0;
    float sum_y = 0.0;
    float sum_z = 0.0;
    for (int i = 0; i < numPoints; i++) {
        
        PointCloudModel vertex;
        
        int testing_algorithm = i*4;
        
        vertex.x = ([[[frames firstObject] pointsArray] objectAtIndex:testing_algorithm].x / 15.0) + (self.particle.position.x - self.xcenter);
        vertex.y = [[[frames firstObject] pointsArray] objectAtIndex:testing_algorithm].y / -15.0 + (self.particle.position.y - self.ycenter);
        vertex.z = [[[frames firstObject] pointsArray] objectAtIndex:testing_algorithm].z / 15.0 + (self.particle.position.z - self.zcenter);
        
        sum_x += vertex.x;
        sum_y += vertex.y;
        sum_z += vertex.z;
        
        vertex.r = [[[frames firstObject] pointsArray] objectAtIndex:testing_algorithm].r / 255.0;
        vertex.g = [[[frames firstObject] pointsArray] objectAtIndex:testing_algorithm].g / 255.0;
        vertex.b = [[[frames firstObject] pointsArray] objectAtIndex:testing_algorithm].b / 255.0;
        
        if (i%1000 == 0) {
            NSLog(@"Location: %f, %f, %f\n Color: %f, %f, %f", vertex.x, vertex.y, vertex.z, vertex.r, vertex.g, vertex.b);
        }
        
        pointCloudVertices[i] = vertex;
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
    
    SCNNode *pointcloudNode = [SCNNode nodeWithGeometry:pointcloudGeometry];
    // pointcloudGeometry.firstMaterial.shaderModifiers = @{SCNShaderModifierEntryPointGeometry : @"gl_PointSize = 0.0000000000005"};
    // pointcloudNode.geometry = pointcloudGeometry;
    // pointcloudNode.geometry.shaderModifiers = @{SCNShaderModifierEntryPointGeometry : @"gl_PointSize = 2.0"};
    pointcloudNode.position = SCNVector3Make(0, 0, 0);
    // SCNAction *fadeParticle = [SCNAction fadeOpacityTo:0.0 duration:0.05f];
    // [pointcloudNode runAction:fadeParticle];
    
    [self.sceneView.scene.rootNode addChildNode:pointcloudNode];
}

-(void) playVideoPressed {
    [self.playVideo setImage:[UIImage imageNamed:@"redCircle"] forState:UIControlStateNormal];
    [self.playVideo setUserInteractionEnabled:NO];
    [self makePointCloud];
    
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



@end

