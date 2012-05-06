//
//  PSRank.m
//  Prismo
//
//  Created by Sergey Lenkov on 04.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSRank.h"

@implementation PSRank

@synthesize identifier;
@synthesize store;
@synthesize category;
@synthesize pop;
@synthesize application;
@synthesize place;
@synthesize date;

- (void)dealloc {
    [store release];
    [category release];
    [pop release];
    [application release];
	[date release];
	[super dealloc];
}

- (id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db {
    self = [super init];
    
    if (self) {
        _db = db;
        self.identifier = pk;
        
        NSString *sql = @"SELECT store_id, category_id, pop_id, application_id, place, date FROM ranks WHERE id = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_int(statement, 1, identifier);
            
            if (sqlite3_step(statement) == SQLITE_ROW) {
                store = [[PSStore alloc] initWithPrimaryKey:sqlite3_column_int(statement, 0) database:_db];
                category = [[PSCategory alloc] initWithPrimaryKey:sqlite3_column_int(statement, 1) database:_db];
                pop = [[PSPop alloc] initWithPrimaryKey:sqlite3_column_int(statement, 2) database:_db];
                application = [[PSApplication alloc] initWithPrimaryKey:sqlite3_column_int(statement, 3) database:_db];
                place = sqlite3_column_int(statement, 4);
                self.date = [NSDate dateFromDbString:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 5)]];
                
            }
        }
        
        sqlite3_finalize(statement);
    }
    
    return self;
}

- (void)save {
    if (identifier == -1) {
        NSString *sql = @"INSERT INTO ranks (store_id, category_id, application_id, pop_id, place, date) VALUES (?, ?, ?, ?, ?, ?)";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_int(statement, 1, store.identifier);
            sqlite3_bind_int(statement, 2, category.identifier);
            sqlite3_bind_int(statement, 3, application.identifier);
            sqlite3_bind_int(statement, 4, pop.identifier);
            sqlite3_bind_int(statement, 5, place);
            sqlite3_bind_text(statement, 6, [[date dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
            
            sqlite3_step(statement);										
        }
        
        sqlite3_finalize(statement);
    }
}

- (NSComparisonResult)compareDate:(PSRank *)rank {
	if ([date timeIntervalSince1970] < [rank.date timeIntervalSince1970]) {
		return NSOrderedAscending;
	} else if ([date timeIntervalSince1970] > [rank.date timeIntervalSince1970]) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

- (NSComparisonResult)compareRanks:(PSRank *)rank {
	if (place < rank.place) {
		return NSOrderedAscending;
	} else if (place > rank.place) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

@end
