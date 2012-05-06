//
//  SyncData.h
//  Prismo
//
//  Created by Sergey Lenkov on 25.07.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PSSyncData;

@protocol SyncDataDelegate <NSObject>

@required

- (void)syncDataDidComplete:(PSSyncData *)syncData;

@end

@interface PSSyncData : NSObject {
    sqlite3 *originalDB;
    sqlite3 *syncDB;
    id <SyncDataDelegate> delegate;
}

@property (nonatomic, assign) id <SyncDataDelegate> delegate;

- (id)initWithOriginalDB:(sqlite3 *)original andSyncDB:(sqlite3 *)sync;
- (void)startSync;
- (void)syncSales;
- (void)syncReviews;
- (void)syncRatings;
- (void)syncRanks;
- (void)syncApplications;
- (NSDate *)minSalesDate;
- (NSDate *)maxSalesDate;
- (NSDate *)minRatingsDate;
- (NSDate *)maxRatingsDate;
- (NSDate *)minRanksDate;
- (NSDate *)maxRanksDate;
- (NSInteger)reviewsCount;
- (NSInteger)salesForDate:(NSDate *)date;
- (NSInteger)ranksForDate:(NSDate *)date;

@end
