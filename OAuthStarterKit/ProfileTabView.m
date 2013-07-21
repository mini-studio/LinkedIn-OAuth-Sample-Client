//
//  iPhone OAuth Starter Kit
//
//  Supported providers: LinkedIn (OAuth 1.0a)
//
//  Lee Whitney
//  http://whitneyland.com
//

#import <Foundation/NSNotificationQueue.h>
#import "ProfileTabView.h"
#import "OAuthViewController.h"


@implementation ProfileTabView

@synthesize button, name, headline, oAuthLoginView, 
            status, postButton, postButtonLabel,
            statusTextView, updateStatusLabel;

- (IBAction)button_TouchUp:(UIButton *)sender
{    
    oAuthLoginView = [[OAuthLoginView alloc] initWithNibName:nil bundle:nil];
    [oAuthLoginView retain];
 
    // register to be told when the login is finished
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(loginViewDidFinish:) 
                                                 name:@"loginViewDidFinish" 
                                               object:oAuthLoginView];
//    OAuthViewController *oAuthLoginView = [[OAuthViewController alloc] init];
    [self presentModalViewController:oAuthLoginView animated:YES];
}


-(void) loginViewDidFinish:(NSNotification*)notification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // We're going to do these calls serially just for easy code reading.
    // They can be done asynchronously
    // Get the profile, then the network updates
    [self profileApiCall];
	
}


- (void)profileApiCall
{
    //NSString *addr = @"http://api.linkedin.com/v1/people/id=145549875";
    //NSString *addr = @"http://api.linkedin.com/v1/people/~";
    NSString *addr = @"https://api.linkedin.com/v1/people/~:(id)";
    NSURL *url = [NSURL URLWithString:addr];
    OAMutableURLRequest *request = 
    [[OAMutableURLRequest alloc] initWithURL:url
                                    consumer:oAuthLoginView.consumer
                                       token:oAuthLoginView.accessToken
                                    callback:nil
                           signatureProvider:nil];
    
    [request setValue:@"json" forHTTPHeaderField:@"x-li-format"];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(profileApiCallResult:didFinish:)
                  didFailSelector:@selector(profileApiCallResult:didFail:)];    
    [request release];
    
}

- (void)profileApiCallResult:(OAServiceTicket *)ticket didFinish:(NSData *)data 
{    
    NSError *error = nil;
    NSJSONSerialization *jsondata = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    
    if ( jsondata )
    {
        name.text = [[NSString alloc] initWithFormat:@"%@ %@",
                     [jsondata valueForKey:@"firstName"], [jsondata valueForKey:@"lastName"]];
        headline.text = [jsondata valueForKey:@"headline"];
        
        NSString *mid = [jsondata valueForKey:@"id"];
        
        NSLog(@"%@",mid);
    }
    
    // The next thing we want to do is call the network updates
    [self networkApiCall];

}

- (void)profileApiCallResult:(OAServiceTicket *)ticket didFail:(NSData *)error 
{
    NSLog(@"%@",[error description]);
}

- (void)networkApiCall
{
    NSURL *url = [NSURL URLWithString:@"http://api.linkedin.com/v1/people/~/network/updates?scope=self&count=1&type=STAT"];
    OAMutableURLRequest *request = 
    [[OAMutableURLRequest alloc] initWithURL:url
                                    consumer:oAuthLoginView.consumer
                                       token:oAuthLoginView.accessToken
                                    callback:nil
                           signatureProvider:nil];
    
    [request setValue:@"json" forHTTPHeaderField:@"x-li-format"];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(networkApiCallResult:didFinish:)
                  didFailSelector:@selector(networkApiCallResult:didFail:)];    
    [request release];
    
}

- (void)networkApiCallResult:(OAServiceTicket *)ticket didFinish:(NSData *)data 
{
//    NSString *responseBody = [[NSString alloc] initWithData:data
//                                                   encoding:NSUTF8StringEncoding];
//    
//    NSDictionary *person = [[[[[responseBody objectFromJSONString] 
//                                objectForKey:@"values"] 
//                                    objectAtIndex:0]
//                                        objectForKey:@"updateContent"]
//                                            objectForKey:@"person"];
    //[responseBody release];
    NSError *error = nil;
    NSJSONSerialization *jsondata = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    NSDictionary *person = [[[[jsondata valueForKey:@"values"]
                              objectAtIndex:0]
                             valueForKey:@"updateContent"]
                            valueForKey:@"person"];
    
    
    
    if ( [person valueForKey:@"currentStatus"] )
    {
        [postButton setHidden:false];
        [postButtonLabel setHidden:false];
        [statusTextView setHidden:false];
        [updateStatusLabel setHidden:false];
        status.text = [person objectForKey:@"currentStatus"];
    } else {
        [postButton setHidden:false];
        [postButtonLabel setHidden:false];
        [statusTextView setHidden:false];
        [updateStatusLabel setHidden:false];
        status.text = [[[[person valueForKey:@"personActivities"] 
                            valueForKey:@"values"]
                                objectAtIndex:0]
                                    valueForKey:@"body"];
        
    }
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)networkApiCallResult:(OAServiceTicket *)ticket didFail:(NSData *)error 
{
    NSLog(@"%@",[error description]);
}

- (IBAction)postButton_TouchUp:(UIButton *)sender
{    
    [statusTextView resignFirstResponder];
    NSURL *url = [NSURL URLWithString:@"http://api.linkedin.com/v1/people/~/shares"];
    OAMutableURLRequest *request = 
    [[OAMutableURLRequest alloc] initWithURL:url
                                    consumer:oAuthLoginView.consumer
                                       token:oAuthLoginView.accessToken
                                    callback:nil
                           signatureProvider:nil];
    
    NSDictionary *update = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [[NSDictionary alloc] 
                             initWithObjectsAndKeys:
                             @"anyone",@"code",nil], @"visibility", 
                            statusTextView.text, @"comment", nil];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    
   // NSString *updateString = [update JSONString];
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:update
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    NSString *updateString = [[NSString alloc] initWithData:jsonData
                                                   encoding:NSUTF8StringEncoding];
    [request setHTTPBodyWithString:updateString];
    [updateString release];
	[request setHTTPMethod:@"POST"];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(postUpdateApiCallResult:didFinish:)
                  didFailSelector:@selector(postUpdateApiCallResult:didFail:)];    
    [request release];
}

- (void)postUpdateApiCallResult:(OAServiceTicket *)ticket didFinish:(NSData *)data 
{
    // The next thing we want to do is call the network updates
    [self networkApiCall];
    
}

- (void)postUpdateApiCallResult:(OAServiceTicket *)ticket didFail:(NSData *)error 
{
    NSLog(@"%@",[error description]);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
