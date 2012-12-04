//
//  ReviewParser.m
//  Prismo
//
//  Created by Sergey Lenkov on 18.05.10.
//  Copyright 2010 Sergey Lenkov. All rights reserved.
//

#import "PSReviewParser.h"

@implementation PSReviewParser

@synthesize isCanceled;
@synthesize delegate;

- (id)initWithDatabase:(sqlite3 *)db {
    self = [super init];
    
	if (self) {
		_db = db;
	}
	
	return self;
}

- (void)parse {
    PSData *data = [PSData sharedData];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:[NSDate date] forKey:@"Last Reviews Update"];
	[defaults setObject:@"Unknown" forKey:@"Last Reviews Update Status"];
    
	NSMutableArray *reviews = [[NSMutableArray alloc] init];
	NSMutableArray *ratings = [[NSMutableArray alloc] init];
    
    NSDictionary *selectedApps = [defaults objectForKey:@"Selected Apps"];
    NSMutableArray *applications = [[NSMutableArray alloc] init];
    
    for (PSApplication *application in data.applications) {
        if ([[selectedApps objectForKey:[NSString stringWithFormat:@"%ld", application.identifier]] boolValue]) {
            [applications addObject:application];
        }
    }
    
	for (int i = 0; i < [applications count]; i++) {
		if (isCanceled) {
            [defaults setObject:@"Canceled" forKey:@"Last Reviews Update Status"];
			break;
		}
		
		PSApplication *application = [applications objectAtIndex:i];

		[reviews removeAllObjects];
        [ratings removeAllObjects];
        
		for (int i = 0; i < [data.stores count]; i++) {
			if (isCanceled) {
                [defaults setObject:@"Canceled" forKey:@"Last Reviews Update Status"];
				break;
			}
            
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			PSStore *store = [data.stores objectAtIndex:i];

			[self changePhaseWithMessage:[NSString stringWithFormat:@"%@ - %@", application.name, store.name]];

            NSString *url = [NSString stringWithFormat:@"http://client-api.itunes.apple.com/WebObjects/MZStore.woa/wa/customerReviews?update=1&id=%ld&displayable-kind=11", application.identifier];
            ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];

            request.timeOutSeconds = 60;
            request.shouldRedirect = NO;
            
            [request addRequestHeader:@"User-Agent" value:@"iTunes/11.0 (Macintosh; OS X 10.7.4) AppleWebKit/534.56.5"];
            [request addRequestHeader:@"X-Apple-Store-Front" value:[NSString stringWithFormat:@"%ld,17", store.identifier]];
            [request addRequestHeader:@"X-Apple-Partner" value:@"origin.0"];
            [request addRequestHeader:@"X-Apple-Connection-Type" value:@"WiFi"];
            [request addRequestHeader:@"X-Apple-Tz" value:@"14400"];

            [request startSynchronous];
            
            NSError *error = [request error];
            
            if (error) {
				[self stopProgressAnimation];
                [GrowlApplicationBridge notifyWithTitle:@"Reviews" description:[error localizedDescription] notificationName:@"New event" iconData:nil priority:0 isSticky:NO clickContext:nil];
			
                [defaults setObject:[error localizedDescription] forKey:@"Last Reviews Update Status"];
                
                isCanceled = YES;
                
				[pool release];
				
				return;
			}
            
            id response = [request.responseString JSONValue];

            if (response) {
                if ([[response objectForKey:@"totalNumberOfReviews"] intValue] > 0) {
                    for (id item in [response objectForKey:@"userReviewList"]) {
                        PSReview *review = [[PSReview alloc] initWithPrimaryKey:-1 database:_db];
                        
                        review.title = [[item objectForKey:@"title"] stringByRemovingNewLinesAndWhitespace];
                        review.text = [[item objectForKey:@"body"] stringByRemovingNewLinesAndWhitespace];
                        review.name = [[item objectForKey:@"name"] stringByRemovingNewLinesAndWhitespace];
                        review.rating = [[item objectForKey:@"rating"] intValue];
                        review.version = @"";
                        review.store = store;
                        review.application = application;
                        review.date = [self dateFromString:[item objectForKey:@"date"]];
                        
                        NSString *sql = @"SELECT COUNT(*) FROM reviews WHERE store_id = ? AND application_id = ? AND title = ? AND name = ?";
                        sqlite3_stmt *statement;
                        int count = 0;
                        
                        if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
                            sqlite3_bind_int(statement, 1, store.identifier);
                            sqlite3_bind_int(statement, 2, application.identifier);
                            sqlite3_bind_text(statement, 3, [review.title UTF8String], -1, SQLITE_TRANSIENT);
                            sqlite3_bind_text(statement, 4, [review.name UTF8String], -1, SQLITE_TRANSIENT);
                            
                            if (sqlite3_step(statement) == SQLITE_ROW) {
                                count = sqlite3_column_int(statement, 0);
                            }
                        }
                        
                        sqlite3_finalize(statement);
                        
                        if (count == 0) {
                            review.isNew = YES;
                        }
                        
                        [reviews addObject:review];
                        [review release];
                    }
                }
                
                if ([response objectForKey:@"ratingCountList"]) {
                    PSRating *rating = [[PSRating alloc] initWithPrimaryKey:-1 database:_db];
                    
                    rating.stars5 = [[[response objectForKey:@"ratingCountList"] objectAtIndex:4] intValue];
                    rating.stars4 = [[[response objectForKey:@"ratingCountList"] objectAtIndex:3] intValue];
                    rating.stars3 = [[[response objectForKey:@"ratingCountList"] objectAtIndex:2] intValue];
                    rating.stars2 = [[[response objectForKey:@"ratingCountList"] objectAtIndex:1] intValue];
                    rating.stars1 = [[[response objectForKey:@"ratingCountList"] objectAtIndex:0] intValue];
                    rating.average = [NSNumber numberWithFloat:[[response objectForKey:@"ratingAverage"] floatValue]];
                    rating.store = store;
                    rating.application = application;
                    rating.date = [NSDate date];
                    
                    [ratings addObject:rating];
                    [rating release];
                }
            }
 					
			[self incrementProgressIndicatorBy:1.0];
			
			[pool release];
		}
        
        [self importReviews:reviews];
        [self importRatings:ratings];
	}
    
	[reviews release];
    [ratings release];
    [applications release];
    
    if (!isCanceled) {
        [defaults setObject:@"Reviews updated successfully" forKey:@"Last Reviews Update Status"];
    }
    
    [defaults synchronize];
}

- (void)importReviews:(NSArray *)reviews {
	if (reviews == nil || [reviews count] == 0) {
		return;
	}
	
    NSString *sql = @"BEGIN TRANSACTION;";
	sqlite3_stmt *statement;
    
	sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL);
	sqlite3_step(statement);
	sqlite3_finalize(statement);
    
	PSReview *review = [reviews lastObject];
    [review deleteReviewsForApplication];	
	
	for (PSReview *review in reviews) {
		[review save];
	}
    
    sql = @"COMMIT;";
	
	sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL);
	sqlite3_step(statement);
	sqlite3_finalize(statement);
}

- (void)importRatings:(NSArray *)ratings {
	if (ratings == nil || [ratings count] == 0) {
		return;
	}
	
	PSRating *rating = [ratings lastObject];
    [rating deleteRatingsForApplication];
	
	for (PSRating *rating in ratings) {
		[rating save];
	}
}

- (NSDate *)dateFromString:(NSString *)str {
    NSDate *date = nil;
    
    str = [str stringByReplacingOccurrencesOfString:@"gen" withString:@"Jan"];
    str = [str stringByReplacingOccurrencesOfString:@"feb" withString:@"Feb"];
    str = [str stringByReplacingOccurrencesOfString:@"mar" withString:@"Mar"];
    str = [str stringByReplacingOccurrencesOfString:@"apr" withString:@"Apr"];
    str = [str stringByReplacingOccurrencesOfString:@"mag" withString:@"May"];
    str = [str stringByReplacingOccurrencesOfString:@"giu" withString:@"Jun"];
    str = [str stringByReplacingOccurrencesOfString:@"lug" withString:@"Jul"];
    str = [str stringByReplacingOccurrencesOfString:@"ago" withString:@"Aug"];
    str = [str stringByReplacingOccurrencesOfString:@"set" withString:@"Sep"];
    str = [str stringByReplacingOccurrencesOfString:@"ott" withString:@"Oct"];
    str = [str stringByReplacingOccurrencesOfString:@"nov" withString:@"Nov"];
    str = [str stringByReplacingOccurrencesOfString:@"dic" withString:@"Dec"];
    
    str = [str stringByReplacingOccurrencesOfString:@"janv." withString:@"Jan"];
    str = [str stringByReplacingOccurrencesOfString:@"févr." withString:@"Fev"];
    str = [str stringByReplacingOccurrencesOfString:@"mars" withString:@"Mar"];
    str = [str stringByReplacingOccurrencesOfString:@"avr." withString:@"Apr"];
    str = [str stringByReplacingOccurrencesOfString:@"mai" withString:@"May"];
    str = [str stringByReplacingOccurrencesOfString:@"juin" withString:@"Jun"];
    str = [str stringByReplacingOccurrencesOfString:@"juil." withString:@"Jul"];
    str = [str stringByReplacingOccurrencesOfString:@"aoút" withString:@"Avg"];
    str = [str stringByReplacingOccurrencesOfString:@"sept." withString:@"Sep"];
    str = [str stringByReplacingOccurrencesOfString:@"oct." withString:@"Oct"];
    str = [str stringByReplacingOccurrencesOfString:@"nov." withString:@"Nov"];
    str = [str stringByReplacingOccurrencesOfString:@"déc." withString:@"Dec"];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
	[formatter setLocale:locale];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    
    [formatter setDateFormat:@"dd.MM.yyyy"];
    date = [formatter dateFromString:str];
    
    if (date == nil) {
        [formatter setDateFormat:@"d-MMM-yyyy"];
        date = [formatter dateFromString:str];
    }
    
    if (date == nil) {
        [formatter setDateFormat:@"dd-MMM-yyyy"];
        date = [formatter dateFromString:str];
    }

    if (date == nil) {
        [formatter setDateFormat:@"MMM d, yyyy"];
        date = [formatter dateFromString:str];
    }
    
    if (date == nil) {
        [formatter setDateFormat:@"dd MMM yyyy"];
        date = [formatter dateFromString:str];
    }

    [formatter release];
    [locale release];

    if (date == nil) {
        date = [NSDate date];
    }
    
    return date;
}

#pragma mark -
#pragma mark Delegate
#pragma mark -

- (void)startProgressAnimationWithTitle:(NSString *)title maxValue:(NSInteger)max indeterminate:(BOOL)indeterminate {
	if (delegate) {
		[delegate startProgressAnimationWithTitle:title maxValue:max indeterminate:indeterminate];
	}
}

- (void)stopProgressAnimation {
	if (delegate) {
		[delegate stopProgressAnimation];
	}
}

- (void)incrementProgressIndicatorBy:(double)value {
	if (delegate) {
		[delegate incrementProgressIndicatorBy:value];
	}
}

- (void)changePhaseWithMessage:(NSString *)message {
	if (delegate) {
		[delegate changePhaseWithMessage:message];
	}
}

@end
