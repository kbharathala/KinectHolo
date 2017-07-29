#pragma once
#include <libfreenect2/libfreenect2.hpp>
#include <libfreenect2/frame_listener_impl.h>
#include <libfreenect2/registration.h>
#include <libfreenect2/logger.h>
#include "ofThread.h"
#undef Status
#undef None
#include "ofPixels.h"

class Kinect : public ofThread {

public:
    Kinect();
    void threadedFunction();
    bool connect();
    void disconnect();
    bool isConnected;

    ofPixels getColorPixels();
    ofFloatPixels getDepthPixels();

    // Camera registration parameters
    float fx, fy, cx, cy;

private:
    ofPixels colorPixelsBack;
    ofPixels colorPixelsFront;

    ofFloatPixels depthPixelsBack;
    ofFloatPixels depthPixelsFront;

    libfreenect2::FrameMap frames;
    libfreenect2::Freenect2 freenect2;
    libfreenect2::Freenect2Device *device = NULL;
    libfreenect2::SyncMultiFrameListener *listener = NULL;

    libfreenect2::Registration *registration = NULL;
    libfreenect2::Frame *undistorted = NULL;
    libfreenect2::Frame *registered = NULL;
    libfreenect2::Frame *bigDepth = NULL;
};
