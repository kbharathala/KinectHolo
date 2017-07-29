cmake_minimum_required(VERSION 3.0)
set(APP KinectHoloClient)

project(${APP} CXX)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-deprecated-declarations")

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules/")
set(OF_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/of" CACHE PATH "The root directory of ofnode/of project")
include(${OF_ROOT}/openFrameworks.cmake)

option(COTIRE "Use cotire" ON)

### source files for out project
set(sources
  src/main.cpp
  src/HoloApp.cpp
  src/Kinect.cpp
)

### dependencies
find_package(OpenCV 3 REQUIRED)
# find_package(TurboJPEG REQUIRED)
find_package(PkgConfig)
find_package(LibUSB REQUIRED)
find_package(freenect2 REQUIRED)
find_package(OpenCL REQUIRED)

include_directories(BEFORE ${OpenCV_INCLUDE_DIRS})
# include_directories(${TurboJPEG_INCLUDE_DIRS})
include_directories(${freenect2_INCLUDE_DIRS})

### addons
# ofxaddon(ofxGui)
# ofxaddon(addons/ofxCv)
ofxaddon(addons/ofxTimeMeasurements)

# set(ofx_addon_includes addons/ofxCv/libs/CLD/include/CLD addons/ofxCv/libs/ofxCv/include/ofxCv)
include_directories(${ofx_addon_includes})

### target definitions
add_executable(${APP} ${sources} ${OFXADDONS_SOURCES})
target_compile_options(${APP} PUBLIC -std=c++1y)
# this lets me include files relative to the root src dir with a <> pair
target_include_directories(${APP} PUBLIC src/main)

target_link_libraries(${APP} PUBLIC
  ${OpenCV_LIBS}
  # ${Boost_LIBRARIES}
  ${OPENFRAMEWORKS_LIBRARIES}
  # ${TurboJPEG_LIBRARIES}
  ${LibUSB_LIBRARIES}
  ${OpenCL_LIBRARIES}
  ${freenect2_LIBRARIES}
)

install(TARGETS ${APP} DESTINATION .)
# this is basically a repeat of the file copy instruction that copies the
# resources in the build directory, but here we tell cmake that we want it
# in the package
# install(DIRECTORY assets/models DESTINATION .)
# install(DIRECTORY assets/images DESTINATION data)
# install(DIRECTORY assets/fonts DESTINATION data)
# install(FILES src/mtcnn_runner.py DESTINATION .)

if (COTIRE)
    cotire(${APP})
endif()
