//
//  ReportDownloader.m
//  Prismo
//
//  Created by Sergey Lenkov on 26.05.10.
//  Copyright 2010 Sergey Lenkov. All rights reserved.
//

#import "PSReportDownloader.h"

@implementation PSReportDownloader

@synthesize delegate;
@synthesize isCanceled;

- (id)initWithDatabase:(sqlite3 *)db {
    self = [super init];
    
	if (self) {	
		_db = db;
	}
	
	return self;
}

- (void)download {	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	[defaults setObject:[NSDate date] forKey:@"Last Reports Check"];
	[defaults setObject:@"Unknown" forKey:@"Last Reports Check Status"];
	
	NSArray *accounts = [defaults objectForKey:@"Accounts"];

    BOOL isAllDownloaded = YES;
    
    for (int i = 0; i < [accounts count]; i++) {
        NSDate *date = [[NSDate date] dateByAddingDays:-15];
        NSDictionary *account = [accounts objectAtIndex:i];

        for (int i = 0; i < 14; i++) {
            date = [date dateByAddingDays:1];

            if (![self isExistsSalesForAccount:[account objectForKey:@"id"] date:date]) {
                isAllDownloaded = NO;
            }
        }
    }
    
    if (!isAllDownloaded) {
       for (int i = 0; i < [accounts count]; i++) {
           if (isCanceled) {				
               break;
           }
		
           NSDictionary *account = [accounts objectAtIndex:i];
           NSString *password = [PTKeychain passwordForLabel:ITUNES_LABEL account:[account objectForKey:@"id"]];
           
           if (![self downloadDailyReportsForAccount:[account objectForKey:@"id"] withPassword:password vendor:[account objectForKey:@"vendor"]]) {
               break;
           }
       }
	}
	
	if (isAllDownloaded) {
		[self changePhaseWithMessage:@"All reports already downloaded"];
        [defaults setObject:@"All reports downloaded" forKey:@"Last Reports Check Status"];
		[NSThread sleepForTimeInterval:2];
	}
}

- (BOOL)downloadDailyReportsForAccount:(NSString *)account withPassword:(NSString *)password vendor:(NSString *)vendor {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	[self changePhaseWithMessage:[NSString stringWithFormat:@"Signing as %@", account]];
    [NSThread sleepForTimeInterval:2];

    [ASIHTTPRequest clearSession];

    NSDate *date = [[NSDate date] dateByAddingDays:-15];
    
    for (int i = 0; i < 14; i++) {
        date = [date dateByAddingDays:1];
        
        if ([self isExistsSalesForAccount:account date:date] || isCanceled) {
            continue;
        }
    
        NSString *dateString = [PSUtilites localizedMediumDateWithFullMonth:date];
        
        if ([date year] == [[NSDate date] year]) {
            dateString = [PSUtilites localizedShortDateWithFullMonth:date];
        }
        
        [self changePhaseWithMessage:[NSString stringWithFormat:@"Checking report for %@", dateString]];
        [NSThread sleepForTimeInterval:1.0];

        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [dateFormatter setDateFormat:@"yyyyMMdd"];

        ASIFormDataRequest *formRequest = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:@"https://reportingitc.apple.com/autoingestion.tft?"]];
        formRequest.shouldRedirect = NO;
        formRequest.timeOutSeconds = 120;
        
        [formRequest addRequestHeader:@"User-Agent" value:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_3; en-us) AppleWebKit/525.18 (KHTML, like Gecko) Version/3.1.1 Safari/525.20"];
        [formRequest addRequestHeader:@"Content-Type" value:@"application/x-www-form-urlencoded"];
    
        [formRequest setPostValue:account forKey:@"USERNAME"];
        [formRequest setPostValue:password forKey:@"PASSWORD"];
        [formRequest setPostValue:vendor forKey:@"VNDNUMBER"];
        [formRequest setPostValue:@"Sales" forKey:@"TYPEOFREPORT"];
        [formRequest setPostValue:@"Daily" forKey:@"DATETYPE"];
        [formRequest setPostValue:@"Summary" forKey:@"REPORTTYPE"];
        [formRequest setPostValue:[dateFormatter stringFromDate:date] forKey:@"REPORTDATE"];
        
        [formRequest startSynchronous];
        
        NSError *error = [formRequest error];

        if (error) {
            [GrowlApplicationBridge notifyWithTitle:account description:[error localizedDescription] notificationName:@"New event" iconData:nil priority:0 isSticky:NO clickContext:nil];
            [defaults setObject:[error localizedDescription] forKey:@"Last Reports Check Status"];

            return NO;        
        }

        NSString *message = [[formRequest responseHeaders] objectForKey:@"ERRORMSG"];

        if (message == nil) {
            message = [[formRequest responseHeaders] objectForKey:@"Errormsg"];
        }
        
        if (message) {
            if ([message isEqualToString:@"Daily reports are available only for past 14 days, please enter a date within past 14 days."] || [message isEqualToString:@"There are no reports available to download for this selection."]) {
                [GrowlApplicationBridge notifyWithTitle:account description:[NSString stringWithFormat:@"Report for %@ not available", dateString] notificationName:@"New event" iconData:nil priority:0 isSticky:NO clickContext:nil];
                [defaults setObject:@"Report not available" forKey:@"Last Reports Check Status"];
                
                [self changePhaseWithMessage:@"Report not available"];
                [NSThread sleepForTimeInterval:2.0];
            } else {
                [GrowlApplicationBridge notifyWithTitle:account description:message notificationName:@"New event" iconData:nil priority:0 isSticky:NO clickContext:nil];
                [defaults setObject:message forKey:@"Last Reports Check Status"];
                
                [self changePhaseWithMessage:message];
                [NSThread sleepForTimeInterval:2.0];
                
                return NO;
            }
        } else {
            [self changePhaseWithMessage:@"Downloading report"];
            [NSThread sleepForTimeInterval:2.0];

            NSString *fileName = [[formRequest responseHeaders] objectForKey:@"filename"];
        
            if (fileName == nil) {
                fileName = [[formRequest responseHeaders] objectForKey:@"Filename"];
            }

            NSString *path = [defaults objectForKey:@"Download Path"];
            NSString *reportFile = [[path stringByAppendingPathComponent:fileName] stringByDeletingPathExtension];

            NSData *unzip = [[formRequest rawResponseData] decompressGZip];
            
            NSError *error = nil;
            
            [unzip writeToFile:reportFile options:NSDataWritingAtomic error:&error];

            if (error) {
                [GrowlApplicationBridge notifyWithTitle:account description:[error localizedDescription] notificationName:@"New event" iconData:nil priority:0 isSticky:NO clickContext:nil];
                [defaults setObject:[error localizedDescription] forKey:@"Last Reports Check Status"];

                return NO;
            } else {
                [self changePhaseWithMessage:@"Importing report"];
                [NSThread sleepForTimeInterval:2.0];

                [self importFile:reportFile forAccount:account];

                [GrowlApplicationBridge notifyWithTitle:account description:[NSString stringWithFormat:@"Report for %@ downloaded", dateString] notificationName:@"New event" iconData:nil priority:0 isSticky:NO clickContext:nil];
                [defaults setObject:[NSString stringWithFormat:@"Report for %@ downloaded",  dateString] forKey:@"Last Reports Check Status"];
            }
        }
    }
    
    return YES;
}

- (BOOL)isExistsSalesForAccount:(NSString *)account date:(NSDate *)date {
    NSString *sql = @"SELECT COUNT(*) FROM sales s, applications a WHERE s.date = ? AND a.account = ? AND s.apple_id = a.id";
    sqlite3_stmt *statement;
    
    int count = 0;

    if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [[date dbDateRepresentation] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 2, [account UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(statement) == SQLITE_ROW) {				
            count = sqlite3_column_int(statement, 0);
        }
    }
    
    sqlite3_finalize(statement);

    if (count == 0) {
        return NO;
    }
    
    return YES;
}

- (void)importFile:(NSString *)fileName forAccount:(NSString *)account {
	NSString *txt = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:nil];
	NSMutableArray *lines = [NSMutableArray arrayWithArray:[txt componentsSeparatedByString:@"\n"]];
	
	if ([lines count] == 0) {
		return;
	}
	
	[lines removeObjectAtIndex:0];
	
	if ([[lines lastObject] isEqualToString:@""]) {
		[lines removeLastObject];
	}
	
	if ([lines count] == 0) {
		return;
	}
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
	[dateFormatter setLocale:locale];
	[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    
    BOOL isNewReport = NO;
    
	NSArray *fields = [NSArray arrayWithArray:[[lines objectAtIndex:0] componentsSeparatedByString:@"\t"]];
    
	[dateFormatter setDateFormat:@"MM/dd/yyyy"];
	NSDate *startDate = [dateFormatter dateFromString:[fields objectAtIndex:11]];
	
	if (startDate == nil) {
		[dateFormatter setDateFormat:@"YYYYMMdd"];
		startDate = [dateFormatter dateFromString:[fields objectAtIndex:11]];
	}
	
	[dateFormatter setDateFormat:@"MM/dd/yyyy"];
	NSDate *endDate = [dateFormatter dateFromString:[fields objectAtIndex:12]];
	
	if (endDate == nil) {
		[dateFormatter setDateFormat:@"YYYYMMdd"];
		endDate = [dateFormatter dateFromString:[fields objectAtIndex:12]];
	}
	
	if (startDate == nil || endDate == nil) {
		[dateFormatter setDateFormat:@"MM/dd/yyyy"];
        startDate = [dateFormatter dateFromString:[fields objectAtIndex:9]];
        
        
        [dateFormatter setDateFormat:@"MM/dd/yyyy"];
        endDate = [dateFormatter dateFromString:[fields objectAtIndex:10]];
        
        if (startDate == nil || endDate == nil) {
            return;
        }
        
        isNewReport = YES;
	}
	
	NSMutableArray *ids = [[NSMutableArray alloc] init];
	
	for (int i = 0; i < [lines count]; i++) {
		fields = [NSArray arrayWithArray:[[lines objectAtIndex:i] componentsSeparatedByString:@"\t"]];
		
		NSString *appleID;
        
        if (isNewReport) {
            appleID = [fields objectAtIndex:14];
        } else {
            appleID = [fields objectAtIndex:19];
        }
        
		BOOL isExists = NO;
		
		for (int j = 0; j < [ids count]; j++) {
			if ([appleID isEqualToString:[ids objectAtIndex:j]]) {
				isExists = YES;
			}
		}
		
		if (!isExists) {
			[ids addObject:appleID];
		}
	}

	NSString *deleteSQL = @"DELETE FROM sales WHERE date >= ? AND date <= ? AND apple_id = ?";
	sqlite3_stmt *deleteStatement;	
	
	for (int i = 0; i < [ids count]; i++) {
		NSString *appleID = [ids objectAtIndex:i];

		if (sqlite3_prepare_v2(_db, [deleteSQL UTF8String], -1, &deleteStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(deleteStatement, 1, [[startDate dbDateRepresentation] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(deleteStatement, 2, [[endDate dbDateRepresentation] UTF8String], -1, SQLITE_TRANSIENT);
			sqlite3_bind_text(deleteStatement, 3, [appleID UTF8String], -1, SQLITE_TRANSIENT);
			
			sqlite3_step(deleteStatement);
		}
	}

	NSString *insertSQL = @"INSERT INTO sales (developer, application_name, application_id, apple_id, type_id, units, currency_code, country_code, price, royalty, date, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";	
	sqlite3_stmt *insertStatement;	
	
	for (int i = 0; i < [lines count]; i++) {
		fields = [NSArray arrayWithArray:[[lines objectAtIndex:i] componentsSeparatedByString:@"\t"]];
        
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        
        NSString *currency = @"";
        NSNumber *royalty;
        
        if (isNewReport) {
            [dict setObject:[fields objectAtIndex:3] forKey:@"developer"];
            [dict setObject:[fields objectAtIndex:4] forKey:@"application_name"];
            [dict setObject:[fields objectAtIndex:2] forKey:@"application_id"];
            [dict setObject:[fields objectAtIndex:14] forKey:@"apple_id"];
            [dict setObject:[fields objectAtIndex:6] forKey:@"type_id"];
            [dict setObject:[fields objectAtIndex:7] forKey:@"units"];
            [dict setObject:[fields objectAtIndex:11] forKey:@"currency_code"];
            [dict setObject:[fields objectAtIndex:12] forKey:@"country_code"];
            [dict setObject:[fields objectAtIndex:15] forKey:@"price"];
            [dict setObject:[fields objectAtIndex:8] forKey:@"royalty"];
            [dict setObject:[startDate dbDateRepresentation] forKey:@"date"];
            
            currency = [fields objectAtIndex:11];
            royalty = [NSNumber numberWithDouble:[[fields objectAtIndex:8] doubleValue]];
        } else {
            [dict setObject:[fields objectAtIndex:5] forKey:@"developer"];
            [dict setObject:[fields objectAtIndex:6] forKey:@"application_name"];
            [dict setObject:[fields objectAtIndex:2] forKey:@"application_id"];
            [dict setObject:[fields objectAtIndex:19] forKey:@"apple_id"];
            [dict setObject:[fields objectAtIndex:8] forKey:@"type_id"];
            [dict setObject:[fields objectAtIndex:9] forKey:@"units"];
            [dict setObject:[fields objectAtIndex:13] forKey:@"currency_code"];
            [dict setObject:[fields objectAtIndex:14] forKey:@"country_code"];
            [dict setObject:[fields objectAtIndex:20] forKey:@"price"];
            [dict setObject:[fields objectAtIndex:10] forKey:@"royalty"];
            [dict setObject:[startDate dbDateRepresentation] forKey:@"date"];
            
            currency = [fields objectAtIndex:13];
            royalty = [NSNumber numberWithDouble:[[fields objectAtIndex:10] doubleValue]];
        }   

        NSDictionary *prices = [self tiersFroCurrency:currency royalty:royalty date:startDate];

        if (sqlite3_prepare_v2(_db, [insertSQL UTF8String], -1, &insertStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(insertStatement, 1, [[dict objectForKey:@"developer"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 2, [[dict objectForKey:@"application_name"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 3, [[dict objectForKey:@"application_id"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 4, [[dict objectForKey:@"apple_id"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 5, [[dict objectForKey:@"type_id"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(insertStatement, 6, [[dict objectForKey:@"units"] intValue]);
            sqlite3_bind_text(insertStatement, 7, [[dict objectForKey:@"currency_code"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 8, [[dict objectForKey:@"country_code"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_double(insertStatement, 9, [[dict objectForKey:@"price"] doubleValue]);
            sqlite3_bind_double(insertStatement, 10, [[dict objectForKey:@"royalty"] doubleValue]);
            sqlite3_bind_text(insertStatement, 11, [[dict objectForKey:@"date"] UTF8String], -1, SQLITE_TRANSIENT);
       		sqlite3_bind_double(insertStatement, 12, [[prices objectForKey:@"royalty_in_usd"] doubleValue]);
            sqlite3_bind_double(insertStatement, 13, [[prices objectForKey:@"royalty_in_eur"] doubleValue]);
            sqlite3_bind_double(insertStatement, 14, [[prices objectForKey:@"royalty_in_gbp"] doubleValue]);
            sqlite3_bind_double(insertStatement, 15, [[prices objectForKey:@"royalty_in_jpy"] doubleValue]);
            sqlite3_bind_double(insertStatement, 16, [[prices objectForKey:@"royalty_in_aud"] doubleValue]);
            sqlite3_bind_double(insertStatement, 17, [[prices objectForKey:@"royalty_in_cad"] doubleValue]);

			sqlite3_step(insertStatement);			
		}
		
		sqlite3_finalize(insertStatement);		
        
		NSMutableDictionary *application = [[NSMutableDictionary alloc] init];
        
        [application setObject:[dict objectForKey:@"apple_id"] forKey:@"id"];
        [application setObject:[dict objectForKey:@"application_name"] forKey:@"name"];
        [application setObject:account forKey:@"account"];
        [application setObject:@"" forKey:@"type"];
        
        if ([[dict objectForKey:@"type_id"] isEqualToString:@"1"] || [[dict objectForKey:@"type_id"] isEqualToString:@"7"]) {
            [application setObject:@"iphone" forKey:@"type"];
        }
        
        if ([[dict objectForKey:@"type_id"] isEqualToString:@"IA1"] || [[dict objectForKey:@"type_id"] isEqualToString:@"IAY"] || [[dict objectForKey:@"type_id"] isEqualToString:@"FI1"]) {
            [application setObject:@"in-app" forKey:@"type"];
        }
        
        if ([[dict objectForKey:@"type_id"] isEqualToString:@"IA9"]) {
            [application setObject:@"subscription" forKey:@"type"];
        }
        
        if ([[dict objectForKey:@"type_id"] isEqualToString:@"1F"] || [[dict objectForKey:@"type_id"] isEqualToString:@"7F"]) {
            [application setObject:@"universal" forKey:@"type"];
        }
        
        if ([[dict objectForKey:@"type_id"] isEqualToString:@"1T"] || [[dict objectForKey:@"type_id"] isEqualToString:@"7T"]) {
            [application setObject:@"ipad" forKey:@"type"];
        }
        
        if ([[dict objectForKey:@"type_id"] isEqualToString:@"F1"] || [[dict objectForKey:@"type_id"] isEqualToString:@"F7"]) {
            [application setObject:@"mac" forKey:@"type"];
        }
        
        if ([account length] == 0) {
            NSString *sql = @"SELECT account FROM applications WHERE id = ?";
            sqlite3_stmt *statement;
            
            if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
                sqlite3_bind_int(statement, 1, [[application objectForKey:@"id"] intValue]);

                if (sqlite3_step(statement) == SQLITE_ROW && sqlite3_column_text(statement, 0) != NULL) {                
                    [application setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)] forKey:@"account"];
                }
            }

            sqlite3_finalize(statement);
        }
        
        NSString *sql = @"INSERT OR REPLACE INTO applications (id, name, type, account) VALUES (?, ?, ?, ?)";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_int(statement, 1, [[application objectForKey:@"id"] intValue]);
            sqlite3_bind_text(statement, 2, [[application objectForKey:@"name"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, [[application objectForKey:@"type"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 4, [[application objectForKey:@"account"] UTF8String], -1, SQLITE_TRANSIENT);

            sqlite3_step(statement);										
        }
            
        sqlite3_finalize(statement);
        
        [application release];
        [dict release];
	}
	
	[ids release];
	[locale release];
	[dateFormatter release];
}

- (NSDictionary *)tiersFroCurrency:(NSString *)currency royalty:(NSNumber *)royalty date:(NSDate *)date {
    int version = 1;
    
    if ([[NSDate dateFromUTCString:[NSString stringWithFormat:@"%@ 00:00:00", [date dbDateRepresentation]]] timeIntervalSince1970] >= [[NSDate dateFromUTCString:@"2011-07-20 00:00:00"] timeIntervalSince1970]) {
        version = 2;
    }
    
    if ([[NSDate dateFromUTCString:[NSString stringWithFormat:@"%@ 00:00:00", [date dbDateRepresentation]]] timeIntervalSince1970] >= [[NSDate dateFromUTCString:@"2012-03-01 00:00:00"] timeIntervalSince1970]) {
        version = 3;
    }
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init]; 

    [dict setObject:[NSNumber numberWithInt:0] forKey:@"royalty_in_usd"];
    [dict setObject:[NSNumber numberWithInt:0] forKey:@"royalty_in_eur"];
    [dict setObject:[NSNumber numberWithInt:0] forKey:@"royalty_in_gbp"];
    [dict setObject:[NSNumber numberWithInt:0] forKey:@"royalty_in_jpy"];
    [dict setObject:[NSNumber numberWithInt:0] forKey:@"royalty_in_aud"];
    [dict setObject:[NSNumber numberWithInt:0] forKey:@"royalty_in_cad"];
    
    NSString *sql = @"SELECT t.royalty_in_usd, t.royalty_in_eur, t.royalty_in_gbp, t.royalty_in_jpy, t.royalty_in_aud, t.royalty_in_cad \
                        FROM tiers t, currencies c WHERE c.tier_currency_code = t.currency_code AND c.currency_code = ? AND t.royalty = ? AND c.version = ? AND t.version = ?";
    sqlite3_stmt *statement;
  
    if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [currency UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_double(statement, 2, [royalty doubleValue]);
        sqlite3_bind_int(statement, 3, version);
        sqlite3_bind_int(statement, 4, version);
        
        if (sqlite3_step(statement) == SQLITE_ROW) {
            [dict setObject:[NSNumber numberWithDouble:sqlite3_column_double(statement, 0)] forKey:@"royalty_in_usd"];
            [dict setObject:[NSNumber numberWithDouble:sqlite3_column_double(statement, 1)] forKey:@"royalty_in_eur"];
            [dict setObject:[NSNumber numberWithDouble:sqlite3_column_double(statement, 2)] forKey:@"royalty_in_gbp"];
            [dict setObject:[NSNumber numberWithDouble:sqlite3_column_double(statement, 3)] forKey:@"royalty_in_jpy"];
            [dict setObject:[NSNumber numberWithDouble:sqlite3_column_double(statement, 4)] forKey:@"royalty_in_aud"];
            [dict setObject:[NSNumber numberWithDouble:sqlite3_column_double(statement, 5)] forKey:@"royalty_in_cad"];
        }
    }

    return [dict autorelease];
}

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

- (void)showWarningMessage:(NSString *)message {
	if (delegate) {
		[delegate showWarningMessage:message];
	}
}

- (void)dealloc {
	[delegate release];
	[super dealloc];
}

@end
