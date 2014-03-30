//
//  HDFacebookShareViewController.m
//  HackDuke
//
//  Created by Ian Perry on 3/30/14.
//  Copyright (c) 2014 iperry. All rights reserved.
//

#import "HDFacebookShareViewController.h"

@interface HDFacebookShareViewController () 

@end

@implementation HDFacebookShareViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    
    FBLoginView *loginView = [[FBLoginView alloc] init];
    [self.view addSubview:loginView];
    loginView.delegate = self;
    
}

- (void)sendVideoToFacebook
{
// Stage the image
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [paths objectAtIndex:0];
    NSString *composedOutputPath = [self.videoInfo objectForKey:@"assetURL"];
    NSData *videoData = [NSData dataWithContentsOfFile:composedOutputPath];
    
    NSMutableDictionary<FBGraphObject>* params = [FBGraphObject graphObject];
    [params setDictionary:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                           videoData, @"video.mov",
                           @"video/quicktime", @"contentType",
                           @"My awesome video", @"title", nil]];
    
    FBRequest *request = [FBRequest requestWithGraphPath:@"me/videos" parameters:params HTTPMethod:@"POST"];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        NSLog(@"result: %@, error: %@", result, error);
    }];
}

-(void)loginView:(FBLoginView *)loginView handleError:(NSError *)error
{
    
}


-(void)loginViewFetchedUserInfo:(FBLoginView *)loginView user:(id<FBGraphUser>)user
{
    
}

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView
{
    [loginView removeFromSuperview];
    
    FBSession *session = [[FBSession alloc] init];
    [FBSession setActiveSession:session];
    
}

@end
