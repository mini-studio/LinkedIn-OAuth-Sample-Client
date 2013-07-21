//
//  OAuthViewController.m
//  OAuthStarterKit
//
//  Created by Wuquancheng on 13-7-17.
//  Copyright (c) 2013年 self. All rights reserved.
//

#import "OAuthViewController.h"

@interface OAuthViewController ()<LinkedInAuthDelegate>

@end

@implementation OAuthViewController

@synthesize engine;

- (id)init
{
    self = [super init];
    if (self) {
        self.engine = [[LinkedInEngine alloc] initWithApiKey:@"hgai5j6rmm7c" secretkey:@"rrfGP5OIA8ySUdXJ"];
        self.engine.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self.engine login];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)linkedInEngine:(LinkedInEngine*)engine webviewWillAppear:(UIWebView*)view
{
    view.frame = self.view.bounds;
    [self.view addSubview:view];
}

- (void)linkedInEngine:(LinkedInEngine*)engine accessTokenResult:(OAToken *)accessToken
{
    
}

- (void)linkedInEngine:(LinkedInEngine*)engine accessTokenFailure:(NSString*)data canceled:(BOOL)canceld
{
    if ( canceld ) {
        [self dismissModalViewControllerAnimated:YES];
    }
}

@end
