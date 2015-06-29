//
//  ViewController.m
//  WebRecorder
//
//  Created by uqadekke on 25/06/2015.
//  Copyright (c) 2015 uqadekke. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>

#define DOCUMENTS_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]

@interface ViewController ()

@property (strong, nonatomic) NSMutableDictionary *nativeRequest;
@property (strong, nonatomic) AVAudioRecorder *recorder;
@property (strong, nonatomic) NSURL *recordingUrl;
@property (strong, nonatomic) AVAudioPlayer *player;
@property (strong, nonatomic) AVAudioSession *audioSession;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupDelegate];
    [self setupRecording];
    [self loadWebsite];
}

- (void)setupRecording {
    self.recordingUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/test.caf",DOCUMENTS_FOLDER]];
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithFloat: 44100.0],                 AVSampleRateKey,
                              [NSNumber numberWithInt: kAudioFormatAppleLossless], AVFormatIDKey,
                              [NSNumber numberWithInt: 1],                         AVNumberOfChannelsKey,
                              [NSNumber numberWithInt: AVAudioQualityMax],         AVEncoderAudioQualityKey,
                              nil];
    NSError *error;
    self.recorder = [[AVAudioRecorder alloc] initWithURL:self.recordingUrl settings:settings error:&error];
    self.audioSession = [AVAudioSession sharedInstance];
}

- (void)setupDelegate {
    self.webView.delegate = self;
    self.webView.scalesPageToFit = YES;
}

- (void) loadWebsite {
    NSString* url = @"https://tools.ceit.uq.edu.au/test/audiotest/index.html";
    url = @"https://edge.edx.org/courses/UQx/ceit1001/2014_1/courseware/a3723e6b048a4d2893687fc278abbd56/6df2a4b26e0d43ef8ee1b85fa9435bda/1";
    NSURL* nsUrl = [NSURL URLWithString:url];
    NSURLRequest* request = [NSURLRequest requestWithURL:nsUrl cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:3];
    [self.webView loadRequest:request];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([[[request URL] absoluteString] hasPrefix:@"ios:"]) {
        if([self setNativeParams:[[request URL] absoluteString]]) {
            [self performSelector:@selector(webToNativeCall)];
        }
        // Cancel the location change
        return NO;
    }
    return YES;
}

//This method checks if the parameters sent are valid
- (BOOL)setNativeParams:(NSString *)request {
    self.nativeRequest = nil;
    NSArray *params = [request componentsSeparatedByString:@":"];
    if([params count] > 1 && [params count] < 4) {
        self.nativeRequest = [[NSMutableDictionary alloc] init];
        [self.nativeRequest setObject:[params objectAtIndex:1] forKey:@"method"];
        [self.nativeRequest setObject:@[] forKey:@"data"];
        if([params count] == 3) {
            NSArray *dataArray = [[params objectAtIndex:2] componentsSeparatedByString:@"|"];
            [self.nativeRequest setObject:dataArray forKey:@"data"];
        }
        return YES;
    }
    return NO;
}

- (void)webToNativeCall
{
    if([[self.nativeRequest objectForKey:@"method"] isEqualToString:@"startaudiorecording"]) {
        [self startAudioRecording];
    } else if([[self.nativeRequest objectForKey:@"method"] isEqualToString:@"stopaudiorecording"]) {
        [self stopAudioRecording];
    } else if([[self.nativeRequest objectForKey:@"method"] isEqualToString:@"playaudiorecording"]) {
        [self playAudioRecording];
    } else if([[self.nativeRequest objectForKey:@"method"] isEqualToString:@"pauseaudiorecording"]) {
        [self pauseAudioRecording];
    } else if([[self.nativeRequest objectForKey:@"method"] isEqualToString:@"seekaudiorecording"]) {
        [self seekAudioRecording];
    } else {
        NSLog(@"UNRECOGNISED METHOD %@",[self.nativeRequest objectForKey:@"method"]);
    }
}

#pragma mark Native Callbacks
- (void)startAudioRecording {
    NSLog(@"STARTING AUDIO");
    if (self.recorder) {
        [self.audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
        [self.audioSession setActive:YES error:nil];
        [self.recorder prepareToRecord];
        [self.recorder record];
    }
}

- (void)stopAudioRecording {
    NSLog(@"STOPPING AUDIO");
    if(self.recorder) {
        [self.recorder stop];
    }
}

- (void)playAudioRecording {
    [self.audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [self.audioSession setActive:YES error:nil];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:self.recordingUrl error:nil];
    self.player.numberOfLoops = 0;
    [self.player play];
    NSLog(@"PLAYING AUDIO");
    NSLog(@"%@",self.recordingUrl);
}

- (void)pauseAudioRecording {
    NSLog(@"PAUSING AUDIO");
    [self.player stop];
}

- (void)seekAudioRecording {
    NSLog(@"SEEKING AUDIO");
}

@end
