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
    ofFloatPixels getSmallDepthPixels();
    ofFloatPixels getBigDepthPixels();

    // Camera registration parameters
    float fx, fy, cx, cy;

    void getPoint(int row, int col, float &x, float &y, float &z, uint8_t &r, uint8_t &g, uint8_t &b);

private:
    ofPixels colorPixelsBack;
    ofPixels colorPixelsFront;

    ofFloatPixels smallDepthPixelsBack;
    ofFloatPixels smallDepthPixelsFront;

    ofFloatPixels bigDepthPixelsBack;
    ofFloatPixels bigDepthPixelsFront;

    libfreenect2::FrameMap frames;
    libfreenect2::Freenect2 freenect2;
    libfreenect2::Freenect2Device *device = nullptr;
    libfreenect2::SyncMultiFrameListener *listener = nullptr;

    libfreenect2::Registration *registration = nullptr;
    libfreenect2::Frame *undistorted = nullptr;
    libfreenect2::Frame *registered = nullptr;
    libfreenect2::Frame *bigDepth = nullptr;
};
