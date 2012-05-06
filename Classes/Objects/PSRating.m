//
//  PSRating.m
//  Prismo
//
//  Created by Sergey Lenkov on 04.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSRating.h"

@implementation PSRating

@synthesize identifier;
@synthesize average;
@synthesize stars5;
@synthesize stars4;
@synthesize stars3;
@synthesize stars2;
@synthesize stars1;
@synthesize date;
@synthesize application;
@synthesize store;

- (void)dealloc {
    [average release];
  	[date release];
	[application release];
	[store release];
	[super dealloc];
}

- (id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db {
    self = [super init];
    
    if (self) {
        _db = db;
        self.identifier = pk;
        
        NSString *sql = @"SELECT stars_5, stars_4, stars_3, stars_2, stars_1, average, date, store_id, application_id FROM ratings WHERE id = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_int(statement, 1, identifier);
            
            if (sqlite3_step(statement) == SQLITE_ROW) {                
                stars5 = sqlite3_column_int(statement, 0);
                stars4 = sqlite3_column_int(statement, 1);
                stars3 = sqlite3_column_int(statement, 2);
                stars2 = sqlite3_column_int(statement, 3);
                stars1 = sqlite3_column_int(statement, 4);
                average = [[NSNumber numberWithDouble:sqlite3_column_double(statement, 5)] retain];
                date = [[NSDate dateFromDbString:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 6)]] retain];
                store = [[PSStore alloc] initWithPrimaryKey:sqlite3_column_int(statement, 7) database:_db];
                application = [[PSApplication alloc] initWithPrimaryKey:sqlite3_column_int(statement, 8) database:_db];
            }
        }
        
        sqlite3_finalize(statement);
    }
    
    return self;
}

- (void)save {
    if (identifier == -1) {
        NSString *sql = @"INSERT INTO ratings (store_id, application_id, stars_5, stars_4, stars_3, stars_2, stars_1, average, date) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_int(statement, 1, store.identifier);
            sqlite3_bind_int(statement, 2, application.identifier);
            sqlite3_bind_int(statement, 3, stars5);
            sqlite3_bind_int(statement, 4, stars4);
            sqlite3_bind_int(statement, 5, stars3);
            sqlite3_bind_int(statement, 6, stars2);
            sqlite3_bind_int(statement, 7, stars1);
            sqlite3_bind_double(statement, 8, [average doubleValue]);
            sqlite3_bind_text(statement, 9, [[date dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
            
            sqlite3_step(statement);										
        }
        
        sqlite3_finalize(statement);
    } else {
        NSString *sql = @"UPDATE ratings SET store_id = ?, application_id = ?, stars_5 = ?, stars_4 = ?, stars_3 = ?, stars_2 = ?, stars_1 = ?, average = ?, date = ? WHERE id = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_int(statement, 10, identifier);
            
            sqlite3_bind_int(statement, 1, store.identifier);
            sqlite3_bind_int(statement, 2, application.identifier);
            sqlite3_bind_int(statement, 3, stars5);
            sqlite3_bind_int(statement, 4, stars4);
            sqlite3_bind_int(statement, 5, stars3);
            sqlite3_bind_int(statement, 6, stars2);
            sqlite3_bind_int(statement, 7, stars1);
            sqlite3_bind_double(statement, 8, [average doubleValue]);
            sqlite3_bind_text(statement, 9, [[date dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
            
            sqlite3_step(statement);										
        }
        
        sqlite3_finalize(statement);
    }
}

- (void)deleteRatingsForApplication {
    NSString *sql = @"DELETE FROM ratings WHERE application_id = ?";
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_int(statement, 1, application.identifier);        
        sqlite3_step(statement);										
    }
    
    sqlite3_finalize(statement);
}

- (NSComparisonResult)compareStore:(PSRating *)rating {
	return [store.name compare:rating.store.name];
}

- (NSComparisonResult)compareAverage:(PSRating *)rating {
	if (average < rating.average) {
		return NSOrderedAscending;
	} else if (average > rating.average) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

- (NSComparisonResult)compareStars5:(PSRating *)rating {
	if (stars5 < rating.stars5) {
		return NSOrderedAscending;
	} else if (stars5 > rating.stars5) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

- (NSComparisonResult)compareStars4:(PSRating *)rating {
	if (stars4 < rating.stars4) {
		return NSOrderedAscending;
	} else if (stars4 > rating.stars4) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

- (NSComparisonResult)compareStars3:(PSRating *)rating {
	if (stars3 < rating.stars3) {
		return NSOrderedAscending;
	} else if (stars3 > rating.stars3) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

- (NSComparisonResult)compareStars2:(PSRating *)rating {
	if (stars2 < rating.stars2) {
		return NSOrderedAscending;
	} else if (stars2 > rating.stars2) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

- (NSComparisonResult)compareStars1:(PSRating *)rating {
	if (stars1 < rating.stars1) {
		return NSOrderedAscending;
	} else if (stars1 > rating.stars1) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

@end
