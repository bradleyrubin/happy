//
//  HDFacebookShareViewController.h
//  HackDuke
//
//  Created by Ian Perry on 3/30/14.
//  Copyright (c) 2014 iperry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@interface HDFacebookShareViewController : UIViewController<FBLoginViewDelegate>
@property (strong, nonatomic) NSDictionary *videoInfo;
-(void)sendVideoToFacebook;
@end
