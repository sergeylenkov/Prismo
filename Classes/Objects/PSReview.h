//
//  PSReview.h
//  Prismo
//
//  Created by Sergey Lenkov on 04.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PSStore.h"
#import "PSApplication.h"

@class PSStore, PSApplication;

@interface PSReview : NSObject {
    sqlite3 *_db;
    NSInteger identifier;
	NSString *name;
	NSString *title;
	NSString *version;
	NSString *text;
	NSInteger rating;
	NSDate *date;
    PSStore *store;
    PSApplication *application;
    BOOL isNew;
}

@property (nonatomic, assign) NSInteger identifier;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, assign) NSInteger rating;
@property (nonatomic, copy) NSDate *date;
@property (nonatomic, retain) PSStore *store;
@property (nonatomic, retain) PSApplication *application;
@property (nonatomic, assign) BOOL isNew;

- (id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db;
- (void)save;
- (void)deleteReviewsForApplication;

- (NSComparisonResult)compareName:(PSReview *)review;
- (NSComparisonResult)compareTitle:(PSReview *)review;
- (NSComparisonResult)compareVersion:(PSReview *)review;
- (NSComparisonResult)compareStore:(PSReview *)review;
- (NSComparisonResult)compareRating:(PSReview *)review;
- (NSComparisonResult)compareDate:(PSReview *)review;
- (NSComparisonResult)compareNew:(PSReview *)review;

@end
