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

float averageDepth(ofFloatPixels bigDepthPixels) {
  auto numPixels = bigDepthPixels.size();
  float totalPixelValue = 0;
  const float *pixelData = bigDepthPixels.getData();
  for (size_t i = 0; i < numPixels; i++) {
    auto currentPixel = pixelData[i];
    auto normalizedPixelValue = max(min(currentPixel, MAX_DEPTH), MIN_DEPTH);
    totalPixelValue += normalizedPixelValue;
  }
  auto average = totalPixelValue / numPixels;
  return average;
}

void subtractBackground(ofPixels *colorPixels, const ofFloatPixels &depthPixels, float low, float high) {
  const float *data = depthPixels.getData();

  for (int i = 0; i < colorPixels->getWidth() * colorPixels->getHeight(); i += 1) {
    auto normalizedPixelValue = max(min(data[i], MAX_DEPTH), MIN_DEPTH);
    bool isPixelWithinThreshold = (normalizedPixelValue > low) && (normalizedPixelValue < high);
    if (!isPixelWithinThreshold) {
      colorPixels->setColor(i*4, ofColor(0, 0, 0, 0));
    }
  }
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
  gui.add(radius.setup("radius", 255, 25, 350));

  bannerImage.load("../assets/wait.png");
}

void Halogen::update() {
  if (!this->kinect->isConnected) return;

  if (isSaving) return;

  TS_START("[Kinect] update frames");
  colorPixels = this->kinect->getColorPixels();
  smallDepthPixels = this->kinect->getSmallDepthPixels();
  bigDepthPixels = this->kinect->getBigDepthPixels();
  TS_STOP("[Kinect] update frames");
  hasData = (colorPixels.size() > 0 && smallDepthPixels.size() > 0 && bigDepthPixels.size() > 0);

  if (!hasData) {
    return;
  }
  colorTexture.loadData(colorPixels);

  if (!isRecording) {
    findFace();

    ofFloatPixels faceDepthPixels;
    bigDepthPixels.cropTo(faceDepthPixels, face.x, face.y, face.width, face.height);
    faceDistance = averageDepth(faceDepthPixels);

    ofLogNotice("Halogen") << "Faces at (x=" << face.x << ", y=" << face.y << ", w=" << face.width << ", h=" << face.height << ") " << mmToFeet(faceDistance) << " ft away";
  }

  ofPixels newColorPixels = colorPixels;
  subtractBackground(
    &colorPixels,
    bigDepthPixels,
    faceDistance - (radius * 2),
    faceDistance + radius
  );
  colorTexture.loadData(colorPixels);

  if (isRecording) {
    addFrame();
  }
}

void Halogen::findFace() {
  std::vector<cv::Rect> faces;
  TS_START("face detect");
  face_cascade.detectMultiScale(ofxCv::toCv(colorPixels), faces, 1.1, 2, 0|CV_HAAR_SCALE_IMAGE, cv::Size(90, 90));
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
  drawBoundBox(face, ofColor::green);

  if (bannerImage.isAllocated()) {
    bannerImage.draw(0,0);
  }
}

void Halogen::serializeToDisk() {
  ofLogNotice("Halogen", "serializeToDisk");
  fstream output("/home/hacker/KinectHolo/server/files/" + ofGetTimestampString() + ".hologram", ios::out | ios::trunc | ios::binary);
  msg->SerializeToOstream(&output);
}

void Halogen::addFrame() {
  isSaving = true;
  ofLogNotice("Halogen", "saving frame");

  auto frame = msg->add_frames();

  auto low = faceDistance - (radius * 2);
  auto high = faceDistance + radius;

  float xMeters, yMeters, zMeters;
  uint8_t r, g, b;
  // depthPixels 1920x1082 "big depth"
  for (auto curHeight = 0; curHeight < smallDepthPixels.getHeight(); curHeight++) {
    for (auto curWidth = 0; curWidth < smallDepthPixels.getWidth(); curWidth++) {
      // getPoint(r, c) indexes into small depth
      kinect->getPoint(curHeight, curWidth, xMeters, yMeters, zMeters, r, g, b);
      float zMm = zMeters * 1000;

      auto normalizedPixelValue = max(min(zMm, MAX_DEPTH), MIN_DEPTH);
      bool isPixelWithinThreshold = (normalizedPixelValue > low) && (normalizedPixelValue < high);
      if (isPixelWithinThreshold) {
        auto pt = frame->add_points();
        pt->set_x(xMeters);
        pt->set_y(yMeters);
        pt->set_z(zMeters);
        pt->set_r((uint32_t) r);
        pt->set_g((uint32_t) g);
        pt->set_b((uint32_t) b);
      }
    }
  }

  frame->set_timestamp(0);
  ofLogNotice() << "# of points " << frame->points_size();

  isSaving = false;
}

void Halogen::startRecording() {
  isRecording = true;
  msg = new Message();
  bannerImage.load("../assets/record.png");
}

void Halogen::stopRecording() {
  isRecording = false;
  serializeToDisk();
  bannerImage.load("../assets/wait.png");
}

Halogen::~Halogen() {
  ofLogNotice("Halogen", "Shutting down...");
  kinect->waitForThread(true);
  kinect->disconnect();
}

void Halogen::keyReleased(int key) {
  if (key == ' ') {
    if (isRecording) stopRecording();
    else startRecording();
  }
  else if (key == 'f') {
    addFrame();
  }
}

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
