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
    libfreenect2::Freenect2Device *device = nullptr;
    libfreenect2::SyncMultiFrameListener *listener = nullptr;

    libfreenect2::Registration *registration = nullptr;
    libfreenect2::Frame *undistorted = nullptr;
    libfreenect2::Frame *registered = nullptr;
    libfreenect2::Frame *bigDepth = nullptr;
};
