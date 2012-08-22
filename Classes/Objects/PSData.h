//
//  PSData.h
//  Prismo
//
//  Created by Sergey Lenkov on 21.11.10.
//  Copyright 2010 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PSSale.h"
#import "PSReview.h"
#import "PSRating.h"
#import "PSRank.h"
#import "PSCategory.h"
#import "PSStore.h"
#import "PSPop.h"
#import "PSApplication.h"
#import "PSCountry.h"
#import "PSCountrySale.h"
#import "PSTop.h"

@interface PSData : NSObject {
    @private
    sqlite3 *_db;
    NSMutableArray *_applications;
    NSMutableArray *_purchases;
    NSMutableArray *_subscriptions;
    NSMutableArray *_allSaleItems;
    NSMutableArray *_stores;
    NSMutableArray *_categories;
    NSMutableArray *_countries;
    NSMutableArray *_pops;
    NSMutableDictionary *_countriesDictionary;
    NSArray *_saleTypes;
    NSArray *_updateTypes;
    NSArray *_appTypes;    
    NSString *_currencyColumn;
    NSString *_currencySymbol;
    NSUserDefaults *defaults;
    NSString *_euroZoneCodes;
    NSString *_americasCodes;
    NSMutableArray *_graphTypes;
}

@property (nonatomic, assign, readonly) sqlite3 *db;
@property (nonatomic, retain, readonly) NSArray *applications;
@property (nonatomic, retain, readonly) NSArray *purchases;
@property (nonatomic, retain, readonly) NSArray *subscriptions;
@property (nonatomic, retain, readonly) NSArray *allSaleItems;
@property (nonatomic, retain, readonly) NSArray *stores;
@property (nonatomic, retain, readonly) NSArray *categories;
@property (nonatomic, retain, readonly) NSArray *countries;
@property (nonatomic, retain, readonly) NSArray *saleTypes;
@property (nonatomic, retain, readonly) NSArray *updateTypes;
@property (nonatomic, retain, readonly) NSArray *appTypes;
@property (nonatomic, retain, readonly) NSArray *pops;
@property (nonatomic, retain, readonly) NSString *currencyColumn;
@property (nonatomic, retain, readonly) NSString *currencySymbol;
@property (nonatomic, retain, readonly) NSMutableArray *graphTypes;

+ (PSData *)sharedData;

- (NSString *)countryNameByCode:(NSString *)code;
- (void)reloadData;
- (void)reloadReferences;
- (NSInteger)newReviewsCount;
- (NSInteger)totalDownloads;
- (NSArray *)salesFromDate:(NSDate *)from toDate:(NSDate *)to;
- (NSArray *)salesFromDate:(NSDate *)from toDate:(NSDate *)to application:(PSApplication *)application;
- (PSSale *)saleForDate:(NSDate *)date;
- (PSSale *)saleForDate:(NSDate *)date application:(PSApplication *)application;
- (PSSale *)totalSaleFromDate:(NSDate *)from toDate:(NSDate *)to application:(PSApplication *)application;
- (PSSale *)totalSaleForApplication:(PSApplication *)application;
- (PSSale *)totalSale;
- (NSArray *)salesByCountriesFromDate:(NSDate *)from toDate:(NSDate *)to;
- (NSArray *)salesByCountriesFromDate:(NSDate *)from toDate:(NSDate *)to application:(PSApplication *)application;
- (NSDictionary *)revenueByCurrenciesFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate;
- (NSDictionary *)revenueByCurrenciesFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate application:(PSApplication *)application;
- (NSNumber *)revenueForRegion:(NSString *)region fromDate:(NSDate *)fromDate toDate:(NSDate *)toDate;
- (NSNumber *)revenueForRegion:(NSString *)region fromDate:(NSDate *)fromDate toDate:(NSDate *)toDate application:(PSApplication *)application;
- (NSNumber *)revenueFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate;
- (NSNumber *)revenueFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate application:(PSApplication *)application;
- (NSDate *)minDateForTop:(PSTop *)top application:(PSApplication *)application;
- (NSDate *)maxDateForTop:(PSTop *)top application:(PSApplication *)application;
- (NSDate *)minSaleDate;
- (NSDate *)maxSaleDate;
- (NSDate *)minSaleDateForApplication:(PSApplication *)application;
- (NSDate *)maxSaleDateForApplication:(PSApplication *)application;
- (NSArray *)reviewsForApplication:(PSApplication *)application;
- (NSArray *)ratingsForApplication:(PSApplication *)application;
- (NSArray *)ranksForApplication:(PSApplication *)application;
- (NSArray *)ranksFromDate:(NSDate *)from toDate:(NSDate *)to application:(PSApplication *)application top:(PSTop *)top;

@end
