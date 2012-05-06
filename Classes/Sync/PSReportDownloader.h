//
//  ReportDownloader.h
//  Prismo
//
//  Created by Sergey Lenkov on 26.05.10.
//  Copyright 2010 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/GrowlApplicationBridge.h>
#import "PTKeychain.h"
#import "NSData+GZip.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "RegexKitLite.h"

@interface PSReportDownloader : NSObject {
	sqlite3 *_db;
	id delegate;
	BOOL isCanceled;
    NSInteger step;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) BOOL isCanceled;

- (id)initWithDatabase:(sqlite3 *)db;
- (void)download;
- (BOOL)downloadDailyReportsForAccount:(NSString *)account withPassword:(NSString *)password vendor:(NSString *)vendor;
- (BOOL)isExistsSalesForAccount:(NSString *)appleID date:(NSDate *)date;
- (void)importFile:(NSString *)fileName forAccount:(NSString *)appleID;
- (NSDictionary *)tiersFroCurrency:(NSString *)currency royalty:(NSNumber *)royalty date:(NSDate *)date;

- (void)startProgressAnimationWithTitle:(NSString *)title maxValue:(NSInteger)max indeterminate:(BOOL)indeterminate;
- (void)stopProgressAnimation;
- (void)incrementProgressIndicatorBy:(double)value;
- (void)changePhaseWithMessage:(NSString *)message;
- (void)showWarningMessage:(NSString *)message;

@end
