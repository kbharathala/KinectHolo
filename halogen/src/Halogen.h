#pragma once

#include "ofBaseApp.h"
#include "ofImage.h"
#include "Kinect.h"
#include "ofxCv.h"
#include "ofxGui.h"
#include "proto/message.pb.h"
#undef Status
#undef None

class Halogen : public ofBaseApp {

private:
  void updateKinect();
  Kinect *kinect = nullptr;

  Message *msg = nullptr;

  ofPixels colorPixels;
  ofFloatPixels smallDepthPixels;
  ofFloatPixels bigDepthPixels;
  ofTexture colorTexture;

  ofRectangle face;
  float faceDistance;

  cv::CascadeClassifier face_cascade;
  bool hasData = false;

  void findFace();

  ofxFloatSlider radius;
  ofxPanel gui;

  bool isRecording = false;
  void startRecording();
  void stopRecording();
  void addFrame();
  void serializeToDisk();

  bool isSaving = false;

public:
  void setup();
  void update();
  void draw();
  ~Halogen();

  void keyPressed(int key);
  void keyReleased(int key);
  void mouseMoved(int x, int y );
  void mouseDragged(int x, int y, int button);
  void mousePressed(int x, int y, int button);
  void mouseReleased(int x, int y, int button);
  void mouseEntered(int x, int y);
  void mouseExited(int x, int y);
  void windowResized(int w, int h);
  void dragEvent(ofDragInfo dragInfo);
  void gotMessage(ofMessage msg);

};
