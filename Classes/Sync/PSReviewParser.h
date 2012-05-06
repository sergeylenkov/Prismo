//
//  ReviewParser.h
//  Prismo
//
//  Created by Sergey Lenkov on 18.05.10.
//  Copyright 2010 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/GrowlApplicationBridge.h>
#import "ASIHTTPRequest.h"
#import "RegexKitLite.h"
#import "NSString+HTML.h"
#import "PSApplication.h"
#import "PSStore.h"
#import "PSReview.h"

@interface PSReviewParser : NSObject {
	sqlite3 *_db;
	id delegate;
	BOOL isCanceled;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) BOOL isCanceled;

- (id)initWithDatabase:(sqlite3 *)db;
- (void)parse;

- (NSString *)downloadReviewsForApplication:(PSApplication *)application store:(PSStore *)store page:(NSInteger)page;
- (void)importReviews:(NSArray *)reviews;
- (NSDate *)dateFromString:(NSString *)str;

- (void)startProgressAnimationWithTitle:(NSString *)title maxValue:(NSInteger)max indeterminate:(BOOL)indeterminate;
- (void)stopProgressAnimation;
- (void)incrementProgressIndicatorBy:(double)value;
- (void)changePhaseWithMessage:(NSString *)message;

@end
