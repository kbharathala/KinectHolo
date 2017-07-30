#include "Halogen.h"
#include "ofUtils.h"
#include "ofAppRunner.h"
#include "ofxTimeMeasurements.h"

int main() {
  ofSetupOpenGL(1920, 1080, OF_WINDOW);

  ofSetFrameRate(20);
  ofSetVerticalSync(false);
  ofSetDataPathRoot("data");
  ofSetWindowTitle("Halogen");
  ofSetFullscreen(true);

  TIME_SAMPLE_SET_FRAMERATE(30.0f);
  TIME_SAMPLE_GET_INSTANCE()->setUiScale(2.0);
  TIME_SAMPLE_DISABLE();

  ofRunApp(new Halogen());
}
