//
//  ViewController.m
//  WorkingTitle
//
//  Created by Sahil Shah on 11/19/15.
//  Copyright (c) 2015 Sahil Shah. All rights reserved.
//

#import "ViewController.h"

#include <stdio.h>

#include "dlib/opencv.h"
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include "dlib/image_processing/frontal_face_detector.h"
#include "dlib/image_processing/shape_predictor.h"

#include <stdlib.h>

using namespace std;
using namespace cv;
using namespace dlib;


const Scalar RED       = Scalar(255,0,0);
const Scalar PINK      = Scalar(255,130,230);
const Scalar BLUE      = Scalar(0,0,255);
const Scalar LIGHTBLUE = Scalar(160,255,255);
const Scalar GREEN     = Scalar(0,255,0);
const Scalar WHITE     = Scalar(255,255,255);


@interface ViewController()
{
    UIImageView *liveView_; // Live output from the camera
    UIImageView *resultView_; // Preview view of everything...
    UIButton *takephotoButton_, *goliveButton_; // Button to initiate OpenCV processing of image
    CvPhotoCamera *photoCamera_; // OpenCV wrapper class to simplfy camera access through AVFoundation
    frontal_face_detector fd;
    shape_predictor pm;
}
@end

@implementation ViewController


// Setup view for excuting App
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    
    
    // 1. Setup the your OpenCV view, so it takes up the entire App screen......
    int view_width = self.view.frame.size.width;
    int view_height = (640*view_width)/480; // Work out the viw-height assuming 640x480 input
    int view_offset = (self.view.frame.size.height - view_height)/2;
    liveView_ = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, view_offset, view_width, view_height)];
    [self.view addSubview:liveView_]; // Important: add liveView_ as a subview
    //resultView_ = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 960, 1280)];
    resultView_ = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, view_offset, view_width, view_height)];
    [self.view addSubview:resultView_]; // Important: add resultView_ as a subview
    resultView_.hidden = true; // Hide the view

    
    // 2. First setup a button to take a single picture
    takephotoButton_ = [self simpleButton:@"Take Photo" buttonColor:[UIColor redColor]];
    // Important part that connects the action to the member function buttonWasPressed
    [takephotoButton_ addTarget:self action:@selector(buttonWasPressed) forControlEvents:UIControlEventTouchUpInside];
    
    // 3. Setup another button to go back to live video
    goliveButton_ = [self simpleButton:@"Go Live" buttonColor:[UIColor greenColor]];
    // Important part that connects the action to the member function buttonWasPressed
    [goliveButton_ addTarget:self action:@selector(liveWasPressed) forControlEvents:UIControlEventTouchUpInside];
    [goliveButton_ setHidden:true]; // Hide the button

    
    // Init the dlib models
    NSString* dlib_cpath = [[NSBundle mainBundle] pathForResource:@"shape_predictor_68_face_landmarks" ofType:@"dat"];
    fd = get_frontal_face_detector();
    deserialize(dlib_cpath.fileSystemRepresentation) >> pm;
    
    // 4. Initialize the camera parameters and start the camera (inside the App)
    photoCamera_ = [[CvPhotoCamera alloc] initWithParentView:liveView_];
    photoCamera_.delegate = self;
    
    // This chooses whether we use the front or rear facing camera
    photoCamera_.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    
    // This is used to set the image resolution
    photoCamera_.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
    
    // This is used to determine the device orientation
    photoCamera_.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    
    // This starts the camera capture
    [photoCamera_ start];
    
}

// This member function is executed when the button is pressed
- (void)buttonWasPressed {
    [photoCamera_ takePicture];
}

// This member function is executed when the button is pressed
- (void)liveWasPressed {
    [takephotoButton_ setHidden:false]; [goliveButton_ setHidden:true]; // Switch visibility of buttons
    resultView_.hidden = true; // Hide the result view again
    [photoCamera_ start];
}

// To be compliant with the CvPhotoCameraDelegate we need to implement these two methods
- (void)photoCamera:(CvPhotoCamera *)photoCamera capturedImage:(UIImage *)image
{
    [photoCamera_ stop];
    resultView_.hidden = false; // Turn the hidden view on
//    cv::Mat cvImage;
    
//    UIImageToMat(image, cvImage);
    
    CGImageRef x = [image CGImage];
    CFDataRef x1 = CGDataProviderCopyData(CGImageGetDataProvider(x));
    const unsigned char *buffer = CFDataGetBytePtr(x1);
    
    int bpp = CGImageGetBitsPerPixel(x);
    int bpr = CGImageGetBytesPerRow(x);
    int w = CGImageGetWidth(x);
    int h = CGImageGetHeight(x);
    
    cv::Mat cvImage(h,w,CV_8UC4, (void*)buffer,(size_t)bpr);
    
    cvImage = cvImage.t();
    cout << "cvImage Size is: " << cvImage.size() << endl;
    cout << "Image Size is: " << image.size.height << " " << image.size.width << endl;
    
    cv::resize(cvImage,cvImage,cv::Size(480/2,640/2), 0, 0,CV_INTER_CUBIC );
    cv::cvtColor(cvImage,cvImage,CV_RGBA2RGB);
    cv_image<rgb_pixel> cimg(cvImage);

    cout << cimg.nc() << " " << cimg.nr() << endl;
    
    std::vector<dlib::rectangle> faces = fd(cimg);
    
    if(faces.size() > 0){
        cout << "Found face" << endl;
        full_object_detection d = pm(cimg, faces[0]);

        
        cv::line(cvImage,cv::Point(faces[0].br_corner().x(),faces[0].br_corner().y()),
                 cv::Point(faces[0].bl_corner().x(),faces[0].bl_corner().y()),GREEN);
        cv::line(cvImage,cv::Point(faces[0].tl_corner().x(),faces[0].tl_corner().y()),
                 cv::Point(faces[0].bl_corner().x(),faces[0].bl_corner().y()),GREEN);
        cv::line(cvImage,cv::Point(faces[0].br_corner().x(),faces[0].br_corner().y()),
                 cv::Point(faces[0].tr_corner().x(),faces[0].tr_corner().y()),GREEN);
        cv::line(cvImage,cv::Point(faces[0].tr_corner().x(),faces[0].tr_corner().y()),
                 cv::Point(faces[0].tl_corner().x(),faces[0].tl_corner().y()),GREEN);
        
        for(int i = 0; i < d.num_parts(); i++){
            cv::circle(cvImage, cv::Point(d.part(i).x(),d.part(i).y()),1, RED);
        }
        
        for (int i = 1; i <= 16; i++)
            cv::line(cvImage, cv::Point(d.part(i).x(),d.part(i).y()),
                     cv::Point(d.part((i-1)).x(),d.part((i-1)).y()), BLUE);

        for (int i = 28; i <= 30; i++)
            cv::line(cvImage, cv::Point(d.part(i).x(),d.part(i).y()),
                     cv::Point(d.part((i-1)).x(),d.part((i-1)).y()), BLUE);

        for (int i = 18; i <= 21; i++)
            cv::line(cvImage, cv::Point(d.part(i).x(),d.part(i).y()),
                     cv::Point(d.part((i-1)).x(),d.part((i-1)).y()), BLUE);
        for (int i = 23; i <= 26; i++)
            cv::line(cvImage, cv::Point(d.part(i).x(),d.part(i).y()),
                     cv::Point(d.part((i-1)).x(),d.part((i-1)).y()), BLUE);
        for (int i = 31; i <= 35; i++)
            cv::line(cvImage, cv::Point(d.part(i).x(),d.part(i).y()),
                     cv::Point(d.part((i-1)).x(),d.part((i-1)).y()), BLUE);
        cv::line(cvImage, cv::Point(d.part(30).x(),d.part(30).y()),
                 cv::Point(d.part((35)).x(),d.part((35)).y()), BLUE);

        
        for (int i = 37; i <= 41; i++)
            cv::line(cvImage, cv::Point(d.part(i).x(),d.part(i).y()),
                     cv::Point(d.part((i-1)).x(),d.part((i-1)).y()), BLUE);
        cv::line(cvImage, cv::Point(d.part(36).x(),d.part(36).y()),
                 cv::Point(d.part((41)).x(),d.part((41)).y()), BLUE);

        
        for (int i = 43; i <= 47; i++)
            cv::line(cvImage, cv::Point(d.part(i).x(),d.part(i).y()),
                     cv::Point(d.part((i-1)).x(),d.part((i-1)).y()), BLUE);
        cv::line(cvImage, cv::Point(d.part(42).x(),d.part(42).y()),
                 cv::Point(d.part((47)).x(),d.part((47)).y()), BLUE);

        for (int i = 49; i <= 59; i++)
            cv::line(cvImage, cv::Point(d.part(i).x(),d.part(i).y()),
                     cv::Point(d.part((i-1)).x(),d.part((i-1)).y()), BLUE);
        cv::line(cvImage, cv::Point(d.part(48).x(),d.part(48).y()),
                 cv::Point(d.part((59)).x(),d.part((59)).y()), BLUE);

        for (int i = 61; i <= 67; i++)
            cv::line(cvImage, cv::Point(d.part(i).x(),d.part(i).y()),
                     cv::Point(d.part((i-1)).x(),d.part((i-1)).y()), BLUE);
        cv::line(cvImage, cv::Point(d.part(60).x(),d.part(60).y()),
                 cv::Point(d.part((67)).x(),d.part((67)).y()), BLUE);

        
    }
    else{
        cout << "Could not find face!" << endl;
    }
    
    cvImage = cvImage.t();
    UIImage *resImage = MatToUIImage(cvImage);
    
    cout << "Rendering Image" << endl;
    
    resultView_.image =  [UIImage imageWithCGImage:[resImage CGImage]
                                             scale:2.0
                                       orientation: UIImageOrientationLeftMirrored];
    
    [takephotoButton_ setHidden:true]; [goliveButton_ setHidden:false]; // Switch visibility of buttons

    
}
- (void)photoCameraCancel:(CvPhotoCamera *)photoCamera
{
    
}

// Simple member function to initialize buttons in the bottom of the screen so we do not have to
// bother with storyboard, and can go straight into vision on mobiles
//
- (UIButton *) simpleButton:(NSString *)buttonName buttonColor:(UIColor *)color
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom]; // Initialize the button
    // Bit of a hack, but just positions the button at the bottom of the screen
    int button_width = 200; int button_height = 50; // Set the button height and width (heuristic)
    // Botton position is adaptive as this could run on a different device (iPAD, iPhone, etc.)
    int button_x = (self.view.frame.size.width - button_width)/2; // Position of top-left of button
    int button_y = self.view.frame.size.height - 80; // Position of top-left of button
    button.frame = CGRectMake(button_x, button_y, button_width, button_height); // Position the button
    [button setTitle:buttonName forState:UIControlStateNormal]; // Set the title for the button
    [button setTitleColor:color forState:UIControlStateNormal]; // Set the color for the title
    
    [self.view addSubview:button]; // Important: add the button as a subview
    //[button setEnabled:bflag]; [button setHidden:(!bflag)]; // Set visibility of the button
    return button; // Return the button pointer
}


// Standard memory warning component added by Xcode
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end