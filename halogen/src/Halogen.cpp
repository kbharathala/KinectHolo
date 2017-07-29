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

void subtractBackground(ofPixels *colorPixels, const ofFloatPixels &depthPixels, float low, float high) {
  // ofPixels paintedPixels;
  // paintedPixels.allocate(depthPixels.getWidth(), depthPixels.getHeight(), OF_IMAGE_COLOR_ALPHA);
  const float *data = depthPixels.getData();

  for (int i = 0; i < colorPixels->getWidth() * colorPixels->getHeight(); i += 1) {
    auto normalizedPixelValue = max(min(data[i], MAX_DEPTH), MIN_DEPTH);
    bool isPixelWithinThreshold = (normalizedPixelValue > low) && (normalizedPixelValue < high);
    if (!isPixelWithinThreshold) {
      colorPixels->setColor(i*4, ofColor(255, 255, 255, 255));
    }
    // paintedPixels.setColor(i * 4, isPixelWithinThreshold ? inColor : outColor);
  }

  // return paintedPixels;
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

  gui.setup();
  gui.setPosition(200, 200);
  gui.add(radius.setup("radius", 255, 25, 1000));
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

  ofLogNotice("Halogen") << "Face at (x=" << face.x << ", y=" << face.y << ") " << mmToFeet(faceDistance) << " ft away";

  subtractBackground(
    &colorPixels,
    depthPixels,
    faceDistance - (radius * 2),
    faceDistance + radius
  );
  colorTexture.loadData(colorPixels);
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

  // Only use largest face
  if (sortedFaces.size() > 0) {
    auto largestFace = sortedFaces[0];
    auto FACE_RESCALE = 0.5;
    auto scaledWidth = largestFace.width * FACE_RESCALE;
    auto scaledHeight = largestFace.height * FACE_RESCALE;

    face = ofRectangle(largestFace.x + (largestFace.width / 2*FACE_RESCALE), largestFace.y + (largestFace.height / 2*FACE_RESCALE), scaledWidth, scaledHeight);
  } else {
    ofLogNotice("Halogen", "No faces detected!");
  }
}

void Halogen::draw() {
  if (!hasData) {
    return;
  }
  colorTexture.draw(0,0);
  // drawBoundBox(face, ofColor::green);
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
