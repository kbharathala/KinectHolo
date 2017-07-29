#include <math.h>
#include "ofAppRunner.h"
#include "Halogen.h"
#include "ofxTimeMeasurements.h"

float MIN_DEPTH = 0;
float MAX_DEPTH = 10 * 1000;
float mmToFeet(float millimeters) { return millimeters * 0.00328084; }

void drawBoundBox(ofRectangle r, ofColor color) {
  ofNoFill();
  ofSetLineWidth(6.0);
  ofSetColor(color);
  ofDrawRectRounded(r, 30.0);
  ofSetColor(ofColor::white);
}

float averageDepth(ofFloatPixels depthPixels) {
  auto numPixels = depthPixels.size();
  float totalPixelValue = 0;
  const float *pixelData = depthPixels.getData();
  for (size_t i = 0; i < numPixels; i++) {
    auto currentPixel = pixelData[i];
    auto normalizedPixelValue = max(min(currentPixel, MAX_DEPTH), MIN_DEPTH);
    totalPixelValue += normalizedPixelValue;
  }
  auto average = totalPixelValue / numPixels;
  return average;
}


void Halogen::setup() {

  // Set up Kinect
  kinect = new Kinect();

  bool didConnectSuccessfully = kinect->connect();
  if (!didConnectSuccessfully) {
      std::exit(1);
  }

  // Set up face detector
  face_cascade.load("assets/haarcascade_frontalface_default.xml");
}

void Halogen::update() {
  if (!this->kinect->isConnected) return;

  TS_START("[Kinect] update frames");
  colorPixels = this->kinect->getColorPixels();
  depthPixels = this->kinect->getDepthPixels();
  TS_STOP("[Kinect] update frames");
  hasData = (colorPixels.size() > 0);

  if (!hasData) {
    return;
  }
  colorTexture.loadData(colorPixels);
  findFace();

  ofFloatPixels faceDepthPixels;
  depthPixels.cropTo(faceDepthPixels, face.x, face.y, face.width, face.height);
  float faceDistance = averageDepth(faceDepthPixels);

  ofLogNotice("Halogen") << "Distance of face: " << mmToFeet(faceDistance) << " ft";
}

void Halogen::findFace() {
  std::vector<cv::Rect> faces;
  TS_START("face detect");
  face_cascade.detectMultiScale(ofxCv::toCv(colorPixels), faces, 1.1, 2, 0|CV_HAAR_SCALE_IMAGE, cv::Size(60, 60));
  TS_STOP("face detect");

  auto sortedFaces = faces;
  std::sort(
    sortedFaces.begin(),
    sortedFaces.end(),
    [] (const cv::Rect& a, const cv::Rect& b) { return a.area() > b.area(); }
  );

  // Only use biggest face
  if (sortedFaces.size() > 0) {
     face = ofxCv::toOf(sortedFaces[0]);
     ofLogNotice("Halogen") << "Face at (" << face.x << ", " << face.y << ")";
  } else {
    ofLogNotice("Halogen", "No faces detected!");
  }
}

void Halogen::draw() {
  if (!hasData) {
    return;
  }
  colorTexture.draw(0,0);
  drawBoundBox(face, ofColor::green);
  // drawBoundBox(ofRectangle(500, 500, 100, 100), ofColor::green);
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