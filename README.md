##16423: Designing Computer Vision Apps Project Proposal
###by Sahil Shah (sahils) 

###Title 

Face Tracking on Mobile Device

###Summary

In this project, I want to port a face tracking on the mobile phone and make it work in real time. I will be using a landmark-based model for the face as opposed to a bounding box approach because that opens avenues for further applications as well. I will also try to get the pose of the face. As a stretch goal, I want to be able to do some fun stuff with the tracked facial points like expression classification, pulse rate detection or blink counts.

###Background

I have not decided which face tracking algorithm I will be porting yet. However, it will be amongst the following:

•	Dlib Face Tracker

•	Face Alignment at 3000 FPS via Regressing Local Binary Features

•	Chehra Face Tracker: Incremental Face Alignment in the Wild

•	Intraface: Supervised Descent Method based face tracking

•	CSIRO face tracker by Prof. Lucey’s lab

The optimizations I use will differ from tracker to tracker. Dlib uses LAPACK so it could make use of the Accelerate framework. Face Alignment at 3000 fps uses binary features so those will be fast on mobile. The matrix multiplications for Intraface can be done with armadillo to make them faster.

###Challenge

From implementation standpoint- porting code for any of these trackers seems to be very challenging. Especially, since some of the trackers are closed source and some only have Matlab implementations. My fallback option is the Dlib tracker as its code is open source and Dlib is just a header only library so I believe it will be simpler to port on iOS.

Form a performance standpoint- the major challenge would be to make it run in real time with considerable accuracy. I hope to make it run in the wild!

###Goals

I plan to port at least one tracker successfully and make it run in real time. I will evaluate its performance on the mobile device on datasets such as Helen and benchmark it against the Desktop implementations.

I hope to add some fun features if I achieve the face tracking early enough. Possible additions are pulse estimation using Fourier transforms, blink counting, expression detection etc.

###Schedule

11/07 – 11/13: Literature Review; Analysis of face trackers

11/14 – 11/20: Porting

11/21 – 11/28: Optimizing 

11/29 – 12/04: Testing

12/05 – 12/11: Picking Slack; Strech Goals

