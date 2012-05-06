//
//  SyncData.m
//  Prismo
//
//  Created by Sergey Lenkov on 25.07.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSSyncData.h"

@implementation PSSyncData

@synthesize delegate;

- (id)initWithOriginalDB:(sqlite3 *)original andSyncDB:(sqlite3 *)sync {
    self = [super init];
    
    if (self) {
        originalDB = original;
        syncDB = sync;
    }
    
    return self;
}

- (void)startSync {
    [self syncSales];
    [self syncReviews];
    [self syncRatings];
    [self syncRanks];
    [self syncApplications];
    
    sqlite3_close(syncDB);
}

- (void)syncThread {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [self syncSales];
    [self syncReviews];
    [self syncRatings];
    [self syncRanks];
    [self syncApplications];
    
    sqlite3_close(syncDB);
    
    [self performSelectorOnMainThread:@selector(syncComplete) withObject:nil waitUntilDone:NO];
    
    [pool release];
}

- (void)syncComplete {
    if (delegate && [delegate respondsToSelector:@selector(syncDataDidComplete:)]) {
        [delegate syncDataDidComplete:self];
    }
}

- (void)syncSales {
    NSDate *minDate = [self minSalesDate];
    NSDate *maxDate = [self maxSalesDate];
    NSDate *minSyncDate = [self minSalesDate];
    NSDate *maxSyncDate = [self maxSalesDate];
    
    NSString *sql = @"SELECT MIN(date) FROM sales";
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(syncDB, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        if (sqlite3_step(statement) == SQLITE_ROW) {
            if (sqlite3_column_double(statement, 0) > 0) {
                minSyncDate = [NSDate dateFromDbString:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)]];
            }
        }		
    }
    
    sqlite3_reset(statement);
    
    sql = @"SELECT MAX(date) FROM sales";
    
    if (sqlite3_prepare_v2(syncDB, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        if (sqlite3_step(statement) == SQLITE_ROW) {
            maxSyncDate = [NSDate dateFromDbString:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)]];
        }		
    }
    
    sqlite3_reset(statement);
    
    if ([minDate compare:minSyncDate] == NSOrderedDescending) {
        minDate = minSyncDate;
    }
    
    if ([maxDate compare:maxSyncDate] == NSOrderedAscending) {
        maxDate = maxSyncDate;
    }
    
    int days = [minDate daysCountBetweenDate:maxDate];
    
    for (int i = 0; i <= days; i++) {
         NSDate *date = [minDate dateByAddingDays:i];
        
        if ([self salesForDate:date] == 0) {
            NSString *selectSQL = @"SELECT developer, application_name, application_id, apple_id, type_id, units, currency_code, country_code, price, royalty, date, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad FROM sales WHERE date = ?";
            NSString *insertSQL = @"INSERT INTO sales (developer, application_name, application_id, apple_id, type_id, units, currency_code, country_code, price, royalty, date, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            sqlite3_stmt *selectStatement;
            sqlite3_stmt *insertStatement;
            sqlite3_stmt *transactionStatement;

            sqlite3_prepare_v2(originalDB, [@"BEGIN TRANSACTION;" UTF8String], -1, &transactionStatement, NULL);
            sqlite3_step(transactionStatement);
            sqlite3_finalize(transactionStatement);
            
            if (sqlite3_prepare_v2(syncDB, [selectSQL UTF8String], -1, &selectStatement, NULL) == SQLITE_OK) {
                sqlite3_bind_text(selectStatement, 1, [[date dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
                
                while (sqlite3_step(selectStatement) == SQLITE_ROW) {					
                    if (sqlite3_prepare_v2(originalDB, [insertSQL UTF8String], -1, &insertStatement, NULL) == SQLITE_OK) {
                        sqlite3_bind_text(insertStatement, 1, [[NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStatement, 0)] UTF8String], -1, SQLITE_TRANSIENT);
                        sqlite3_bind_text(insertStatement, 2, [[NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStatement, 1)] UTF8String], -1, SQLITE_TRANSIENT);
                        sqlite3_bind_text(insertStatement, 3, [[NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStatement, 2)] UTF8String], -1, SQLITE_TRANSIENT);
                        sqlite3_bind_text(insertStatement, 4, [[NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStatement, 3)] UTF8String], -1, SQLITE_TRANSIENT);
                        sqlite3_bind_text(insertStatement, 5, [[NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStatement, 4)] UTF8String], -1, SQLITE_TRANSIENT);
                        sqlite3_bind_int(insertStatement, 6, sqlite3_column_int(selectStatement, 5));
                        sqlite3_bind_text(insertStatement, 7, [[NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStatement, 6)] UTF8String], -1, SQLITE_TRANSIENT);
                        sqlite3_bind_text(insertStatement, 8, [[NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStatement, 7)] UTF8String], -1, SQLITE_TRANSIENT);
                        sqlite3_bind_double(insertStatement, 9, sqlite3_column_double(selectStatement, 8));
                        sqlite3_bind_double(insertStatement, 10, sqlite3_column_double(selectStatement, 9));
                        sqlite3_bind_text(insertStatement, 11, [[NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStatement, 10)] UTF8String], -1, SQLITE_TRANSIENT);
                        sqlite3_bind_double(insertStatement, 12, sqlite3_column_double(selectStatement, 11));
                        sqlite3_bind_double(insertStatement, 13, sqlite3_column_double(selectStatement, 12));
                        sqlite3_bind_double(insertStatement, 14, sqlite3_column_double(selectStatement, 13));
                        sqlite3_bind_double(insertStatement, 15, sqlite3_column_double(selectStatement, 14));
                        sqlite3_bind_double(insertStatement, 16, sqlite3_column_double(selectStatement, 15));
                        sqlite3_bind_double(insertStatement, 17, sqlite3_column_double(selectStatement, 16));
                        
                        sqlite3_step(insertStatement);							
                    }
                    
                    sqlite3_finalize(insertStatement);
                }		
            }
            
            sqlite3_finalize(selectStatement);
            
            sqlite3_prepare_v2(originalDB, [@"COMMIT;" UTF8String], -1, &transactionStatement, NULL);
            sqlite3_step(transactionStatement);
            sqlite3_finalize(transactionStatement);
        }
    }   
}

- (void)syncReviews {
    NSString *sql = @"SELECT id FROM reviews";
    sqlite3_stmt *statement;
    
	if (sqlite3_prepare_v2(syncDB, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        NSString *selectSQL = @"SELECT COUNT(*) FROM reviews WHERE store_id = ? AND application_id = ? AND title = ? AND name = ?";
        sqlite3_stmt *selectStatement;
        
		while (sqlite3_step(statement) == SQLITE_ROW) {
			PSReview *review = [[PSReview alloc] initWithPrimaryKey:sqlite3_column_int(statement, 0) database:syncDB];
            int count = 0;

            if (sqlite3_prepare_v2(originalDB, [selectSQL UTF8String], -1, &selectStatement, NULL) == SQLITE_OK) {
                sqlite3_bind_int(selectStatement, 1, review.store.identifier);
                sqlite3_bind_int(selectStatement, 2, review.application.identifier);
                sqlite3_bind_text(selectStatement, 3, [review.title UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(selectStatement, 4, [review.name UTF8String], -1, SQLITE_TRANSIENT);                    
                
                if (sqlite3_step(selectStatement) == SQLITE_ROW) {				
                    count = sqlite3_column_int(selectStatement, 0);
                }
            }
            
            sqlite3_finalize(selectStatement);

            if (count == 0) {
                PSReview *newReview = [[PSReview alloc] initWithPrimaryKey:-1 database:originalDB];
                
                newReview.title = review.title;
                newReview.text = review.text;
                newReview.name = review.name;
                newReview.rating = review.rating;
                newReview.version = review.version;
                newReview.store = review.store;
                newReview.application = review.application;
                newReview.date = review.date;
                newReview.isNew = review.isNew;
                
                [newReview save];
                [newReview release];
            }
            
			[review release];
		}
	}
	
	sqlite3_finalize(statement);
}

- (void)syncRatings {
    NSString *sql = @"SELECT id FROM ratings";
    sqlite3_stmt *statement;
    
	if (sqlite3_prepare_v2(syncDB, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        NSString *selectSQL = @"SELECT id FROM ratings WHERE store_id = ? AND application_id = ?";
        sqlite3_stmt *selectStatement;
        
		while (sqlite3_step(statement) == SQLITE_ROW) {
			PSRating *rating = [[PSRating alloc] initWithPrimaryKey:sqlite3_column_int(statement, 0) database:syncDB];

            if (sqlite3_prepare_v2(originalDB, [selectSQL UTF8String], -1, &selectStatement, NULL) == SQLITE_OK) {
                sqlite3_bind_int(selectStatement, 1, rating.store.identifier);
                sqlite3_bind_int(selectStatement, 2, rating.application.identifier);
                sqlite3_bind_text(selectStatement, 3, [[rating.date dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
                
                if (sqlite3_step(selectStatement) == SQLITE_ROW) {				
                    PSRating *newRating = [[PSRating alloc] initWithPrimaryKey:sqlite3_column_int(statement, 0) database:originalDB];
                    
                    if ([rating.date timeIntervalSince1970] > [newRating.date timeIntervalSince1970]) {
                        newRating.stars5 = rating.stars5;
                        newRating.stars4 = rating.stars4;
                        newRating.stars3 = rating.stars3;
                        newRating.stars2 = rating.stars2;
                        newRating.stars1 = rating.stars1;
                        newRating.average = rating.average;
                        newRating.store = rating.store;
                        newRating.application = rating.application;
                        newRating.date = rating.date;
                        
                        [newRating save];
                    }
                                                               
                    [newRating release];
                } else {
                    PSRating *newRating = [[PSRating alloc] initWithPrimaryKey:-1 database:originalDB];
                    
                    newRating.stars5 = rating.stars5;
                    newRating.stars4 = rating.stars4;
                    newRating.stars3 = rating.stars3;
                    newRating.stars2 = rating.stars2;
                    newRating.stars1 = rating.stars1;
                    newRating.average = rating.average;
                    newRating.store = rating.store;
                    newRating.application = rating.application;
                    newRating.date = rating.date;
                    
                    [newRating save];
                    [newRating release];
                }
            }
            
            sqlite3_finalize(selectStatement);

			[rating release];
		}
	}
	
	sqlite3_finalize(statement);
}

- (void)syncRanks {
    NSString *sql = @"SELECT id FROM ranks";
    sqlite3_stmt *statement;
    
	if (sqlite3_prepare_v2(syncDB, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        NSString *selectSQL = @"SELECT COUNT(*) FROM ranks WHERE store_id = ? AND category_id = ? AND application_id = ? AND pop_id = ? AND date = ?";
        sqlite3_stmt *selectStatement;
        
		while (sqlite3_step(statement) == SQLITE_ROW) {
			PSRank *rank = [[PSRank alloc] initWithPrimaryKey:sqlite3_column_int(statement, 0) database:syncDB];
            int count = 0;
            
            if (sqlite3_prepare_v2(originalDB, [selectSQL UTF8String], -1, &selectStatement, NULL) == SQLITE_OK) {
                sqlite3_bind_int(selectStatement, 1, rank.store.identifier);
                sqlite3_bind_int(selectStatement, 2, rank.category.identifier);
                sqlite3_bind_int(selectStatement, 3, rank.application.identifier);
                sqlite3_bind_int(selectStatement, 4, rank.pop.identifier);
                sqlite3_bind_text(selectStatement, 5, [[rank.date dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
                
                if (sqlite3_step(selectStatement) == SQLITE_ROW) {				
                    count = sqlite3_column_int(selectStatement, 0);
                }
            }
            
            sqlite3_finalize(selectStatement);
            
            if (count == 0) {
                PSRank *newRank = [[PSRank alloc] initWithPrimaryKey:-1 database:originalDB];

                newRank.store = rank.store;
                newRank.category = rank.category;
                newRank.application = rank.application;
                newRank.pop = rank.pop;
                newRank.place = rank.place;
                newRank.date = rank.date;
                
                [newRank save];
                [newRank release];
            }
            
			[rank release];
		}
	}
	
	sqlite3_finalize(statement);
}

- (void)syncApplications {
    NSString *sql = @"SELECT id, name, type, account FROM applications";
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(syncDB, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        NSString *insertSQL = @"INSERT OR REPLACE INTO applications (id, name, type, account) VALUES (?, ?, ?, ?)";
        sqlite3_stmt *insertStatement;
    
        while (sqlite3_step(statement) == SQLITE_ROW) {
            if (sqlite3_prepare_v2(originalDB, [insertSQL UTF8String], -1, &insertStatement, NULL) == SQLITE_OK) {
                sqlite3_bind_int(insertStatement, 1, sqlite3_column_int(statement, 0));
                sqlite3_bind_text(insertStatement, 2, [[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)] UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(insertStatement, 3, [[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 2)] UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(insertStatement, 4, [[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 3)] UTF8String], -1, SQLITE_TRANSIENT);
        
                sqlite3_step(insertStatement);										
            }
        }
    }
    
    sqlite3_finalize(statement);
}

- (NSDate *)minSalesDate {
	NSString *sql = @"SELECT MIN(date) FROM sales";
	sqlite3_stmt *statement;
	NSDate *date = [NSDate date];
	
	if (sqlite3_prepare_v2(originalDB, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
		if (sqlite3_step(statement) == SQLITE_ROW) {			
			if (sqlite3_column_text(statement, 0) != NULL) {
				date = [NSDate dateFromDbString:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)]];
			}
		}		
	}
	
	sqlite3_finalize(statement);
    
	return date;
}

- (NSDate *)maxSalesDate {
	NSString *sql = @"SELECT MAX(date) FROM sales";
	sqlite3_stmt *statement;
	NSDate *date = [NSDate date];
	
	if (sqlite3_prepare_v2(originalDB, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
		if (sqlite3_step(statement) == SQLITE_ROW) {
            if (sqlite3_column_text(statement, 0) != NULL) {
                date = [NSDate dateFromDbString:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)]];
            }
		}		
	}
	
	sqlite3_finalize(statement);
    
	return date;
}

- (NSDate *)minRatingsDate {
	NSString *sql = @"SELECT MIN(date) FROM ratings";
	sqlite3_stmt *statement;
	NSDate *date = [NSDate date];
	
	if (sqlite3_prepare_v2(originalDB, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
		if (sqlite3_step(statement) == SQLITE_ROW) {
			if (sqlite3_column_double(statement, 0) > 0) {
				date = [NSDate dateFromDbString:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)]];
			}
		}		
	}
	
	sqlite3_finalize(statement);
    
	return date;
}

- (NSDate *)maxRatingsDate {
	NSString *sql = @"SELECT MAX(date) FROM ratings";
	sqlite3_stmt *statement;
	NSDate *date = [NSDate date];
	
	if (sqlite3_prepare_v2(originalDB, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
		if (sqlite3_step(statement) == SQLITE_ROW) {
			date = [NSDate dateFromDbString:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)]];
		}		
	}
	
	sqlite3_finalize(statement);
    
	return date;
}

- (NSDate *)minRanksDate {
	NSString *sql = @"SELECT MIN(date) FROM ranks";
	sqlite3_stmt *statement;
	NSDate *date = [NSDate date];
	
	if (sqlite3_prepare_v2(originalDB, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
		if (sqlite3_step(statement) == SQLITE_ROW) {
			if (sqlite3_column_double(statement, 0) > 0) {
				date = [NSDate dateFromDbString:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)]];
			}
		}		
	}
	
	sqlite3_finalize(statement);
    
	return date;
}

- (NSDate *)maxRanksDate {
	NSString *sql = @"SELECT MAX(date) FROM ranks";
	sqlite3_stmt *statement;
	NSDate *date = [NSDate date];
	
	if (sqlite3_prepare_v2(originalDB, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
		if (sqlite3_step(statement) == SQLITE_ROW) {
			date = [NSDate dateFromDbString:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)]];
		}		
	}
	
	sqlite3_finalize(statement);
    
	return date;
}

- (NSInteger)reviewsCount {
	NSString *sql = @"SELECT COUNT(*) FROM reviews";
	sqlite3_stmt *statement;
	NSInteger result = 0;
	
	if (sqlite3_prepare_v2(originalDB, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
		if (sqlite3_step(statement) == SQLITE_ROW) {
			result = sqlite3_column_int(statement, 0);
		}		
	}
	
	sqlite3_finalize(statement);
	return result;
}

- (NSInteger)salesForDate:(NSDate *)date {
	NSString *sql = @"SELECT COUNT(*) FROM sales WHERE date = ?";
	sqlite3_stmt *statement;
	int count = 0;
	
	if (sqlite3_prepare_v2(originalDB, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [[date dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
        
		if (sqlite3_step(statement) == SQLITE_ROW) {
			count = sqlite3_column_int(statement, 0);
		}
	}
	
	sqlite3_finalize(statement);	
	return count;
}

- (NSInteger)ranksForDate:(NSDate *)date {
	NSString *sql = @"SELECT COUNT(*) FROM ranks WHERE date = ?";	
	sqlite3_stmt *statement;
	int count = 0;
	
	if (sqlite3_prepare_v2(originalDB, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_text(statement, 1, [[date dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
        
		if (sqlite3_step(statement) == SQLITE_ROW) {
			count = sqlite3_column_int(statement, 0);
		}
	}
	
	sqlite3_finalize(statement);	
	return count;
}

@end
