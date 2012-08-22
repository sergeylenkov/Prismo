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
        
		for (int i = 0; i < [data.stores count]; i++) {
			if (isCanceled) {
                [defaults setObject:@"Canceled" forKey:@"Last Reviews Update Status"];
				break;
			}
            
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			PSStore *store = [data.stores objectAtIndex:i];

			[self changePhaseWithMessage:[NSString stringWithFormat:@"%@ - %@", application.name, store.name]];

            NSString *url = [NSString stringWithFormat:@"http://itunes.apple.com/WebObjects/MZStore.woa/wa/customerReviews?update=1&id=%ld&displayable-kind=11", application.identifier];
            ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
            
            request.timeOutSeconds = 60;
            request.shouldRedirect = NO;
            
            [request addRequestHeader:@"User-Agent" value:@"iTunes/10.1.1 (Macintosh; Intel Mac OS X 10.6.6) AppleWebKit/533.19.4"];
            [request addRequestHeader:@"X-Apple-Store-Front" value:[NSString stringWithFormat:@"%ld,12", store.identifier]];
            [request addRequestHeader:@"X-Apple-Partner" value:@"origin.0"];
            [request addRequestHeader:@"X-Apple-Connection-Type" value:@"WiFi"];
            
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
            
            NSString *response = [[NSString alloc] initWithData:[request responseData] encoding:NSUTF8StringEncoding];

            int numberOfPages = [[response stringByMatching:@"total-number-of-pages='(.*)?'" capture:1] intValue];
            
            for (int i = 0; i < numberOfPages; i++) {
                NSString *response = [self downloadReviewsForApplication:application store:store page:i + 1];
                
                if (response == nil) {
                    [self stopProgressAnimation];
                    [GrowlApplicationBridge notifyWithTitle:@"Reviews" description:@"Parsing Error" notificationName:@"New event" iconData:nil priority:0 isSticky:NO clickContext:nil];
                    
                    [defaults setObject:@"Parsing Error" forKey:@"Last Reviews Update Status"];
                    
                    isCanceled = YES;
                    
                    [pool release];
                    
                    return;
                }
                
                NSArray *items = [response componentsSeparatedByString:@"class=\"customer-review\">"];
                
                for (int i = 1; i < [items count]; i++) {
                    NSArray *lines = [[items objectAtIndex:i] componentsSeparatedByString:@"\n"];
                    NSString *item = @"";
                    
                    for (NSString *line in lines) {
                        line = [line stringByRemovingNewLinesAndWhitespace];
                        
                        if ([line length] > 0) {
                            item = [item stringByAppendingString:line];
                        }
                    }

                    item = [item stringByRemovingNewLinesAndWhitespace];

                    @try {                        
                        NSString *title = [item stringByMatching:@"<span class=\"customerReviewTitle\">(.*?)</span>" capture:1];
                        NSString *text = [item stringByMatching:@"<p class=\"content.*?\">(.*?)</p>" capture:1];
                        NSString *name = [item stringByMatching:@"<a href='.*' class=\"reviewer\">(.*?)</a>" capture:1];
                        NSInteger rating = [[item componentsSeparatedByString:@"\"rating-star\""] count] - 1;

                        NSString *temp = [item stringByMatching:@"<span class=\"user-info\">.*?</a>(.*?)</span>" capture:1];
                        
                        NSArray *fields = [temp componentsSeparatedByString:@"-"];
                        NSString *version = [[fields objectAtIndex:1] stringByMatching:@"([0-9].*)" capture:1];
                        
                        NSString *dateStr = @"";
                        
                        for (int i = 2; i < [fields count]; i++) {
                            dateStr = [dateStr stringByAppendingFormat:@"%@-", [[fields objectAtIndex:i] stringByRemovingNewLinesAndWhitespace]];
                        }
                        
                        dateStr = [dateStr substringToIndex:[dateStr length] - 1];

                        PSReview *review = [[PSReview alloc] initWithPrimaryKey:-1 database:_db];
                        
                        review.title = [title stringByRemovingNewLinesAndWhitespace];
                        review.text = [text stringByRemovingNewLinesAndWhitespace];
                        review.name = [name stringByRemovingNewLinesAndWhitespace];
                        review.rating = rating;
                        review.version = [version stringByRemovingNewLinesAndWhitespace];
                        review.store = store;
                        review.application = application;
                        review.date = [self dateFromString:dateStr];

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
                    @catch (NSException *exception) {
                        //
                    }
                    @finally {
                        //
                    }            
                }
            }
					
			[self incrementProgressIndicatorBy:1.0];
			
			[pool release];
		}
        
        [self importReviews:reviews];
	}
    
	[reviews release];
    [applications release];
    
    if (!isCanceled) {
        [defaults setObject:@"Reviews updated successfully" forKey:@"Last Reviews Update Status"];
    }
    
    [defaults synchronize];
}

- (NSString *)downloadReviewsForApplication:(PSApplication *)application store:(PSStore *)store page:(NSInteger)page {
    NSString *url = [NSString stringWithFormat:@"http://itunes.apple.com/WebObjects/MZStore.woa/wa/customerReviews?update=1&id=%ld&displayable-kind=11&page=%ld&sort=1", application.identifier, page];    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    
    request.timeOutSeconds = 60;
    request.shouldRedirect = NO;
    
    [request addRequestHeader:@"User-Agent" value:@"iTunes/10.1.1 (Macintosh; Intel Mac OS X 10.6.6) AppleWebKit/533.19.4"];
    [request addRequestHeader:@"X-Apple-Store-Front" value:[NSString stringWithFormat:@"%ld,12", store.identifier]];
    [request addRequestHeader:@"X-Apple-Partner" value:@"origin.0"];
    [request addRequestHeader:@"X-Apple-Connection-Type" value:@"WiFi"];
    
    [request startSynchronous];
    
    NSError *error = [request error];
    
    if (error) {        
        return nil;
    }
    
    NSString *result = [[NSString alloc] initWithData:[request responseData] encoding:NSUTF8StringEncoding];
    
    return [result autorelease];
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
