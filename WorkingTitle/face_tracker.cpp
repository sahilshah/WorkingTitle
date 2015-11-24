//
//  face_tracker.cpp
//  WorkingTitle
//
//  Created by Sahil Shah on 11/19/15.
//  Copyright (c) 2015 Sahil Shah. All rights reserved.
//

#include "face_tracker.h"
#include <string>

using namespace dlib;
using namespace std;


void getImageWithFaceLandmarks(cv::Mat& img, const char* model_name){
    // Load face detection and pose estimation models.
    frontal_face_detector detector = get_frontal_face_detector();
    shape_predictor pose_model;
    deserialize(model_name) >> pose_model;
    
    cv::resize(img,img,cv::Size(),0.5,0.5,CV_INTER_CUBIC );
    cout << img.size() << endl;
    cout << img.channels() << endl;
    cv::cvtColor(img,img,CV_RGBA2RGB);
    cv_image<rgb_pixel> cimg(img);

    std::vector<rectangle> faces = detector(cimg);
    if(faces.size() > 0){
        cout << "Found face" << endl;
        full_object_detection d = pose_model(cimg, faces[0]);
        for(int i = 0; i < d.num_parts(); i++){
            cv::circle(img, cv::Point(d.part(i).x(),d.part(i).y()), 2, cv::Scalar(255,255,255));
        }
        
    }
    else
        cout << "Sorry!" << endl;
    
    
}

