//
//  PSRating.h
//  Prismo
//
//  Created by Sergey Lenkov on 04.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PSRating : NSObject {
    sqlite3 *_db;
    NSInteger identifier;	
	NSInteger stars5;
	NSInteger stars4;
	NSInteger stars3;
	NSInteger stars2;
	NSInteger stars1;
    NSNumber *average;
	NSDate *date;
    PSApplication *application;
	PSStore *store;
}

@property (nonatomic, assign) NSInteger identifier;
@property (nonatomic, assign) NSInteger stars5;
@property (nonatomic, assign) NSInteger stars4;
@property (nonatomic, assign) NSInteger stars3;
@property (nonatomic, assign) NSInteger stars2;
@property (nonatomic, assign) NSInteger stars1;
@property (nonatomic, retain) NSNumber *average;
@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) PSApplication *application;
@property (nonatomic, retain) PSStore *store;

- (id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db;
- (void)save;
- (void)deleteRatingsForApplication;

- (NSComparisonResult)compareStore:(PSRating *)rating;
- (NSComparisonResult)compareAverage:(PSRating *)rating;
- (NSComparisonResult)compareStars5:(PSRating *)rating;
- (NSComparisonResult)compareStars4:(PSRating *)rating;
- (NSComparisonResult)compareStars3:(PSRating *)rating;
- (NSComparisonResult)compareStars2:(PSRating *)rating;
- (NSComparisonResult)compareStars1:(PSRating *)rating;

@end
