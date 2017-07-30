#include "Kinect.h"

Kinect::Kinect() {
  libfreenect2::setGlobalLogger(libfreenect2::createConsoleLogger(libfreenect2::Logger::Nada));
  isConnected = false;
}

// returns true if successful
bool Kinect::connect() {
  if (freenect2.enumerateDevices() == 0) {
    std::cerr << "Kinect not plugged in" << std::endl;
    return false;
  }

  libfreenect2::PacketPipeline *pipeline = new libfreenect2::OpenCLPacketPipeline();

  device = freenect2.openDevice(freenect2.getDefaultDeviceSerialNumber(), pipeline);
  if (device == NULL) {
    std::cerr << "Failure opening Kinect device" << std::endl;
    return false;
  }

  libfreenect2::Freenect2Device::Config config;
  config.MaxDepth = 10;
  device->setConfiguration(config);

  std::cout << "device serial: " << device->getSerialNumber() << std::endl;

  int types = libfreenect2::Frame::Color | libfreenect2::Frame::Ir | libfreenect2::Frame::Depth;
  listener = new libfreenect2::SyncMultiFrameListener(types);
  libfreenect2::FrameMap frames;

  device->setColorFrameListener(listener);
  device->setIrAndDepthFrameListener(listener);

  if (!device->start()) {
    std::cerr << "Failure starting Kinect device" << std::endl;
    return false;
  }

  registration = new libfreenect2::Registration(
    device->getIrCameraParams(),
    device->getColorCameraParams()
  );

  auto colorParams = device->getColorCameraParams();
  fx = colorParams.fx;
  fy = colorParams.fy;
  cx = colorParams.cx;
  cy = colorParams.cy;

  undistorted = new libfreenect2::Frame(512, 424, 4);
  registered = new libfreenect2::Frame(512, 424, 4);
  bigDepth = new libfreenect2::Frame(1920, 1080 + 2, 4);

  startThread(true);
  isConnected = true;
  return true;
}

void Kinect::disconnect() {
  listener->release(frames);
  device->stop();
  device->close();
  delete registration;
  delete listener;
  listener = NULL;
  isConnected = false;
}

void Kinect::getPoint(int row, int col, float &x, float &y, float &z, uint8_t &r, uint8_t &g, uint8_t &b) {
  float rgb;
  registration->getPointXYZRGB(undistorted, registered, row, col, x, y, z, rgb);
  const uint8_t *p = reinterpret_cast<uint8_t*>(&rgb);
  b = p[0];
  g = p[1];
  r = p[2];
}

ofPixels Kinect::getColorPixels() {
  return colorPixelsFront;
}

ofFloatPixels Kinect::getDepthPixels() {
  return depthPixelsFront;
}

void Kinect::threadedFunction() {
    while (isThreadRunning()) {
      // ofLogNotice("HoloApp") << "processed kinect frame";
      if (!listener->waitForNewFrame(frames, 2*1000)) {
        std::cerr << "Timed out!" << std::endl;
        break;
      }
      libfreenect2::Frame *color = frames[libfreenect2::Frame::Color];
      // libfreenect2::Frame *ir = frames[libfreenect2::Frame::Ir];
      libfreenect2::Frame *depth = frames[libfreenect2::Frame::Depth];

      mutex.lock();

      registration->apply(color, depth, undistorted, registered, true, bigDepth);

      colorPixelsBack.setFromPixels(color->data, color->width, color->height, OF_PIXELS_BGRA);
      // unalignedDepthPixelsBack.setFromPixels(reinterpret_cast<float *>(depth->data), ir->width, ir->height, OF_PIXELS_GRAY);
      depthPixelsBack.setFromPixels(reinterpret_cast<float *>(bigDepth->data), bigDepth->width, bigDepth->height, OF_PIXELS_GRAY);

      colorPixelsFront.swap(colorPixelsBack);
      depthPixelsFront.swap(depthPixelsBack);

      mutex.unlock();

      listener->release(frames);
    }
}
