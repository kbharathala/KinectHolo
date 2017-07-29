#include "ofAppRunner.h"
#include "HoloApp.h"

void HoloApp::setup() {
  kinect = new Kinect();

  bool didConnectSuccessfully = kinect->connect();
  if (!didConnectSuccessfully) {
      std::exit(1);
  }

}

void HoloApp::update() {
  if (!this->kinect->isConnected) return;

  colorPixels = this->kinect->getColorPixels();
  depthPixels = this->kinect->getDepthPixels();
  hasData = (colorPixels.size() > 0);

  if (hasData) {
    colorTexture.loadData(colorPixels);
  }
}

void HoloApp::draw() {
  if (!hasData) {
    return;
  }
  colorTexture.draw(0,0);
}

HoloApp::~HoloApp() {
  ofLogNotice("HoloApp", "Shutting down...");
  kinect->waitForThread(true);
  kinect->disconnect();
}

void HoloApp::keyReleased(int key) {}
void HoloApp::keyPressed(int key) {}
void HoloApp::mouseMoved(int x, int y) {}
void HoloApp::mouseDragged(int x, int y, int button) {}
void HoloApp::mousePressed(int x, int y, int button) {}
void HoloApp::mouseReleased(int x, int y, int button) {}
void HoloApp::mouseEntered(int x, int y) {}
void HoloApp::mouseExited(int x, int y) {}
void HoloApp::windowResized(int w, int h) {}
void HoloApp::gotMessage(ofMessage msg) {}
void HoloApp::dragEvent(ofDragInfo dragInfo) {}
