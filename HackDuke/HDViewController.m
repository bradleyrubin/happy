//
//  HDViewController.m
//  HackDuke
//
//  Created by Ian Perry on 3/30/14.
//  Copyright (c) 2014 iperry. All rights reserved.
//

#import "HDViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "HDMoviePlayerViewController.h"
#import "HDFacebookShareViewController.h"

@interface HDViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (strong, nonatomic) UIView *cameraOverlayView;
@property (strong, nonatomic) MPMusicPlayerController *myPlayer;
@property (strong, nonatomic) HDMoviePlayerViewController *player;
@property (strong, nonatomic) NSDictionary *info;
@property BOOL recording;
@end

@implementation HDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // instantiate a music player
    self.myPlayer =
    [MPMusicPlayerController applicationMusicPlayer];
    
    MPMediaPropertyPredicate *artistPredicate =
    [MPMediaPropertyPredicate predicateWithValue:@"Pharrell Williams"
                                     forProperty:MPMediaItemPropertyArtist
                                  comparisonType:MPMediaPredicateComparisonContains];
    
    NSSet *predicates = [NSSet setWithObjects: artistPredicate, nil];
    
    MPMediaQuery *songsQuery =  [[MPMediaQuery alloc] initWithFilterPredicates: predicates];
    printf("Num songs:%d\n",[[songsQuery items] count] );
    
    if ([[songsQuery items] count] == 0) {
        printf("You don't have Happy!\n");
        
        
        
        NSString *iTunesLink = @"https://itunes.apple.com/us/album/happy-from-despicable-me-2/id823593445?i=823593456&uo=4";
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
        
    } else {
        [self.myPlayer setQueueWithQuery:songsQuery];
//        [self.myPlayer play];
//        AudioSessionSetProperty( kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof(trueValue), &trueValue);
//        AudioSessionSetProperty( kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof( trueValue ), &trueValue );
        
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];


}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self->imagePickerController == nil)
    {
    
        self->imagePickerController = [[UIImagePickerController alloc] init];
        CGRect theRect = [self.view frame];
        UIView *view = [[UIView alloc] initWithFrame:theRect];
        
        view.opaque = NO;
        view.backgroundColor = [UIColor clearColor];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        [button setTitle:@"Take Pic" forState:UIControlStateNormal];
        button.frame = CGRectMake(100, 500, 320, 100);
        [button addTarget:self action:@selector(recordVideo) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:button];
        
        //    self.imagePickerController = [[UIImagePickerController alloc] init];
        
        
        if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO)
        {
            //        [self performSelector:@selector(showImagePicker) withObject:nil afterDelay:0.1];
            [self showImagePicker:view];
        }
    }
    

}

- (void)showImagePicker:(UIView *)view
{
    self->imagePickerController.modalPresentationStyle = UIModalPresentationFullScreen;
    self->imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    self->imagePickerController.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *) kUTTypeMovie, nil];
    self->imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    self->imagePickerController.delegate = self;
    self->imagePickerController.showsCameraControls = NO;
    self->imagePickerController.allowsEditing = NO;
    self->imagePickerController.cameraViewTransform = CGAffineTransformScale(self->imagePickerController.cameraViewTransform, 1.32, 1.32);
    self->imagePickerController.cameraOverlayView = view;
    
    [self presentViewController:self->imagePickerController animated:NO completion:nil];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)recordVideo
{
    if (!self.recording)
    {
        self.recording = YES;
        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];
        UInt32 doSetProperty = 1;
        AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(doSetProperty), &doSetProperty);
        [[AVAudioSession sharedInstance] setActive: YES error: nil];
        
        [self.myPlayer play];
        [self->imagePickerController startVideoCapture];
    }
    else
    {
        self.recording = NO;
        [self->imagePickerController stopVideoCapture];
  
    }
}

- (void)showVideo:(NSURL *)url
{

    self.player = [[HDMoviePlayerViewController alloc] initWithContentURL:url];
    self.player.moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
    self.player.moviePlayer.shouldAutoplay = YES;
    [self.player.moviePlayer setFullscreen:YES animated:YES];
    self.player.moviePlayer.movieSourceType = MPMovieSourceTypeFile;
    [self.player.moviePlayer prepareToPlay];
    [self.player.view setFrame:self.view.frame];
    [self.view addSubview:self.player.view];
//    [self presentMoviePlayerViewControllerAnimated:self.player];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayBackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    
    [self.player.moviePlayer play];
}

-(void)moviePlayBackDidFinish:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    [self.player.view removeFromSuperview];
    HDFacebookShareViewController *viewController = [[HDFacebookShareViewController alloc] init];
    viewController.videoInfo = self.info;
    [viewController sendVideoToFacebook];
    [self presentViewController:viewController animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate Methods
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    self.info = info;
    NSURL *videoUrl = [info objectForKey:UIImagePickerControllerMediaURL];
    NSURL *songUrl = [self.myPlayer.nowPlayingItem valueForProperty:@"assetURL"];
    [self.myPlayer stop];
    NSURL *binded = [self bindAudioAndVideo:songUrl videoFileUrl:videoUrl];
    [self->imagePickerController dismissViewControllerAnimated:YES completion:nil];
    [self showVideo:binded];
}

- (void) removeFile:(NSURL *)fileURL
{
    NSString *filePath = [fileURL path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error;
        if ([fileManager removeItemAtPath:filePath error:&error] == NO) {
            NSLog(@"removeItemAtPath %@ error:%@", filePath, error);
        }
    }
}

-(NSURL*)bindAudioAndVideo:(NSURL*)audio_inputFileUrl videoFileUrl:(NSURL*)video_inputFileUrl
{
    
    //documents folder
    NSArray     *paths              = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsFolder       = [[NSString alloc] initWithString:[paths objectAtIndex:0]];    //Get the docs directory
    
//    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
//    NSString* audio_inputFileName   = audioFileName;
//    NSString* audio_inputFilePath   = [documentsFolder stringByAppendingPathComponent:audio_inputFileName];
//    NSURL*    audio_inputFileUrl    = [NSURL fileURLWithPath:audio_inputFilePath];
    
//    NSString* video_inputFileName   = videoFileName;
//    NSString* video_inputFilePath   = [documentsFolder stringByAppendingPathComponent:video_inputFileName];
//    NSURL*    video_inputFileUrl    = [NSURL fileURLWithPath:video_inputFilePath];
    
    NSString* outputFileName        = @"outputFile.mp4";
    NSString* outputFilePath        = [documentsFolder stringByAppendingPathComponent:outputFileName];
    NSURL*    outputFileUrl         = [NSURL fileURLWithPath:outputFilePath];
    
    //Check files actually exist before beginning (they do)
    
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    CMTime nextClipStartTime = kCMTimeZero;
    
    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:video_inputFileUrl options:nil];
    CMTimeRange video_timeRange = CMTimeRangeMake(kCMTimeZero,videoAsset.duration);
    AVMutableCompositionTrack *a_compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [a_compositionVideoTrack insertTimeRange:video_timeRange ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:nextClipStartTime error:nil];
    
    CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(M_PI_2);
    a_compositionVideoTrack.preferredTransform = rotationTransform;
    
    
    AVURLAsset* audioAsset = [[AVURLAsset alloc]initWithURL:audio_inputFileUrl options:nil];
//    CMTimeRange audio_timeRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
    CMTimeRange audio_timeRange = video_timeRange;

    AVMutableCompositionTrack *b_compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [b_compositionAudioTrack insertTimeRange:audio_timeRange ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:nextClipStartTime error:nil];
    
    
    
    AVAssetExportSession* _assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    _assetExport.outputFileType = @"com.apple.quicktime-movie";
    _assetExport.outputURL = outputFileUrl;
    [self removeFile:outputFileUrl];

    
    [_assetExport exportAsynchronouslyWithCompletionHandler:
     ^(void ) {
         [self addSkipBackupAttributeToItemAtURL:outputFileUrl];
         NSLog(@"Completed. Tidy time.");
         
         switch ([_assetExport status]) {
             case AVAssetExportSessionStatusCompleted:
                 NSLog(@"Export Completed");
                 break;
             case AVAssetExportSessionStatusFailed:
                 NSLog(@"Export failed: %@", [[_assetExport error] localizedDescription]);
                 NSLog (@"FAIL %@",_assetExport.error); //-11820! I AM A USELESS ERROR CODE
                 NSLog (@"supportedFileTypes: %@", _assetExport.supportedFileTypes);
                 break;
             case AVAssetExportSessionStatusCancelled:
                 NSLog(@"Export cancelled");
                 break;
             default:
                 break;
         }
         
         
//         NSTimer *refreshTimer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(exportCompleteRefreshView) userInfo:Nil repeats:NO];
//         
//         //Throw back to main thread unuless you want really long delays for no reason.
//         [[NSRunLoop mainRunLoop] addTimer:refreshTimer forMode:NSRunLoopCommonModes];
     }
     ];
    
    
    return outputFileUrl;
}


- (int)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
    
    NSError *error = nil;
    BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                  forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success){
        NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    return success;
}


@end
