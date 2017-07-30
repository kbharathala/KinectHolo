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

@property (nonatomic) BOOL planeFound;

@end

@implementation ARKitViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.count = 0;
    
    // setting up the sceneView
    self.sceneView = [[ARSCNView alloc] initWithFrame:self.view.frame];
    self.sceneView.delegate = self;
    [self.view addSubview: self.sceneView];
    
    [self makePointCloud];
    
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
    
    UITapGestureRecognizer *singleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(handleSingleTap:)];
    [self.view addGestureRecognizer:singleFingerTap];
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer
{
    CGPoint location = [recognizer locationInView:[recognizer.view superview]];
    
    //Do stuff here...
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Setting up the navigation bar
    [self.navigationController.navigationBar setHidden:YES];
    self.navigationController.navigationItem.backBarButtonItem = nil;
    
    // setting up the scene
//    self.scene = [SCNScene new];
//    self.sceneView.scene = self.scene;
    
    // starting the session
    ARWorldTrackingSessionConfiguration *configuration = [ARWorldTrackingSessionConfiguration new];
    configuration.planeDetection = ARPlaneDetectionHorizontal;
    configuration.worldAlignment = ARWorldAlignmentGravityAndHeading;
    [self.sceneView.session runWithConfiguration:configuration];
}

- (void) handleTimer:(NSTimer *)timer {
    //    [self resetPointCloud];
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
    [self makePointCloud];
}

- (void)makePointCloud
{
    NSUInteger numPoints = 40000;
    
    PointCloudModel pointCloudVertices[numPoints+10];
    NSMutableArray *frames = self.message.framesArray;
    
    NSLog(@"%lu", [[self.message.framesArray firstObject].pointsArray count]);
    for (int i = 0; i < numPoints; i++) {
        
        PointCloudModel vertex;
        
        int testing_algorithm = i*4;
        
        vertex.x = [[[frames firstObject] pointsArray] objectAtIndex:testing_algorithm].x / 15.0;
        vertex.y = [[[frames firstObject] pointsArray] objectAtIndex:testing_algorithm].y / -15.0;
        vertex.z = [[[frames firstObject] pointsArray] objectAtIndex:testing_algorithm].z / 15.0;
        
        vertex.r = [[[frames firstObject] pointsArray] objectAtIndex:testing_algorithm].r / 255.0;
        vertex.g = [[[frames firstObject] pointsArray] objectAtIndex:testing_algorithm].g / 255.0;
        vertex.b = [[[frames firstObject] pointsArray] objectAtIndex:testing_algorithm].b / 255.0;
        
        if (i%1000 == 0) {
            NSLog(@"Location: %f, %f, %f\n Color: %f, %f, %f", vertex.x, vertex.y, vertex.z, vertex.r, vertex.g, vertex.b);
        }
        
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
    // pointcloudGeometry.firstMaterial.shaderModifiers = @{SCNShaderModifierEntryPointGeometry : @"gl_PointSize = 0.0000000000005"};
    // pointcloudNode.geometry = pointcloudGeometry;
    //    pointcloudNode.geometry.shaderModifiers = @{SCNShaderModifierEntryPointGeometry : @"gl_PointSize = 2.0"};
    pointcloudNode.position = SCNVector3Make(0, 0, 0);
    //    SCNAction *fadeParticle = [SCNAction fadeOpacityTo:0.0 duration:0.05f];
    //    [pointcloudNode runAction:fadeParticle];
    
    [self.sceneView.scene.rootNode addChildNode:pointcloudNode];
    
    
}



- (void)showAnchorPoint:(ARPlaneAnchor *)anchor onNode:(SCNNode *)node
{
    SCNNode *plane = [self planeFromAnchor:anchor];
    
    SCNSphere *sphereGeometry = [SCNSphere sphereWithRadius:0.5];
    SCNNode *sphereNode = [SCNNode nodeWithGeometry:sphereGeometry];
    sphereNode.position = SCNVector3Make(0, 0, 3);
    
    [plane addChildNode:sphereNode];
    [node addChildNode:plane];
}

#pragma mark - Node builders

- (SCNNode *)planeFromAnchor:(ARPlaneAnchor *)anchor
{
    
    NSLog(@"i'm being called here");
    
    SCNPlane *plane = [SCNPlane planeWithWidth:anchor.extent.x height:anchor.extent.z];
    // plane.firstMaterial.diffuse.contents = [UIColor redColor];
    SCNNode *planeNode = [SCNNode nodeWithGeometry:plane];
    planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z);
    planeNode.transform = SCNMatrix4MakeRotation(-M_PI * 0.5, 1, 0, 0);

    return planeNode;
}

#pragma mark - ARSCNViewDelegate

- (void)renderer:(id <SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor;
{
    
    if (self.planeFound == NO)
    {
        if ([anchor isKindOfClass:[ARPlaneAnchor class]])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showSuccessWithStatus:@"found the right anchor"];
                self.planeFound = YES;
                
                self.currNode = node;
                self.currAnchor = (ARPlaneAnchor *) anchor;
                
//                [self showAnchorPoint:self.currAnchor onNode:self.currNode];
                
                [node addChildNode:[self planeFromAnchor:(ARPlaneAnchor *)anchor]];
                
                self.playVideo = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                [self.playVideo setFrame: CGRectMake(0, 0, 275, 40)];
                [self.playVideo setCenter:CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height * 6 / 7)];
                self.playVideo.backgroundColor = [UIColor whiteColor];
                [self.playVideo setTitle:@"Play video message now!" forState:UIControlStateNormal];
                self.playVideo.layer.cornerRadius = 8;
                [self.playVideo addTarget:self action:@selector(playVideoPressed) forControlEvents:UIControlEventTouchUpInside];
                [self.sceneView addSubview:self.playVideo];
            });
        }
    }
}

-(void) playVideoPressed {
    [self.playVideo removeFromSuperview];
    [self makePointCloud];
}



@end

