//
//  DropboxSync.h
//  Prismo
//
//  Created by Sergey Lenkov on 03.08.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OAuthConsumer/OAuthConsumer.h>
#import <Growl/GrowlApplicationBridge.h>
#import "PTKeychain.h"
#import "PSSyncData.h"
#import "ASIFormDataRequest.h"

@interface PSDropboxSync : NSObject {
    NSString *tempFile;
    id delegate;
    BOOL isCanceled;
    OAConsumer *consumer;
    OADataFetcher *fetcher;
    OAToken *requestToken;
    OAToken *accessToken;
    OAPlaintextSignatureProvider *provider;
}

@property (nonatomic, retain) id delegate;
@property (nonatomic, assign) BOOL isCanceled;

- (void)startSync;

- (void)requestTokenTicket;
- (void)accessTokenTicket;
- (void)loadFromDropbox;
- (void)uploadToDropbox;

- (void)startProgressAnimationWithTitle:(NSString *)title maxValue:(NSInteger)max indeterminate:(BOOL)indeterminate;
- (void)stopProgressAnimation;
- (void)incrementProgressIndicatorBy:(double)value;
- (void)changePhaseWithMessage:(NSString *)message;

@end
