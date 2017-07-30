//
//  ARKitViewController.m
//  HoloKinect
//
//  Created by Krishna Bharathala on 7/29/17.
//  Copyright © 2017 Krishna Bharathala. All rights reserved.
//

#import "ARKitViewController.h"
@import SceneKit;

typedef struct PointCloudModel
{
    float x, y, z, r, g, b;
} PointCloudModel;

@interface ARKitViewController () <ARSCNViewDelegate>

@property (nonatomic, strong) ARSCNView *sceneView;
@property (nonatomic, strong) SCNScene *scene;
@property (nonatomic, strong) UILabel *label;

@property (nonatomic) BOOL planeFound;

@end

@implementation ARKitViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    [self setupLabel];
    [self setupSceneView];
    
    self.sceneView = [[ARSCNView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview: _sceneView];
    
    [self makePointCloud];
    [NSTimer scheduledTimerWithTimeInterval:0.05f target:self selector:@selector(handleTimer:) userInfo:nil repeats:YES];

    
//    SCNNode *cubeNode = [SCNNode node];
//    cubeNode.geometry = [SCNBox boxWithWidth:0.1 height:0.1 length:0.1 chamferRadius:0];
//    cubeNode.position = SCNVector3Make(0, 0, -0.2);
//
//    [self.sceneView.scene.rootNode addChildNode:cubeNode];
    

    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe:)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:rightSwipe];
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
//    [self setupScene];
    [self startSession];
    
    // Setting up the navigation bar
    [self.navigationController.navigationBar setHidden:YES];
    self.navigationController.navigationItem.backBarButtonItem = nil;
}

- (void)viewWillDisappear:(BOOL)animated
{

    [super viewWillDisappear:animated];
    
    [self.sceneView.scene removeAllParticleSystems];
    
    [self.sceneView.session pause];
    
}
- (void)setupSceneView
{
    self.sceneView.delegate = self;
    self.sceneView.autoenablesDefaultLighting = YES;
}

//- (void)setupScene
//{
//    SCNScene *scene = [SCNScene scene];
//    self.myView.scene = scene;
//
//    SCNNode *cameraNode = [SCNNode node];
//    cameraNode.camera = [SCNCamera camera];
//    cameraNode.position = SCNVector3Make(0, 12, 30);
//    cameraNode.rotation = SCNVector4Make(1, 0, 0, -sin(12.0/30.0));
//
//    [scene.rootNode addChildNode:cameraNode];
//}

- (void)startSession
{
    ARWorldTrackingSessionConfiguration *configuration = [ARWorldTrackingSessionConfiguration new];
    configuration.planeDetection = ARPlaneDetectionHorizontal;
    configuration.worldAlignment = ARWorldAlignmentGravityAndHeading;
    
//    for (SCNNode *node in [self.sceneView.scene.rootNode childNodes]) {
//        [node removeFromParentNode];
//    }
    
    [self.sceneView.session runWithConfiguration:configuration];
}

- (void)resetPointCloud
{
    
    [self makePointCloud];
}

- (void)makePointCloud
{
    NSUInteger numPoints = 30000;

    int randomPosUL = 2;
    int scaleFactor = 1000;

    PointCloudModel pointCloudVertices[numPoints];

    for (NSUInteger i = 0; i < numPoints; i++) {

        PointCloudModel vertex;
    
        float x = (arc4random_uniform(randomPosUL * 2 * scaleFactor));
//        (float) rand() / (RAND_MAX);
        float y = (arc4random_uniform(randomPosUL * 2 * scaleFactor));
        float z = (arc4random_uniform(randomPosUL * 2 * scaleFactor));
//        (arc4random_uniform(randomPosUL * 2 * scaleFactor));

        vertex.x = (x - randomPosUL * scaleFactor) / scaleFactor;
        vertex.y = (y - randomPosUL * scaleFactor) / scaleFactor;
        vertex.z = (z - randomPosUL * scaleFactor) / scaleFactor;
        
//        vertex.x = (float) (rand() / RAND_MAX);
//        vertex.y = (float) (rand() / RAND_MAX);
//        vertex.z = (float) (rand() / RAND_MAX);

        vertex.r = arc4random_uniform(255) / 255.0;
        vertex.g = arc4random_uniform(255) / 255.0;
        vertex.b = arc4random_uniform(255) / 255.0;
        

        pointCloudVertices[i] = vertex;
        
//        SCNMaterial *particleMaterial = [SCNMaterial new];
//        particleMaterial.diffuse.contents = [UIColor colorWithRed:vertex.r green:vertex.g blue:vertex.b alpha:1];
//
//        SCNGeometry *particleGeometry = [SCNSphere sphereWithRadius:0.003];
//        particleGeometry.firstMaterial = particleMaterial;
//        SCNNode *particle = [SCNNode nodeWithGeometry:particleGeometry];
//        particle.position = SCNVector3Make(vertex.x, vertex.y, vertex.z);
//        SCNAction *fadeParticle = [SCNAction fadeOpacityTo:0.0 duration:0.05f];
//        [particle runAction:fadeParticle];
//        [self.sceneView.scene.rootNode addChildNode:particle];
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
//    pointcloudGeometry.firstMaterial.shaderModifiers = @{SCNShaderModifierEntryPointGeometry : @"gl_PointSize = 0.0000000000005"};
    pointcloudNode.geometry = pointcloudGeometry;
//    pointcloudNode.geometry.shaderModifiers = @{SCNShaderModifierEntryPointGeometry : @"gl_PointSize = 2.0"};
    pointcloudNode.position = SCNVector3Make(0, 0, -0.2);
    SCNAction *fadeParticle = [SCNAction fadeOpacityTo:0.0 duration:0.05f];
    [pointcloudNode runAction:fadeParticle];
    
//
//    pointcloudGeometry.firstMaterial.shaderModifiers =[SCNShaderModifierEntryPointGeometry] [SCNShaderModifierEntryPointGeometry:"gl_PointSize = 2.5;"];
    
//    pointcloudGeometry.firstMaterial.shaderModifiers = [SCNShaderModifierEntryPoint.geometry: "gl_PointSize = 2.5;"]
    [self.sceneView.scene.rootNode addChildNode:pointcloudNode];


}

//- (void)setupLabel
//{
//    self.label = [[UILabel alloc] initWithFrame:CGRectMake(10, self.view.frame.size.height * 0.5, self.view.frame.size.width - 20, 40)];
//    self.label.numberOfLines = 0;
//    self.label.textAlignment = NSTextAlignmentCenter;
//    self.label.font = [UIFont systemFontOfSize:16];
//    [self.view addSubview:self.label];
//    self.label.text = @"FIND A DANCEFLOOR.";
//}



- (void)showDiscoBallWithAncor:(ARPlaneAnchor *)anchor onNode:(SCNNode *)node
{
//    SCNNode *plane = [self planeFromAnchor:anchor];
//    SCNNode *discoBall = [self discoBall];
//
//    NSArray *colors = @[[UIColor yellowColor],
//                        [UIColor redColor],
//                        [UIColor greenColor],
//                        [UIColor blueColor],
//                        [UIColor purpleColor],
//                        [UIColor magentaColor],
//                        [UIColor orangeColor],
//                        [UIColor cyanColor]];
//
//    for (NSInteger i = 0; i < 30; i++) {
//        UIColor *color = colors[arc4random() % colors.count];
//        SCNNode *lightBeam = [self lightBeamOfColor:color];
//        lightBeam.rotation = SCNVector4Make([self randomFloat], [self randomFloat], [self randomFloat], (M_PI * 0.5) * (CGFloat)((arc4random() % 3) + 1));
//        [discoBall addChildNode:lightBeam];
//    }
    
//    CABasicAnimation *rotation = [self rotationAnimation];
//    [discoBall addAnimation:rotation forKey:@"rotation"];
//    [plane addChildNode:discoBall];
//    [node addChildNode:plane];
}

#pragma mark - Utils

#pragma mark - Node builders

- (SCNNode *)planeFromAnchor:(ARPlaneAnchor *)anchor
{
    SCNPlane *plane = [SCNPlane planeWithWidth:anchor.extent.x height:anchor.extent.z];
    plane.firstMaterial.diffuse.contents = [UIColor clearColor];
    SCNNode *planeNode = [SCNNode nodeWithGeometry:plane];
    planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z);
    planeNode.transform = SCNMatrix4MakeRotation(-M_PI * 0.5, 1, 0, 0);
    
    return planeNode;
}

#pragma mark - ARSCNViewDelegate

- (void)renderer:(id <SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor;
{
//    if (self.planeFound == NO)
//    {
//        if ([anchor isKindOfClass:[ARPlaneAnchor class]])
//        {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                self.planeFound = YES;
//                self.label.text = @"DANCEFLOOR FOUND. LET'S BOOGIE";
//
//                UIView *overlay = [[UIView alloc] initWithFrame:self.view.frame];
//                overlay.backgroundColor = [UIColor blackColor];
//                overlay.alpha = 0;
//                [self.view insertSubview:overlay belowSubview:self.label];
//
//                [UIView animateWithDuration:1.5 delay:2 options:UIViewAnimationOptionCurveEaseIn animations:^{
//                    self.label.alpha = 0;
//                    overlay.alpha = 0.5;
//                } completion:^(BOOL finished) {
//                    ARPlaneAnchor *planeAnchor = (ARPlaneAnchor *)anchor;
//                    [self showDiscoBallWithAncor:planeAnchor onNode:node];
//                }];
//            });
//        }
//    }
}

- (void)session:(ARSession *)session didFailWithError:(NSError *)error
{
}

- (void)sessionWasInterrupted:(ARSession *)session
{
}

- (void)sessionInterruptionEnded:(ARSession *)session
{
}



@end
