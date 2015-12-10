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
    
    // get image data in buffer and create opencv image
    CGImageRef x = [image CGImage];
    CFDataRef x1 = CGDataProviderCopyData(CGImageGetDataProvider(x));
    const unsigned char *buffer = CFDataGetBytePtr(x1);
    size_t bpr = CGImageGetBytesPerRow(x);
    size_t w = CGImageGetWidth(x);
    size_t h = CGImageGetHeight(x);
    cv::Mat cvImage((int)h,(int)w,CV_8UC4, (void*)buffer,(size_t)bpr);
    
    // clone image for maintaing a full scale copy
    cvImage = cvImage.t();
    cv::Mat cvFImage(cvImage);
    
    cv::resize(cvImage,cvImage,cv::Size(480/2,640/2), 0, 0,CV_INTER_CUBIC );
    cv::cvtColor(cvImage,cvImage,CV_RGBA2RGB);
    cv_image<rgb_pixel> cimg(cvImage);
    
    UIImage *tImage = MatToUIImage(cvFImage);
//    UIImage *tImage = scaleAndRotateImage(image);

    // Create FD and apply on image
    NSDictionary *detectorOptions = @{ CIDetectorAccuracy : CIDetectorAccuracyLow };
    CIDetector *faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
    NSArray *features = [faceDetector featuresInImage:[CIImage imageWithCGImage: [tImage CGImage]]];
    
    // Loop through each detected face
    for(CIFaceFeature* faceFeature in features) {
        cout << "Found Face from Detector " << endl;
        CGPoint o = faceFeature.bounds.origin;
        CGSize s = faceFeature.bounds.size;
        cv::Point p1(o.x,640 - o.y);
        cv::Point p2(o.x + s.width, 640 - o.y);
        cv::Point p3(o.x + s.width, 640 - o.y - s.height);
        cv::Point p4(o.x, 640 - o.y - s.height);
        
        cv::line(cvFImage,p1,p2,BLUE);
        cv::line(cvFImage,p2,p3,BLUE);
        cv::line(cvFImage,p3,p4,BLUE);
        cv::line(cvFImage,p4,p1,BLUE);

        
        // get pose from dlib pose model
        dlib::rectangle face(dlib::point(o.x + 0.1 * s.width, (640 - o.y) - 0.9 * s.height ),
                             dlib::point(o.x + 0.9 * s.width, (640 - o.y) - 0.1 * s.height));
        
        cv::line(cvFImage,cv::Point(face.br_corner().x(),face.br_corner().y()),
                 cv::Point(face.bl_corner().x(),face.bl_corner().y()),GREEN);
        cv::line(cvFImage,cv::Point(face.tl_corner().x(),face.tl_corner().y()),
                 cv::Point(face.bl_corner().x(),face.bl_corner().y()),GREEN);
        cv::line(cvFImage,cv::Point(face.br_corner().x(),face.br_corner().y()),
                 cv::Point(face.tr_corner().x(),face.tr_corner().y()),GREEN);
        cv::line(cvFImage,cv::Point(face.tr_corner().x(),face.tr_corner().y()),
                 cv::Point(face.tl_corner().x(),face.tl_corner().y()),GREEN);
        
        full_object_detection d = pm(cimg, face);
        for(int i = 0; i < d.num_parts(); i++){
            cv::circle(cvFImage, cv::Point(d.part(i).x(),d.part(i).y()),2, RED);
        }

    }
    
    cvFImage = cvFImage.t();
    UIImage *resImage = MatToUIImage(cvFImage);
    
    cout << "Rendering Image" << endl;
    
    resultView_.image =  [UIImage imageWithCGImage:[resImage CGImage]
                                             scale:1.0
                                       orientation: UIImageOrientationLeftMirrored];
    
    [takephotoButton_ setHidden:true]; [goliveButton_ setHidden:false];
    
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

UIImage *scaleAndRotateImage(UIImage *image)
{
    int kMaxResolution = 640; // Or whatever
    
    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (width > kMaxResolution || height > kMaxResolution) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = kMaxResolution;
            bounds.size.height = bounds.size.width / ratio;
        }
        else {
            bounds.size.height = kMaxResolution;
            bounds.size.width = bounds.size.height * ratio;
        }
    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;
    switch(orient) {
            
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();  
    
    return imageCopy;  
}

@end