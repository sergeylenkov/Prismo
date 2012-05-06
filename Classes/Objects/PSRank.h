//
//  PSRank.h
//  Prismo
//
//  Created by Sergey Lenkov on 04.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PSStore.h"
#import "PSCategory.h"
#import "PSPop.h"
#import "PSApplication.h"

@interface PSRank : NSObject {
    sqlite3 *_db;
    NSInteger identifier;
    PSStore *store;
    PSCategory *category;
    PSPop *pop;
    PSApplication *application;
	NSInteger place;
	NSDate *date;
}

@property (nonatomic, assign) NSInteger identifier;
@property (nonatomic, retain) PSStore *store;
@property (nonatomic, retain) PSCategory *category;
@property (nonatomic, retain) PSPop *pop;
@property (nonatomic, retain) PSApplication *application;
@property (nonatomic, assign) NSInteger place;
@property (nonatomic, retain) NSDate *date;

- (id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db;
- (void)save;

- (NSComparisonResult)compareDate:(PSRank *)rank;
- (NSComparisonResult)compareRanks:(PSRank *)rank;

@end
