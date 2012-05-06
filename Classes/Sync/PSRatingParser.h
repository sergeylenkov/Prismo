//
//  RatingParser.m
//  Prismo
//
//  Created by Sergey Lenkov on 09.04.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/GrowlApplicationBridge.h>
#import "ASIHTTPRequest.h"
#import "RegexKitLite.h"
#import "NSString+HTML.h"
#import "PSApplication.h"
#import "PSStore.h"
#import "PSRating.h"

@interface PSRatingParser : NSObject {
	sqlite3 *_db;
	id delegate;
	BOOL isCanceled;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) BOOL isCanceled;

- (id)initWithDatabase:(sqlite3 *)db;
- (void)parse;
- (void)importRatings:(NSArray *)ratings;

- (void)startProgressAnimationWithTitle:(NSString *)title maxValue:(NSInteger)max indeterminate:(BOOL)indeterminate;
- (void)stopProgressAnimation;
- (void)incrementProgressIndicatorBy:(double)value;
- (void)changePhaseWithMessage:(NSString *)message;

@end
