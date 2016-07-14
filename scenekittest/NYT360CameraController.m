//
//  Controls.m
//  scenekittest
//
//  Created by Thiago on 7/13/16.
//  Copyright © 2016 The New York Times. All rights reserved.
//

#import "NYT360CameraController.h"

#define CLAMP(x, low, high) (((x) > (high)) ? (high) : (((x) < (low)) ? (low) : (x)))

CGPoint subtractPoints(CGPoint a, CGPoint b) {
    return CGPointMake(b.x - a.x, b.y - a.y);
}

@interface NYT360CameraController ()

@property (nonatomic) SCNView *view;
@property (nonatomic) UIGestureRecognizer *panRecognizer;
@property (nonatomic) CMMotionManager *motionManager;
@property (nonatomic) SCNNode *camera;

@property (nonatomic, assign) CGPoint rotateStart;
@property (nonatomic, assign) CGPoint rotateCurrent;
@property (nonatomic, assign) CGPoint rotateDelta;
@property (nonatomic, assign) CGPoint currentPosition;

@end

@implementation NYT360CameraController

- (id)initWithView:(SCNView *)view {
    self = [super init];
    if (self) {
        _camera = view.pointOfView;
        _view = view;
        _currentPosition = CGPointMake(0, 0);
        
        _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        _panRecognizer.delegate = self;
        [_view addGestureRecognizer:_panRecognizer];
        
        _motionManager = [[CMMotionManager alloc] init];
        _motionManager.deviceMotionUpdateInterval = (1.f / 60.f);
    }
    
    return self;
}

- (void)startMotionUpdates {
    [self.motionManager startDeviceMotionUpdates];
}

- (void)stopMotionUpdates {
    [self.motionManager stopDeviceMotionUpdates];
}

- (void)updateFromDeviceMotion {
#ifdef DEBUG
    if (!self.motionManager.deviceMotionActive) {
        NSLog(@"Warning: %@ called while %@ is not receiving motion updates", NSStringFromSelector(_cmd), NSStringFromClass(self.class));
    }
#endif
    
    CMRotationRate rotationRate = self.motionManager.deviceMotion.rotationRate;
    CGPoint position = CGPointMake(self.currentPosition.x + rotationRate.y * 0.02,
                                   self.currentPosition.y - rotationRate.x * 0.02 * -1);
    position.y = CLAMP(position.y, -M_PI / 2, M_PI / 2);
    self.currentPosition = position;
    
    self.camera.eulerAngles = SCNVector3Make(self.currentPosition.y, self.currentPosition.x, 0);
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:self.view];
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            self.rotateStart = point;
            break;
        case UIGestureRecognizerStateChanged:
            self.rotateCurrent = point;
            self.rotateDelta = subtractPoints(self.rotateStart, self.rotateCurrent);
            self.rotateStart = self.rotateCurrent;
        
            CGPoint position = CGPointMake(self.currentPosition.x + 2 * M_PI * self.rotateDelta.x / self.view.frame.size.width * 0.5,
                                           self.currentPosition.y + 2 * M_PI * self.rotateDelta.y / self.view.frame.size.height * 0.4);
            position.y = CLAMP(position.y, -M_PI / 2, M_PI / 2);
            self.currentPosition = position;
        
            self.camera.eulerAngles = SCNVector3Make(self.currentPosition.y, self.currentPosition.x, 0);
            break;
        default:
            break;
    }
}

@end
