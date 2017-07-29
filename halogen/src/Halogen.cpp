#include "ofAppRunner.h"
#include "Halogen.h"

void Halogen::setup() {

  // Set up Kinect
  kinect = new Kinect();

  bool didConnectSuccessfully = kinect->connect();
  if (!didConnectSuccessfully) {
      std::exit(1);
  }

  // Set up face detector
  face_cascade.load("haarcascade_frontalface_default.xml");
}

void Halogen::update() {
  if (!this->kinect->isConnected) return;

  colorPixels = this->kinect->getColorPixels();
  depthPixels = this->kinect->getDepthPixels();
  hasData = (colorPixels.size() > 0);

  if (!hasData) {
    return;
  }
  colorTexture.loadData(colorPixels);

  std::vector<cv::Rect> faces;
  // face_cascade.detectMultiScale(
  //   ofxCv::toCv(colorPixels), faces, 1.1, 2, 0|CV_HAAR_SCALE_IMAGE, cv::Size(30, 30));
}

void Halogen::draw() {
  if (!hasData) {
    return;
  }
  colorTexture.draw(0,0);
}

Halogen::~Halogen() {
  ofLogNotice("Halogen", "Shutting down...");
  kinect->waitForThread(true);
  kinect->disconnect();
}

void Halogen::keyReleased(int key) {}
void Halogen::keyPressed(int key) {}
void Halogen::mouseMoved(int x, int y) {}
void Halogen::mouseDragged(int x, int y, int button) {}
void Halogen::mousePressed(int x, int y, int button) {}
void Halogen::mouseReleased(int x, int y, int button) {}
void Halogen::mouseEntered(int x, int y) {}
void Halogen::mouseExited(int x, int y) {}
void Halogen::windowResized(int w, int h) {}
void Halogen::gotMessage(ofMessage msg) {}
void Halogen::dragEvent(ofDragInfo dragInfo) {}
