//
//  face_tracker.h
//  WorkingTitle
//
//  Created by Sahil Shah on 11/19/15.
//  Copyright (c) 2015 Sahil Shah. All rights reserved.
//

#ifndef __WorkingTitle__face_tracker__
#define __WorkingTitle__face_tracker__

#include <stdio.h>

#include "dlib/opencv.h"
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include "dlib/image_processing/frontal_face_detector.h"
#include "dlib/image_processing/shape_predictor.h"

void getImageWithFaceLandmarks(cv::Mat& img, const char* model);

#endif /* defined(__WorkingTitle__face_tracker__) */
