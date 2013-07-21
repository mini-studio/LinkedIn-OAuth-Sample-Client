//
//  LinkedInEngine.m
//  OAuthStarterKit
//
//  Created by Wuquancheng on 13-7-16.
//  Copyright (c) 2013年 self. All rights reserved.
//

#import "LinkedInEngine.h"
#import "OAMutableURLRequest.h"
#import "OADataFetcher.h"

@implementation LinkedInUser
@synthesize userId,lastName,firstName,headLine;
- (void)dealloc
{
    [userId release];
    [lastName release];
    [firstName release];
    [headLine release];
    [super dealloc];
}
@end

@interface LinkedInEngine ()<UIWebViewDelegate>

@property(nonatomic, retain) OAToken *requestToken;
@property(nonatomic, retain) OAToken *accessToken;
@property(nonatomic, retain) NSDictionary *profile;
@property(nonatomic, retain) OAConsumer *consumer;
@property(nonatomic, retain) NSURL *requestTokenURL;
@property(nonatomic, retain) NSURL *accessTokenURL;
@property(nonatomic, retain) NSURL *userLoginURL;

@property (nonatomic,retain) OADataFetcher *fetcher;

@property (nonatomic,retain)NSString *apikey;
@property (nonatomic,retain)NSString *secretkey;

@property (nonatomic,retain) NSString *linkedInCallbackURL;

@property (nonatomic,retain)UIWebView *webView;

- (void)accessTokenFromProvider;
- (void)allowUserToLogin;

@end

@implementation LinkedInEngine

@synthesize requestToken = _requestToken;
@synthesize accessToken = _accessToken;
@synthesize profile = _profile;
@synthesize consumer = _consumer;
@synthesize requestTokenURL = _requestTokenURL;
@synthesize accessTokenURL = _accessTokenURL;
@synthesize userLoginURL = _userLoginURL;
@synthesize apikey = _apikey;
@synthesize secretkey = _secretkey;
@synthesize linkedInCallbackURL = _linkedInCallbackURL;
@synthesize webView = _webView;
@synthesize fetcher = _fetcher;
@synthesize user = _user;;

@synthesize delegate=_delegate;

- (id)initWithApiKey:(NSString *)apiKey secretkey:(NSString*)secretkey callbackUrl:(NSString*)callbackUrl
{
    self = [super init];
    if ( self ) {
        self.apikey = apiKey;
        self.secretkey = secretkey;
        self.user = [[[LinkedInUser alloc] init] autorelease];
        self.fetcher = [[[OADataFetcher alloc] init] autorelease];
        self.linkedInCallbackURL = callbackUrl;
    }
    return self;
}

- (void)dealloc
{
    [_requestToken release];
    [_accessToken release];
    [_profile release];
    [_consumer release];
    [_requestTokenURL release];
    [_accessTokenURL release];
    [_userLoginURL release];
    [_apikey release];
    [_secretkey release];
    [_linkedInCallbackURL release];
    [_webView stopLoading];
    [_webView release];
    _fetcher.delegate = nil;
    [_fetcher release];
    _delegate = nil;
    [super dealloc];
}



- (void)initLinkedInApi
{   
    self.consumer = [[OAConsumer alloc] initWithKey:self.apikey
                                             secret:self.secretkey
                                              realm:@"http://api.linkedin.com/"];
    
    NSString *requestTokenURLString = @"https://api.linkedin.com/uas/oauth/requestToken";
    NSString *accessTokenURLString = @"https://api.linkedin.com/uas/oauth/accessToken";
    NSString *userLoginURLString = @"https://www.linkedin.com/uas/oauth/authorize";
    if ( self.linkedInCallbackURL.length == 0 )
    self.linkedInCallbackURL = @"hdlinked://linkedin/oauth";
    
    self.requestTokenURL = [[NSURL URLWithString:requestTokenURLString] retain];
    self.accessTokenURL = [[NSURL URLWithString:accessTokenURLString] retain];
    self.userLoginURL = [[NSURL URLWithString:userLoginURLString] retain];
}

- (void)requestTokenFromProvider
{
    OAMutableURLRequest *request =
    [[[OAMutableURLRequest alloc] initWithURL:self.requestTokenURL
                                     consumer:self.consumer
                                        token:nil
                                     callback:self.linkedInCallbackURL 
                            signatureProvider:nil] autorelease];
    
    [request setHTTPMethod:@"POST"];
    
    OARequestParameter *nameParam = [[OARequestParameter alloc] initWithName:@"scope"
                                                                       value:@"r_basicprofile+rw_nus"];
    NSArray *params = [NSArray arrayWithObjects:nameParam, nil];
    [request setParameters:params];
    OARequestParameter * scopeParameter=[OARequestParameter requestParameter:@"scope" value:@"r_fullprofile rw_nus"];
    
    [request setParameters:[NSArray arrayWithObject:scopeParameter]];
    
    [self.fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(requestTokenResult:didFinish:)
                  didFailSelector:@selector(requestTokenResult:didFail:)];
}

#pragma mark - delegate form OADataFetcher
- (void)requestTokenResult:(OAServiceTicket *)ticket didFinish:(NSData *)data
{
    if (ticket.didSucceed == NO)
        return;
    
    NSString *responseBody = [[NSString alloc] initWithData:data
                                                   encoding:NSUTF8StringEncoding];
    self.requestToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
    [responseBody release];
    [self allowUserToLogin];
}

- (void)requestTokenResult:(OAServiceTicket *)ticket didFail:(NSError *)error
{
    if ( self.delegate)
    [self.delegate linkedInEngine:self accessTokenFailure:[error localizedDescription] canceled:YES];
}

- (void)allowUserToLogin
{
    NSString *userLoginURLWithToken = [NSString stringWithFormat:@"%@?oauth_token=%@", self.userLoginURL.absoluteString, self.requestToken.key];
    
    self.userLoginURL = [NSURL URLWithString:userLoginURLWithToken];
    NSURLRequest *request = [NSMutableURLRequest requestWithURL: self.userLoginURL];
    UIWebView *view = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    view.delegate = self;
    [self.delegate linkedInEngine:self webviewWillAppear:view];
    [view loadRequest:request];
    self.webView = view;
}

#pragma mark - delegate for webview

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (self.delegate) {
 	NSURL *url = request.URL;
	NSString *urlString = url.absoluteString;
    
    BOOL requestForCallbackURL = ([urlString rangeOfString:self.linkedInCallbackURL].location != NSNotFound);
    if ( requestForCallbackURL )
    {
        BOOL userAllowedAccess = ([urlString rangeOfString:@"user_refused"].location == NSNotFound);
        if ( userAllowedAccess )
        {
            [self.requestToken setVerifierWithUrl:url];
            [self accessTokenFromProvider];
        }
        else
        {
            [self.delegate linkedInEngine:self accessTokenFailure:nil canceled:YES];
        }
        return NO;
    }
	return YES;
    }
    return NO;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    if (self.delegate)
    [self.delegate linkedInEngineRequestStart:self];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (self.delegate)
    [self.delegate linkedInEngineRequestEnd:self];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if (self.delegate) {
    [self.delegate linkedInEngineRequestEnd:self];
    [self.delegate linkedInEngine:self accessTokenFailure:[error localizedDescription] canceled:NO];
    }
}

- (void)accessTokenFromProvider
{
    OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:self.accessTokenURL
                                                                    consumer:self.consumer
                                                                       token:self.requestToken
                                                                    callback:nil
                                                           signatureProvider:nil] autorelease];
    
    [request setHTTPMethod:@"POST"];
    [self.fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(accessTokenResult:didFinish:)
                  didFailSelector:@selector(accessTokenResult:didFail:)];
}

- (void)accessTokenResult:(OAServiceTicket *)ticket didFinish:(NSData *)data
{
    if (self.delegate) {
        NSString *responseBody = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        BOOL problem = ([responseBody rangeOfString:@"oauth_problem"].location != NSNotFound);
        if ( problem ) {
            [self.delegate linkedInEngine:self accessTokenFailure:responseBody canceled:NO];
        } else {
            self.accessToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
           
            [self.delegate linkedInEngine:self accessTokenResult:self.accessToken];
            [self fetchProfile];
        }
    }
}

- (void)accessTokenResult:(OAServiceTicket *)ticket didFail:(NSError *)error
{
     if (self.delegate)
     [self.delegate linkedInEngine:self accessTokenFailure:[error localizedDescription] canceled:NO];
}

- (void)login
{
    [self initLinkedInApi];
    [self requestTokenFromProvider];
}

- (void)fetchProfile
{
    //NSString *addr = @"https://api.linkedin.com/v1/people/~";
    NSString *addr = @"https://api.linkedin.com/v1/people/~:(id)";
    NSURL *url = [NSURL URLWithString:addr];
    OAMutableURLRequest *request =
    [[OAMutableURLRequest alloc] initWithURL:url
                                    consumer:self.consumer
                                       token:self.accessToken
                                    callback:nil
                           signatureProvider:nil];
    
    [request setValue:@"json" forHTTPHeaderField:@"x-li-format"];
    
    [self.fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(profileApiCallResult:didFinish:)
                  didFailSelector:@selector(profileApiCallResult:didFail:)];
    [request release];

}

- (void)profileApiCallResult:(OAServiceTicket *)ticket didFinish:(NSData *)data
{
    NSError *error = nil;
    NSJSONSerialization *jsondata = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    
    if ( jsondata ) {
        NSString *lastName =  [jsondata valueForKey:@"lastName"];
        if ( lastName.length > 0 ) {
            self.user.lastName = lastName;
        }
        NSString *firstName = [jsondata valueForKey:@"firstName"];
        if ( firstName.length > 0 ) {
            self.user.firstName = firstName;
        }
        NSString *headLine =  [jsondata valueForKey:@"headline"];
        if ( headLine.length > 0 ) {
            self.user.headLine = headLine;
        }
        NSString *mid = [jsondata valueForKey:@"id"];
        if ( mid.length > 0 ) {
            self.user.userId = mid;
        }
    }
    if (self.delegate)
    [self.delegate linkedInEngine:self didLogin:self.user error:nil];
    
}

- (void)profileApiCallResult:(OAServiceTicket *)ticket didFail:(NSData *)error
{
     if (self.delegate)
    [self.delegate linkedInEngine:self didLogin:nil error:error];
}

- (void)setDelegate:(id<LinkedInAuthDelegate>)delegate
{
    _delegate = delegate;
    if ( _delegate == nil ) {
        [self.webView stopLoading];
        self.webView.delegate = nil;
        self.fetcher.delegate = nil;
    }
}
@end
