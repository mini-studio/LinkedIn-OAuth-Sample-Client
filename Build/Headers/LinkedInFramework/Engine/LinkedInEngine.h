//
//  LinkedInEngine.h
//  OAuthStarterKit
//
//  Created by Wuquancheng on 13-7-16.
//  Copyright (c) 2013年 self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAServiceTicket.h"

@interface LinkedInUser : NSObject
@property (nonatomic,retain) NSString *userId;
@property (nonatomic,retain) NSString *lastName;
@property (nonatomic,retain) NSString *firstName;
@property (nonatomic,retain) NSString *headLine;
@end

@class LinkedInEngine;

@protocol LinkedInAuthDelegate <NSObject>
- (void)linkedInEngine:(LinkedInEngine*)engine webviewWillAppear:(UIWebView*)view;
- (void)linkedInEngine:(LinkedInEngine*)engine accessTokenResult:(OAToken *)accessToken;
- (void)linkedInEngine:(LinkedInEngine*)engine accessTokenFailure:(NSString*)data canceled:(BOOL)canceld;
- (void)linkedInEngineRequestStart:(LinkedInEngine*)engine;
- (void)linkedInEngineRequestEnd:(LinkedInEngine*)engine;
- (void)linkedInEngine:(LinkedInEngine*)engine didLogin:(LinkedInUser*)user error:(NSData *)error;
@end

@interface LinkedInEngine : NSObject
@property (nonatomic,retain)LinkedInUser *user;
@property (nonatomic,assign)id<LinkedInAuthDelegate>delegate;
- (id)initWithApiKey:(NSString *)apiKey secretkey:(NSString*)secretkey callbackUrl:(NSString*)callbackUrl;
- (void)login;

@end
