//
//  PSSale.h
//  Prismo
//
//  Created by Sergey Lenkov on 30.05.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PSSale : NSObject {
    NSNumber *total;
	NSNumber *downloads;
	NSNumber *sales;
	NSNumber *updates;
	NSNumber *refunds;
	NSNumber *revenue;
	NSDate *date;
	NSString *description;
	NSMutableArray *details;
    BOOL isDetail;
}

@property (nonatomic, retain) NSNumber *total;
@property (nonatomic, retain) NSNumber *downloads;
@property (nonatomic, retain) NSNumber *sales;
@property (nonatomic, retain) NSNumber *updates;
@property (nonatomic, retain) NSNumber *refunds;
@property (nonatomic, retain) NSNumber *revenue;
@property (nonatomic, retain) NSDate *date;
@property (nonatomic, copy) NSString *description;
@property (nonatomic, retain) NSMutableArray *details;
@property (nonatomic, assign) BOOL isDetail;

- (NSComparisonResult)compareTotal:(PSSale *)sale;
- (NSComparisonResult)compareDownloads:(PSSale *)sale;
- (NSComparisonResult)compareSales:(PSSale *)sale;
- (NSComparisonResult)compareUpdates:(PSSale *)sale;
- (NSComparisonResult)compareRefunds:(PSSale *)sale;
- (NSComparisonResult)compareRevenue:(PSSale *)sale;
- (NSComparisonResult)compareDate:(PSSale *)sale;
- (NSComparisonResult)compareDescription:(PSSale *)sale;

@end
