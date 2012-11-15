//
//  OWSegmentingAppleEncoder.m
//  OpenWatch
//
//  Created by Christopher Ballinger on 11/13/12.
//  Copyright (c) 2012 OpenWatch FPC. All rights reserved.
//

#import "OWSegmentingAppleEncoder.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "OWCaptureAPIClient.h"

@implementation OWSegmentingAppleEncoder
@synthesize segmentationTimer, queuedAssetWriter;
@synthesize queuedAudioEncoder, queuedVideoEncoder;
@synthesize audioBPS, videoBPS;

- (void) dealloc {
    if (self.segmentationTimer) {
        [self.segmentationTimer invalidate];
        self.segmentationTimer = nil;
    }
}

- (void) finishEncoding {
    if (self.segmentationTimer) {
        [self.segmentationTimer invalidate];
        self.segmentationTimer = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super finishEncoding];
    //[[OWCaptureAPIClient sharedClient] finishedRecording:self.recording];
}

- (id) initWithURL:(NSURL *)url segmentationInterval:(NSTimeInterval)timeInterval {
    if (self = [super init]) {
        self.segmentationTimer = [NSTimer timerWithTimeInterval:timeInterval target:self selector:@selector(segmentRecording:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:segmentationTimer forMode:NSDefaultRunLoopMode];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedBandwidthUpdateNotification:) name:kOWCaptureAPIClientBandwidthNotification object:nil];
    }
    return self;
}

- (void) receivedBandwidthUpdateNotification:(NSNotification*)notification {
    double bps = [[[notification userInfo] objectForKey:@"bps"] doubleValue];
    self.videoBPS = (bps*0.5) - audioBPS;
    //self.videoBPS = videoBPS * 0.75;
    NSLog(@"bps: %f\tvideoBPS: %d\taudioBPS: %d", bps, videoBPS, audioBPS);
}



- (void) segmentRecording:(NSTimer*)timer {
    AVAssetWriter *tempAssetWriter = self.assetWriter;
    AVAssetWriterInput *tempAudioEncoder = self.audioEncoder;
    AVAssetWriterInput *tempVideoEncoder = self.videoEncoder;
    self.assetWriter = queuedAssetWriter;
    self.audioEncoder = queuedAudioEncoder;
    self.videoEncoder = queuedVideoEncoder;
    //NSLog(@"Switching encoders");
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        if (tempAssetWriter.status == AVAssetWriterStatusWriting) {
            [tempAudioEncoder markAsFinished];
            [tempVideoEncoder markAsFinished];
            if(![tempAssetWriter finishWriting]) {
                [self showError:[tempAssetWriter error]];
            } else {
                [self uploadFileURL:tempAssetWriter.outputURL];
            }
        }
        if (self.readyToRecordAudio && self.readyToRecordVideo) {
            NSError *error = nil;
            self.queuedAssetWriter = [[AVAssetWriter alloc] initWithURL:[self.recording urlForNextSegment] fileType:(NSString *)kUTTypeMPEG4 error:&error];
            if (error) {
                [self showError:error];
            }
            self.queuedVideoEncoder = [self setupVideoEncoderWithAssetWriter:self.queuedAssetWriter formatDescription:videoFormatDescription bitsPerSecond:videoBPS];
            self.queuedAudioEncoder = [self setupAudioEncoderWithAssetWriter:self.queuedAssetWriter formatDescription:audioFormatDescription bitsPerSecond:audioBPS];
            //NSLog(@"Encoder switch finished");

        }
    });
}



- (void) setupVideoEncoderWithFormatDescription:(CMFormatDescriptionRef)formatDescription bitsPerSecond:(int)bps {
    videoFormatDescription = formatDescription;
    videoBPS = bps;
    if (!self.assetWriter) {
        NSError *error = nil;
        self.assetWriter = [[AVAssetWriter alloc] initWithURL:[self.recording urlForNextSegment] fileType:(NSString *)kUTTypeMPEG4 error:&error];
        if (error) {
            [self showError:error];
        }
    }
    self.videoEncoder = [self setupVideoEncoderWithAssetWriter:self.assetWriter formatDescription:formatDescription bitsPerSecond:bps];
    
    if (!queuedAssetWriter) {
        NSError *error = nil;
        self.queuedAssetWriter = [[AVAssetWriter alloc] initWithURL:[self.recording urlForNextSegment] fileType:(NSString *)kUTTypeMPEG4 error:&error];
        if (error) {
            [self showError:error];
        }
    }
    self.queuedVideoEncoder = [self setupVideoEncoderWithAssetWriter:self.queuedAssetWriter formatDescription:formatDescription bitsPerSecond:bps];
    self.readyToRecordVideo = YES;
}

- (void) setupAudioEncoderWithFormatDescription:(CMFormatDescriptionRef)formatDescription bitsPerSecond:(int)bps {
    audioFormatDescription = formatDescription;
    audioBPS = bps;
    if (!self.assetWriter) {
        NSError *error = nil;
        self.assetWriter = [[AVAssetWriter alloc] initWithURL:[self.recording urlForNextSegment] fileType:(NSString *)kUTTypeMPEG4 error:&error];
        if (error) {
            [self showError:error];
        }
    }
    self.audioEncoder = [self setupAudioEncoderWithAssetWriter:self.assetWriter formatDescription:formatDescription bitsPerSecond:bps];
    
    if (!queuedAssetWriter) {
        NSError *error = nil;
        self.queuedAssetWriter = [[AVAssetWriter alloc] initWithURL:[self.recording urlForNextSegment] fileType:(NSString *)kUTTypeMPEG4 error:&error];
        if (error) {
            [self showError:error];
        }
    }
    self.queuedAudioEncoder = [self setupAudioEncoderWithAssetWriter:self.queuedAssetWriter formatDescription:formatDescription bitsPerSecond:bps];
    self.readyToRecordAudio = YES;
}

- (void) uploadFileURL:(NSURL*)url {
    OWCaptureAPIClient *captureClient = [OWCaptureAPIClient sharedClient];
    [captureClient uploadFileURL:url recording:self.recording priority:NSOperationQueuePriorityVeryHigh];
}



@end