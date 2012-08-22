//
//  PSReview.m
//  Prismo
//
//  Created by Sergey Lenkov on 04.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSReview.h"

@implementation PSReview

@synthesize identifier;
@synthesize name;
@synthesize title;
@synthesize version;
@synthesize text;
@synthesize rating;
@synthesize date;
@synthesize store;
@synthesize application;
@synthesize isNew;

- (void)dealloc {
	[name release];
	[title release];
	[version release];
	[text release];
	[date release];
 	[store release];
    [application release];
	[super dealloc];
}

- (id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db {
    self = [super init];
    
    if (self) {
        _db = db;
        self.identifier = pk;
        
        NSString *sql = @"SELECT title, name, text, rating, version, date, is_new, store_id, application_id FROM reviews WHERE id = ?";
        sqlite3_stmt *statement;
            
        if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_int(statement, 1, identifier);
                
            if (sqlite3_step(statement) == SQLITE_ROW) {
                title = [[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)] copy];
                name = [[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)] copy];
                text = [[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 2)] copy];
                rating = sqlite3_column_int(statement, 3);
                version = [[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 4)] copy];
                date = [[NSDate dateFromDbString:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 5)]] retain];
                isNew = sqlite3_column_int(statement, 6);                
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
        NSString *sql = @"INSERT INTO reviews (store_id, application_id, title, name, text, version, rating, date, is_new) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_int(statement, 1, store.identifier);
            sqlite3_bind_int(statement, 2, application.identifier);
            sqlite3_bind_text(statement, 3, [title UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 4, [name UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 5, [text UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 6, [version UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(statement, 7, rating);
            sqlite3_bind_text(statement, 8, [[date dbDateRepresentation] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(statement, 9, isNew);
            
            sqlite3_step(statement);										
        }
        
        sqlite3_finalize(statement);
    } else {
        NSString *sql = @"UPDATE reviews SET store_id = ?, application_id = ?, title = ?, name = ?, text = ?, version = ?, rating = ?, date = ?, is_new = ? WHERE id = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_int(statement, 10, identifier);
            
            sqlite3_bind_int(statement, 1, store.identifier);
            sqlite3_bind_int(statement, 2, application.identifier);
            sqlite3_bind_text(statement, 3, [title UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 4, [name UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 5, [text UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 6, [version UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(statement, 7, rating);
            sqlite3_bind_text(statement, 8, [[date dbDateRepresentation] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(statement, 9, isNew);
            
            sqlite3_step(statement);										
        }
        
        sqlite3_finalize(statement);
    }
}

- (void)deleteReviewsForApplication {
    NSString *sql = @"DELETE FROM reviews WHERE application_id = ?";
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_int(statement, 1, application.identifier);        
        sqlite3_step(statement);										
    }
    
    sqlite3_finalize(statement);
}

- (NSComparisonResult)compareName:(PSReview *)review {
	return [name compare:review.name];
}

- (NSComparisonResult)compareTitle:(PSReview *)review {
	return [title compare:review.title];
}

- (NSComparisonResult)compareVersion:(PSReview *)review {
	return [version compare:review.version];
}

- (NSComparisonResult)compareStore:(PSReview *)review {
	return [store.name compare:review.store.name];
}

- (NSComparisonResult)compareRating:(PSReview *)review {
	if (rating < review.rating) {
		return NSOrderedAscending;
	} else if (rating > review.rating) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

- (NSComparisonResult)compareDate:(PSReview *)review {
	if ([date timeIntervalSince1970] < [review.date timeIntervalSince1970]) {
		return NSOrderedAscending;
	} else if ([date timeIntervalSince1970] > [review.date timeIntervalSince1970]) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

- (NSComparisonResult)compareNew:(PSReview *)review {
    if (isNew < review.isNew) {
		return NSOrderedAscending;
	} else if (isNew > review.isNew) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

@end