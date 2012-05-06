//
//  DropboxSync.m
//  Prismo
//
//  Created by Sergey Lenkov on 03.08.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSDropboxSync.h"

@implementation PSDropboxSync

@synthesize delegate;
@synthesize isCanceled;

- (void)dealloc {
    [tempFile release];
    [consumer release];
    [fetcher release];
    [requestToken release];
    [accessToken release];
    [provider release];
	[super dealloc];
}

- (id)init {
    self = [super init];
    
    if (self) {
        tempFile = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"Temp.sqlite"] copy];
        consumer = [[OAConsumer alloc] initWithKey:DROPBOX_KEY secret:DROPBOX_SECRET];
        fetcher = [[OADataFetcher alloc] init];
        requestToken = [[OAToken alloc] initWithUserDefaultsUsingServiceProviderName:@"Dropbox" prefix:@"Request"];
        accessToken = [[OAToken alloc] initWithUserDefaultsUsingServiceProviderName:@"Dropbox" prefix:@"Access"];
        provider = [[OAPlaintextSignatureProvider alloc] init];
    }
    
    return self;
}

- (void)startSync {
    if (!requestToken && !accessToken) {
        [self requestTokenTicket];   
    } else {
        if (accessToken) {
            [self loadFromDropbox];
        } else {
            [self accessTokenTicket];
        }
    }
}

#pragma mark -
#pragma mark OAuth
#pragma mark -

- (void)requestTokenTicket {
    if (isCanceled) {
        return;
    }
    
    NSURL *url = [NSURL URLWithString:@"https://api.dropbox.com/0/oauth/request_token"];
    
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url consumer:consumer token:nil realm:nil signatureProvider:provider];
    [request prepare];
    
    ASIFormDataRequest *formRequest = [ASIFormDataRequest requestWithURL:url];
    formRequest.shouldRedirect = NO;

    [formRequest addRequestHeader:@"Content-Type" value:@"application/x-www-form-urlencoded"];
    [formRequest addRequestHeader:@"Authorization" value:[request.allHTTPHeaderFields objectForKey:@"Authorization"]];
    
    [formRequest startSynchronous];
    
    NSError *error = [formRequest error];

    if (error) {
        isCanceled = YES;
        [GrowlApplicationBridge notifyWithTitle:@"Sync" description:[error localizedDescription] notificationName:@"New event" iconData:nil priority:0 isSticky:NO clickContext:nil];
    } else {
        isCanceled = YES;
        
        requestToken = [[OAToken alloc] initWithHTTPResponseBody:[formRequest responseString]];
        [requestToken storeInUserDefaultsWithServiceProviderName:@"Dropbbox" prefix:@"Request"];
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.dropbox.com/0/oauth/authorize?oauth_token=%@", requestToken.key]];
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
    
    [request release];
}

- (void)accessTokenTicket {
    if (isCanceled) {
        return;
    }
    
    NSURL *url = [NSURL URLWithString:@"https://api.dropbox.com/0/oauth/access_token"];
    
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url consumer:consumer token:requestToken realm:nil signatureProvider:provider];
    [request prepare];
    
    ASIFormDataRequest *formRequest = [ASIFormDataRequest requestWithURL:url];
    formRequest.shouldRedirect = NO;
    
    [formRequest addRequestHeader:@"Content-Type" value:@"application/x-www-form-urlencoded"];
    [formRequest addRequestHeader:@"Authorization" value:[request.allHTTPHeaderFields objectForKey:@"Authorization"]];
    
    [formRequest startSynchronous];
    
    NSError *error = [formRequest error];

    if (error) {
        isCanceled = YES;
        [GrowlApplicationBridge notifyWithTitle:@"Sync" description:[NSString stringWithFormat:@"Network Error %@", [error localizedDescription]] notificationName:@"New event" iconData:nil priority:0 isSticky:NO clickContext:nil];
    } else {
        accessToken = [[OAToken alloc] initWithHTTPResponseBody:[formRequest responseString]];
        [accessToken storeInUserDefaultsWithServiceProviderName:@"Dropbox" prefix:@"Access"];
        
        [self loadFromDropbox];
    }
    
    [request release];
}

- (void)loadFromDropbox {
    if (isCanceled) {
        return;
    }
    
    [self changePhaseWithMessage:@"Downloading data..."];
    
    NSURL *url = [NSURL URLWithString:@"https://api-content.dropbox.com/0/files/dropbox/Database.prismo"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url consumer:consumer token:accessToken realm:nil signatureProvider:provider];
    [request prepare];
    
    ASIHTTPRequest *formRequest = [ASIHTTPRequest requestWithURL:url];
    formRequest.shouldRedirect = NO;
    formRequest.timeOutSeconds = 60;
    
    [formRequest addRequestHeader:@"User-Agent" value:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_3; en-us) AppleWebKit/525.18 (KHTML, like Gecko) Version/3.1.1 Safari/525.20"];
    [formRequest addRequestHeader:@"Content-Type" value:@"application/x-www-form-urlencoded"];
    [formRequest addRequestHeader:@"Authorization" value:[request.allHTTPHeaderFields objectForKey:@"Authorization"]];
    
    [formRequest startSynchronous];
    
    [request release];

    NSError *error = [formRequest error];

    if (error) {
        if (formRequest.responseStatusCode == 401 || formRequest.responseStatusCode == 403) {
            requestToken = nil;
            accessToken = nil;
            
            [self startSync];
        } else if (error) {
            isCanceled = YES;
            [GrowlApplicationBridge notifyWithTitle:@"Sync" description:[error localizedDescription] notificationName:@"New event" iconData:nil priority:0 isSticky:NO clickContext:nil];
        }
    } else {
        if (formRequest.responseStatusCode == 404) {
            [self uploadToDropbox];
        } else {
            if (isCanceled) {
                return;
            }
            
            [[formRequest responseData] writeToFile:tempFile atomically:YES];
        
            sqlite3 *syncDatabase;
        
            if (sqlite3_open([tempFile UTF8String], &syncDatabase) == SQLITE_OK) {
                [self changePhaseWithMessage:@"Sync data..."];
                
                PSSyncData *syncData = [[PSSyncData alloc] initWithOriginalDB:[Database sharedDatabase] andSyncDB:syncDatabase];
            
                [syncData startSync];
                [syncData release];
                
                [[NSFileManager defaultManager] removeItemAtPath:tempFile error:nil];
                [self uploadToDropbox];
            }
        }
    }
}

- (void)uploadToDropbox {
    if (isCanceled) {
        return;
    }
    
    [self changePhaseWithMessage:@"Uploading data..."];
    
    NSURL *url = [NSURL URLWithString:@"https://api-content.dropbox.com/0/files/dropbox/"];
    
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url consumer:consumer token:accessToken realm:nil signatureProvider:provider];
    [request setOAuthParameterName:@"file" withValue:@"Database.prismo"];
    [request prepare];
    
    ASIFormDataRequest *formRequest = [ASIFormDataRequest requestWithURL:url];
    formRequest.shouldRedirect = NO;
    
    [formRequest addRequestHeader:@"User-Agent" value:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_3; en-us) AppleWebKit/525.18 (KHTML, like Gecko) Version/3.1.1 Safari/525.20"];
    [formRequest addRequestHeader:@"Content-Type" value:@"application/x-www-form-urlencoded"];
    [formRequest addRequestHeader:@"Authorization" value:[request.allHTTPHeaderFields objectForKey:@"Authorization"]];
    
    [formRequest addFile:[Database path] withFileName:@"Database.prismo" andContentType:@"application/octet-stream" forKey:@"file"];
    
    [formRequest startSynchronous];
    
    NSError *error = [formRequest error];
    
    if (error) {
        isCanceled = YES;
        [GrowlApplicationBridge notifyWithTitle:@"Sync" description:[error localizedDescription] notificationName:@"New event" iconData:nil priority:0 isSticky:NO clickContext:nil];
    }
    
    [request release];
}

#pragma mark -
#pragma mark Delegate
#pragma mark -

- (void)startProgressAnimationWithTitle:(NSString *)title maxValue:(NSInteger)max indeterminate:(BOOL)indeterminate {
	if (delegate) {
		[delegate startProgressAnimationWithTitle:title maxValue:max indeterminate:indeterminate];
	}
}

- (void)stopProgressAnimation {
	if (delegate) {
		[delegate stopProgressAnimation];
	}
}

- (void)incrementProgressIndicatorBy:(double)value {
	if (delegate) {
		[delegate incrementProgressIndicatorBy:value];
	}
}

- (void)changePhaseWithMessage:(NSString *)message {
	if (delegate) {
		[delegate changePhaseWithMessage:message];
	}
}

@end
