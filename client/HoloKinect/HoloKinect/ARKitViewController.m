//
//  ARKitViewController.m
//  HoloKinect
//
//  Created by Krishna Bharathala on 7/29/17.
//  Copyright © 2017 Krishna Bharathala. All rights reserved.
//

#import "ARKitViewController.h"
#import <SVProgressHUD/SVProgressHUD.h>

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
@property (nonatomic, strong) SCNNode *currNode;
@property (nonatomic, strong) ARPlaneAnchor *currAnchor;

@property (nonatomic) SCNNode *pointcloudNode;

@property (nonatomic) float xcenter;
@property (nonatomic) float ycenter;
@property (nonatomic) float zcenter;

@property(nonatomic) BOOL buttonPressed;

@property (nonatomic, strong) SCNNode *particle;

@property (nonatomic) BOOL isObjectPlaced;

@end

@implementation ARKitViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.count = 0;
    
    float sum_x = 0.0;
    float sum_y = 0.0;
    float sum_z = 0.0;
    
    NSMutableArray *frames = self.message.framesArray;

    for (int i = 0; i < 40000; i++) {
        
        PointCloudModel vertex;
        
        int testing_algorithm = i;
        
        vertex.x = ([[[frames firstObject] pointsArray] objectAtIndex:testing_algorithm].x / 15.0);
        vertex.y = [[[frames firstObject] pointsArray] objectAtIndex:testing_algorithm].y / -15.0;
        vertex.z = ([[[frames firstObject] pointsArray] objectAtIndex:testing_algorithm].z / 15.0);
        
        sum_x += vertex.x;
        sum_y += vertex.y;
        sum_z += vertex.z;
    }
    
    self.xcenter = sum_x / 40000;
    self.ycenter = sum_y / 40000;
    self.zcenter = sum_z / 40000;

    self.buttonPressed = NO;
    
    // setting up the sceneView
    self.sceneView = [[ARSCNView alloc] initWithFrame:self.view.frame];
    self.sceneView.delegate = self;
    [self.view addSubview: self.sceneView];
    
    // [self makePointCloud];
    
    //    [self setupLabel];
    
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
    if (self.buttonPressed) {
        NSLog(@"button pressed");
        [self resetPointCloud];
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
    
    self.playVideo = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.playVideo setFrame: CGRectMake(0, 0, 275, 40)];
    [self.playVideo setCenter:CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height * 6 / 7)];
    self.playVideo.backgroundColor = [UIColor whiteColor];
    [self.playVideo setTitle:@"Play video message now!" forState:UIControlStateNormal];
    self.playVideo.layer.cornerRadius = 8;
    [self.playVideo addTarget:self action:@selector(playVideoPressed) forControlEvents:UIControlEventTouchUpInside];
}

- (void) handleTimer:(NSTimer *)timer {
        [self resetPointCloud];
    // Hanlde the timed event.
}

- (void)didSwipe:(UISwipeGestureRecognizer*) swipe {
    
    if (swipe.direction == UISwipeGestureRecognizerDirectionRight) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.sceneView.scene removeAllParticleSystems];
    [self.sceneView.session pause];
}

- (void)resetPointCloud {
        SCNAction *fadeParticle = [SCNAction fadeOpacityTo:0.0 duration:0.05f];
        [self.pointcloudNode runAction:fadeParticle];
    [self makePointCloud];
}

- (void)makePointCloud
{
    NSUInteger numPoints = 40000;
    
    PointCloudModel pointCloudVertices[numPoints+10];
    NSMutableArray *frames = self.message.framesArray;
    
    NSLog(@"%lu", [[self.message.framesArray objectAtIndex:self.count].pointsArray count]);
    float sum_x = 0.0;
    float sum_y = 0.0;
    float sum_z = 0.0;
    for (int i = 0; i < numPoints; i++) {
        
        PointCloudModel vertex;
        
        int testing_algorithm = i;
        
        vertex.x = ([[[frames objectAtIndex:self.count] pointsArray] objectAtIndex:testing_algorithm].x / 15.0) + (self.particle.position.x - self.xcenter);
        vertex.y = [[[frames objectAtIndex:self.count] pointsArray] objectAtIndex:testing_algorithm].y / -15.0 + (self.particle.position.y - self.ycenter);
        vertex.z = [[[frames objectAtIndex:self.count] pointsArray] objectAtIndex:testing_algorithm].z / 15.0 + (self.particle.position.z - self.zcenter);
        
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
    // pointcloudGeometry.firstMaterial.shaderModifiers = @{SCNShaderModifierEntryPointGeometry : @"gl_PointSize = 0.0000000000005"};
    // pointcloudNode.geometry = pointcloudGeometry;
    //    pointcloudNode.geometry.shaderModifiers = @{SCNShaderModifierEntryPointGeometry : @"gl_PointSize = 2.0"};
    self.pointcloudNode.position = SCNVector3Make(0, 0, 0);
    //    SCNAction *fadeParticle = [SCNAction fadeOpacityTo:0.0 duration:0.05f];
    //    [pointcloudNode runAction:fadeParticle];
    
    [self.sceneView.scene.rootNode addChildNode:self.pointcloudNode];
    
    
}


//- (void)showAnchorPoint:(ARPlaneAnchor *)anchor onNode:(SCNNode *)node
//{
//    SCNNode *plane = [self planeFromAnchor:anchor];
//
//    SCNSphere *sphereGeometry = [SCNSphere sphereWithRadius:0.5];
//    SCNNode *sphereNode = [SCNNode nodeWithGeometry:sphereGeometry];
//    sphereNode.position = SCNVector3Make(0, 0, 3);
//
//    [plane addChildNode:sphereNode];
//    [node addChildNode:plane];
//}

#pragma mark - Node builders

#pragma mark - ARSCNViewDelegate

- (void)renderer:(id <SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor;
{
    
//    if (self.planeFound == NO)
//    {
//        if ([anchor isKindOfClass:[ARPlaneAnchor class]])
//        {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [SVProgressHUD showSuccessWithStatus:@"found the right anchor"];
//                self.planeFound = YES;
//
//                self.currNode = node;
//                self.currAnchor = (ARPlaneAnchor *) anchor;
//
////                [self showAnchorPoint:self.currAnchor onNode:self.currNode];
//
//                [node addChildNode:[self planeFromAnchor:(ARPlaneAnchor *)anchor]];
//
//                self.playVideo = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//                [self.playVideo setFrame: CGRectMake(0, 0, 275, 40)];
//                [self.playVideo setCenter:CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height * 6 / 7)];
//                self.playVideo.backgroundColor = [UIColor whiteColor];
//                [self.playVideo setTitle:@"Play video message now!" forState:UIControlStateNormal];
//                self.playVideo.layer.cornerRadius = 8;
//                [self.playVideo addTarget:self action:@selector(playVideoPressed) forControlEvents:UIControlEventTouchUpInside];
//                [self.sceneView addSubview:self.playVideo];
//            });
//        }
//    }
}

-(void) playVideoPressed {
    [self.playVideo removeFromSuperview];
    [NSTimer scheduledTimerWithTimeInterval:0.052f target:self selector:@selector(handleTimer:) userInfo:nil repeats:YES];
    self.buttonPressed = YES;
    [self makePointCloud];
}



@end

