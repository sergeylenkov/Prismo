//
//  PSUpdater.m
//  Prismo
//
//  Created by Sergey Lenkov on 06.08.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSUpdater.h"

@implementation PSUpdater

- (id)initWithDatabase:(sqlite3 *)db {
    self = [super init];
    
    if (self) {
        _db = db;
    }
    
    return self;
}

- (void)update {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:APPLICATION_SUPPORT_FOLDER];  	
    path = [path stringByAppendingPathComponent:DATABASE];

    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) {
        return;
    }
    
    NSString *sql = @"SELECT MAX(id), version FROM schema";
    sqlite3_stmt *statement;
    
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *dbVersion = @"";
    
    if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {      
        if (sqlite3_step(statement) == SQLITE_ROW) {
            dbVersion = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)];
        }
    }

    if (![appVersion isEqualToString:dbVersion]) {
        if ([dbVersion isEqualToString:@""]) {
            dbVersion = @"1.3.8";

            [self backup:dbVersion];
            [self updateTo139];
        }
        
        for (int i = [self intFromVersion:dbVersion]; i <= [self intFromVersion:appVersion]; i++) {
            NSString *version = [self versionFromInt:i];

            if (![self isVersionExists:version]) {
                SEL action = NSSelectorFromString([NSString stringWithFormat:@"updateTo%d", i]);
                
                if ([self respondsToSelector:action]) {
                    [self performSelector:action];
                }
            }
        }
    }
}

- (void)backup:(NSString *)version {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:APPLICATION_SUPPORT_FOLDER];  	
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingPathComponent:BACKUP_FOLDER] isDirectory:nil]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByAppendingPathComponent:BACKUP_FOLDER] withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *dbPath = [path stringByAppendingPathComponent:DATABASE];
    NSString *backupPath = [[path stringByAppendingPathComponent:BACKUP_FOLDER] stringByAppendingPathComponent:[NSString stringWithFormat:@"Database.%@.sqlite", version]];
    
   [[NSFileManager defaultManager] copyItemAtPath:dbPath toPath:backupPath error:nil]; 
}

- (void)addSchema:(NSInteger)schema version:(NSString *)version {
    NSString *sql = @"INSERT OR REPLACE INTO schema (id, version) VALUES (?, ?)";
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_int(statement, 1, schema);
        sqlite3_bind_text(statement, 2, [version UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(statement);										
    }
    
    sqlite3_finalize(statement);
}

- (int)intFromVersion:(NSString *)version {
    version = [version stringByReplacingOccurrencesOfString:@"." withString:@""];
    
    if ([version length] == 2) {
        version = [version stringByAppendingString:@"0"];
    }
    
    return [version intValue];
}

- (NSString *)versionFromInt:(int)version {
    NSString *temp = [NSString stringWithFormat:@"%d", version];
    return [NSString stringWithFormat:@"%c.%c.%c", [temp characterAtIndex:0], [temp characterAtIndex:1], [temp characterAtIndex:2]];
}

- (BOOL)isVersionExists:(NSString *)version {
    NSString *sql = @"SELECT COUNT(*) FROM schema WHERE version = ?";
    sqlite3_stmt *statement;
    BOOL result = NO;
    
    if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [version UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(statement) == SQLITE_ROW) {
            if (sqlite3_column_int(statement, 0) > 0) {
                result = YES;
            }
        }
    }
    
    sqlite3_finalize(statement);
    
    return result;
}

#pragma mark -
#pragma mark Update
#pragma mark -

- (void)updateTo139 {
    [Database close];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:APPLICATION_SUPPORT_FOLDER];  	
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:path isDirectory:nil]) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *originalPath = [path stringByAppendingPathComponent:@"Database.sqlite"];
    NSString *newPath = [path stringByAppendingPathComponent:@"Database.v2.sqlite"];
    
    NSString *defaultPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Database.sqlite"];
    [fileManager copyItemAtPath:defaultPath toPath:newPath error:nil];
    
    sqlite3 *originalDb;
    sqlite3_open([originalPath UTF8String], &originalDb);
    
    sqlite3 *newDb;
    sqlite3_open([newPath UTF8String], &newDb);
    
    NSString *deleteSQL = @"DELETE FROM sales";
    sqlite3_stmt *deleteStatement;	
    
    if (sqlite3_prepare_v2(newDb, [deleteSQL UTF8String], -1, &deleteStatement, NULL) == SQLITE_OK) {                    
        sqlite3_step(deleteStatement);                
    }
    
    sqlite3_finalize(deleteStatement);
    
    sqlite3_stmt *transactionStatement;
    
    sqlite3_prepare_v2(newDb, [@"BEGIN TRANSACTION;" UTF8String], -1, &transactionStatement, NULL);
    sqlite3_step(transactionStatement);
    sqlite3_finalize(transactionStatement);
    
    NSString *selectSQL = @"SELECT developer, application_name, application_id, apple_id, type_id, units, currency_code, country_code, price, royalty, date, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad FROM sales";
    sqlite3_stmt *selectStatement;
    
    if (sqlite3_prepare_v2(originalDb, [selectSQL UTF8String], -1, &selectStatement, NULL) == SQLITE_OK) {      
        while (sqlite3_step(selectStatement) == SQLITE_ROW) {
            NSString *insertSQL = @"INSERT INTO sales (developer, application_name, application_id, apple_id, type_id, units, currency_code, country_code, price, royalty, date, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";	
            sqlite3_stmt *insertStatement;            
            
            if (sqlite3_prepare_v2(newDb, [insertSQL UTF8String], -1, &insertStatement, NULL) == SQLITE_OK) {
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
                
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_double(selectStatement, 10)];
                sqlite3_bind_text(insertStatement, 11, [[date dbDateRepresentation] UTF8String], -1, SQLITE_TRANSIENT);
                
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
    
    sqlite3_prepare_v2(newDb, [@"COMMIT;" UTF8String], -1, &transactionStatement, NULL);
    sqlite3_step(transactionStatement);
    sqlite3_finalize(transactionStatement);
    
    selectSQL = @"SELECT apple_id, store_id, category_id, rank, date FROM ranks";
    NSString *revenueSQL = @"SELECT TOTAL(royalty_in_usd) FROM sales WHERE application_id = ? ORDER BY date DESC LIMIT 1";
    sqlite3_stmt *revenueStatement;
    
    if (sqlite3_prepare_v2(originalDb, [selectSQL UTF8String], -1, &selectStatement, NULL) == SQLITE_OK) {
        while (sqlite3_step(selectStatement) == SQLITE_ROW) {            
            int pop = 27;
            
            if (sqlite3_prepare_v2(originalDb, [revenueSQL UTF8String], -1, &revenueStatement, NULL) == SQLITE_OK) {
                sqlite3_bind_int(revenueStatement, 1, sqlite3_column_int(selectStatement, 0));
                
                while (sqlite3_step(revenueStatement) == SQLITE_ROW) {
                    if (sqlite3_column_double(revenueStatement, 0) > 0.0) {
                        pop = 30;
                    }
                }
            }
            
            sqlite3_finalize(revenueStatement);
            
            NSString *sql = @"INSERT INTO ranks (application_id, store_id, category_id, pop_id, place, date) VALUES (?, ?, ?, ?, ?, ?)";
            sqlite3_stmt *statement;
            
            if (sqlite3_prepare_v2(newDb, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
                sqlite3_bind_int(statement, 1, sqlite3_column_int(selectStatement, 0));
                sqlite3_bind_int(statement, 2, sqlite3_column_int(selectStatement, 1));
                sqlite3_bind_int(statement, 3, sqlite3_column_int(selectStatement, 2));
                sqlite3_bind_int(statement, 4, pop);
                sqlite3_bind_int(statement, 5, sqlite3_column_int(selectStatement, 3));
                
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_double(selectStatement, 4)];
                sqlite3_bind_text(statement, 6, [[date dbDateRepresentation] UTF8String], -1, SQLITE_TRANSIENT);
                
                sqlite3_step(statement);										
            }
            
            sqlite3_finalize(statement);
        }
    }
    
    sqlite3_finalize(selectStatement);
    
    
    selectSQL = @"SELECT s.application_name, s.type_id, s.apple_id, CASE WHEN a.apple_id IS NULL THEN \"\" ELSE a.apple_id END AS account FROM sales s LEFT JOIN accounts a ON s.apple_id = a.application_id GROUP BY s.apple_id, s.type_id";
    
    if (sqlite3_prepare_v2(originalDb, [selectSQL UTF8String], -1, &selectStatement, NULL) == SQLITE_OK) {      
        while (sqlite3_step(selectStatement) == SQLITE_ROW) {					
            NSString *sql = @"INSERT INTO applications (id, name, type, account) VALUES (?, ?, ?, ?)";
            sqlite3_stmt *statement;
            
            NSString *typeID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStatement, 1)];
            NSString *type = @"";
            
            if ([typeID isEqualToString:@"1"] || [typeID isEqualToString:@"7"]) {
                type = @"iphone";
            }
            
            if ([typeID isEqualToString:@"IA1"] || [typeID isEqualToString:@"IAY"]) {
                type = @"in-app";
            }
            
            if ([typeID isEqualToString:@"IA9"]) {
                type = @"subscription";
            }
            
            if ([typeID isEqualToString:@"1F"] || [typeID isEqualToString:@"7F"]) {
                type = @"universal";
            }
            
            if ([typeID isEqualToString:@"1T"] || [typeID isEqualToString:@"7T"]) {
                type = @"ipad";
            }
            
            if ([typeID isEqualToString:@"F1"] || [typeID isEqualToString:@"F7"]) {
                type = @"mac";
            }
            
            if (sqlite3_prepare_v2(newDb, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
                sqlite3_bind_int(statement, 1, sqlite3_column_int(selectStatement, 2));
                sqlite3_bind_text(statement, 2, [[NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStatement, 0)] UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(statement, 3, [type UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(statement, 4, [[NSString stringWithUTF8String:(char *)sqlite3_column_text(selectStatement, 3)] UTF8String], -1, SQLITE_TRANSIENT);
                
                sqlite3_step(statement);										
            }
            
            sqlite3_finalize(statement);
        }		
    }
    
    sqlite3_finalize(selectStatement);
    
    sqlite3_close(newDb);
    sqlite3_close(originalDb);
    
    [fileManager removeItemAtPath:originalPath error:nil];
    [fileManager moveItemAtPath:newPath toPath:originalPath error:nil];
    
    [self addSchema:1 version:@"1.3.9"];
}

- (void)updateTo141 {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dict = [defaults dictionaryRepresentation];

    NSArray *ignore = [NSArray arrayWithObjects:@"registration name", @"registration key", @"download path", @"update ranks every", @"check reports every", 
                                                @"translate to", @"currency", @"download on startup", @"check ranks on startup", @"selected tops", 
                                                @"suhaslaunchedbefore", @"suenableautomaticchecks", @"susendprofileinfo", @"sulastchecktime", nil];
    
    for (id key in dict) {
        if ([ignore containsObject:[key lowercaseString]]) {
            continue;
        }
        
        [defaults removeObjectForKey:key];
    }
    
    [defaults synchronize];
    
    NSString *sql = @"INSERT INTO currencies (currency_code, tier_currency_code, version) VALUES (?, ?, ?)";
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [@"MXN" UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 2, [@"MXP" UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(statement, 3, 2);
        
        sqlite3_step(statement);										
    }
    
    sqlite3_finalize(statement);
    
    sql = @"UPDATE tiers SET to_date = '2011-07-20' WHERE to_date = '14-07-2011'";
    
    if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_step(statement);										
    }
    
    sqlite3_finalize(statement);
    
    [self addSchema:2 version:@"1.4.0"];
    [self addSchema:3 version:@"1.4.1"];
}

- (void)updateTo143 {
    NSString *sql = @"UPDATE currencies SET tier_currency_code = ? WHERE currency_code = ?";
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [@"CHF" UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 2, [@"CHF" UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(statement);										
    }
    
    sqlite3_finalize(statement);
    
    [self addSchema:4 version:@"1.4.3"];
}

- (void)updateTo146 {
    NSString *sql = @"CREATE INDEX 'sales_tcd_index' ON 'sales' ('type_id', 'country_code', 'date')";
    sqlite3_stmt *statement;
    
    sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL);
	sqlite3_step(statement);	
	sqlite3_finalize(statement);
    
    sql = @"CREATE INDEX 'ranks_scapd_index' ON 'ranks' ('store_id', 'category_id', 'application_id', 'pop_id', 'date')";
	
	sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL);
	sqlite3_step(statement);	
	sqlite3_finalize(statement);
    
    sql = @"CREATE INDEX 'reviews_app_index' ON 'reviews' ('application_id')";
	
	sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL);
	sqlite3_step(statement);	
	sqlite3_finalize(statement);
    
    sql = @"CREATE INDEX 'ratings_app_index' ON 'ratings' ('application_id')";
	
	sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL);
	sqlite3_step(statement);	
	sqlite3_finalize(statement);
    
    sql = @"CREATE INDEX 'sales_cd_index' ON 'sales' ('country_code', 'date')";
    
    sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL);
	sqlite3_step(statement);	
	sqlite3_finalize(statement);
    
    sql = @"REINDEX";
	
	sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL);
	sqlite3_step(statement);	
	sqlite3_finalize(statement);
    
    [self addSchema:5 version:@"1.4.6"];
}

- (void)updateTo150 {
    NSString *sql = @"INSERT INTO 'categories' ('id', 'genre_id', 'name', 'type_id') VALUES (29721, 6021, 'Newsstand', 0)";
    sqlite3_stmt *statement;
    
    sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL);
	sqlite3_step(statement);	
	sqlite3_finalize(statement);
    
    [self addSchema:8 version:@"1.5.0"];
}

- (void)updateTo151 {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"SUSendProfileInfo"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self addSchema:9 version:@"1.5.1"];
}

- (void)updateTo152 {
    NSString *sql = @"INSERT INTO 'currencies' ('currency_code', 'tier_currency_code', 'version') VALUES ('CNY', 'CNY', 2)";
    sqlite3_stmt *statement;
    
    sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL);
	sqlite3_step(statement);	
	sqlite3_finalize(statement);
    
    NSMutableArray *queries = [[NSMutableArray alloc] init];
    
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('1', 'CNY', 0.69, 0.42, 0.70, 0.48, 0.42, 60, 0.63, 0.70, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('2', 'CNY', 1.49, 0.91, 1.40, 0.97, 0.91, 119, 1.27, 1.40, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('3', 'CNY', 1.99, 1.21, 2.10, 1.45, 1.21, 175, 1.90, 2.10, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('4', 'CNY', 2.49, 1.52, 2.80, 1.82, 1.52, 245, 2.86, 2.80, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('5', 'CNY', 2.99, 1.82, 3.50, 2.43, 1.82, 315, 3.49, 3.50, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('6', 'CNY', 3.99, 2.43, 4.20, 3.04, 2.43, 350, 4.13, 4.20, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('7', 'CNY', 4.99, 3.04, 4.90, 3.34, 3.04, 420, 4.77, 4.90, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('8', 'CNY', 5.49, 3.34, 5.60, 3.65, 3.34, 490, 5.40, 5.60, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('9', 'CNY', 5.99, 3.65, 6.30, 4.25, 3.65, 560, 6.04, 6.30, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('10', 'CNY', 6.99, 4.25, 7.00, 4.86, 4.25, 595, 6.68, 7.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('11', 'CNY', 7.49, 4.56, 7.70, 5.47, 4.56, 630, 7.31, 7.70, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('12', 'CNY', 7.99, 4.86, 8.40, 6.08, 4.86, 700, 8.27, 8.40, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('13', 'CNY', 8.99, 5.47, 9.10, 6.39, 5.47, 770, 8.90, 9.10, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('14', 'CNY', 9.99, 6.08, 9.80, 6.69, 6.08, 840, 9.54, 9.80, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('15', 'CNY', 10.49, 6.39, 10.50, 7.30, 6.39, 910, 10.18, 10.50, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('16', 'CNY', 10.99, 6.69, 11.20, 7.91, 6.69, 980, 10.81, 11.20, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('17', 'CNY', 11.99, 7.30, 11.90, 8.52, 7.30, 1050, 11.45, 11.90, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('18', 'CNY', 12.99, 7.91, 12.60, 8.82, 7.91, 1120, 12.08, 12.60, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('19', 'CNY', 13.49, 8.21, 13.30, 9.12, 8.21, 1155, 12.72, 13.30, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('20', 'CNY', 13.99, 8.52, 14.00, 9.73, 8.52, 1190, 13.36, 14.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('21', 'CNY', 14.99, 9.12, 14.70, 10.34, 9.12, 1260, 13.99, 14.70, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('22', 'CNY', 15.49, 9.43, 15.40, 10.95, 9.43, 1330, 14.63, 15.40, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('23', 'CNY', 15.99, 9.73, 16.10, 11.25, 9.73, 1400, 15.27, 16.10, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('24', 'CNY', 16.99, 10.34, 16.80, 11.56, 10.34, 1470, 15.90, 16.80, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('25', 'CNY', 17.49, 10.65, 17.50, 12.17, 10.65, 1540, 16.54, 17.50, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('26', 'CNY', 17.99, 10.95, 18.20, 12.78, 10.95, 1610, 17.18, 18.20, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('27', 'CNY', 18.99, 11.56, 18.90, 13.08, 11.56, 1680, 17.81, 18.90, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('28', 'CNY', 19.49, 11.86, 19.60, 13.39, 11.86, 1715, 19.08, 19.60, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('29', 'CNY', 19.99, 12.17, 20.30, 13.99, 12.17, 1750, 19.72, 20.30, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('30', 'CNY', 20.99, 12.78, 21.00, 14.60, 12.78, 1820, 20.36, 21.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('31', 'CNY', 21.99, 13.39, 21.70, 15.21, 13.39, 1890, 20.99, 21.70, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('32', 'CNY', 22.49, 13.69, 22.40, 15.52, 13.69, 1960, 21.63, 22.40, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('33', 'CNY', 22.99, 13.99, 23.10, 15.82, 13.99, 2030, 22.27, 23.10, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('34', 'CNY', 23.99, 14.60, 23.80, 16.43, 14.60, 2065, 22.90, 23.80, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('35', 'CNY', 24.49, 14.91, 24.50, 17.04, 14.91, 2100, 23.54, 24.50, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('36', 'CNY', 24.99, 15.21, 25.20, 17.65, 15.21, 2170, 24.18, 25.20, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('37', 'CNY', 25.99, 15.82, 25.90, 17.95, 15.82, 2240, 24.81, 25.90, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('38', 'CNY', 26.99, 16.43, 26.60, 18.25, 16.43, 2310, 25.45, 26.60, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('39', 'CNY', 27.49, 16.73, 27.30, 18.86, 16.73, 2380, 26.08, 27.30, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('40', 'CNY', 27.99, 17.04, 28.00, 19.47, 17.04, 2415, 26.72, 28.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('41', 'CNY', 28.99, 17.65, 28.70, 20.08, 17.65, 2450, 27.36, 28.70, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('42', 'CNY', 29.49, 17.95, 29.40, 20.39, 17.95, 2520, 27.99, 29.40, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('43', 'CNY', 29.99, 18.25, 30.10, 20.69, 18.25, 2590, 28.63, 30.10, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('44', 'CNY', 30.99, 18.86, 30.80, 21.30, 18.86, 2660, 29.27, 30.80, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('45', 'CNY', 31.99, 19.47, 31.50, 21.91, 19.47, 2730, 29.90, 31.50, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('46', 'CNY', 32.49, 19.78, 32.20, 22.52, 19.78, 2765, 30.54, 32.20, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('47', 'CNY', 32.99, 20.08, 32.90, 22.82, 20.08, 2800, 31.18, 32.90, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('48', 'CNY', 33.99, 20.69, 33.60, 23.12, 20.69, 2870, 31.81, 33.60, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('49', 'CNY', 34.49, 20.99, 34.30, 23.73, 20.99, 2940, 32.45, 34.30, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('50', 'CNY', 34.99, 21.30, 35.00, 24.34, 21.30, 3010, 33.08, 35.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('51', 'CNY', 37.99, 23.12, 38.50, 26.17, 23.12, 3360, 38.18, 38.50, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('52', 'CNY', 39.99, 24.34, 42.00, 27.39, 24.34, 3640, 41.36, 42.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('53', 'CNY', 44.99, 27.39, 45.50, 30.43, 27.39, 3990, 44.54, 45.50, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('54', 'CNY', 47.99, 29.21, 49.00, 33.47, 29.21, 4270, 47.72, 49.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('55', 'CNY', 49.99, 30.43, 52.50, 36.52, 30.43, 4550, 50.90, 52.50, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('56', 'CNY', 54.99, 33.47, 56.00, 38.34, 33.47, 4830, 54.08, 56.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('57', 'CNY', 57.99, 35.30, 59.50, 39.56, 35.30, 5180, 57.27, 59.50, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('58', 'CNY', 59.99, 36.52, 63.00, 42.60, 36.52, 5460, 60.45, 63.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('59', 'CNY', 64.99, 39.56, 66.50, 45.65, 39.56, 5740, 63.63, 66.50, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('60', 'CNY', 69.99, 42.60, 70.00, 48.69, 42.60, 5950, 69.99, 70.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('61', 'CNY', 74.99, 45.65, 77.00, 51.73, 45.65, 6650, 76.36, 77.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('62', 'CNY', 79.99, 48.69, 84.00, 54.78, 48.69, 7350, 82.72, 84.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('63', 'CNY', 89.99, 54.78, 91.00, 57.82, 54.78, 8050, 89.08, 91.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('64', 'CNY', 94.99, 57.82, 98.00, 60.86, 57.82, 8750, 95.45, 98.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('65', 'CNY', 99.99, 60.86, 105.00, 66.95, 60.86, 9100, 101.81, 105.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('66', 'CNY', 109.99, 66.95, 112.00, 73.04, 66.95, 9800, 108.18, 112.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('67', 'CNY', 119.99, 73.04, 119.00, 76.08, 73.04, 10500, 114.54, 119.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('68', 'CNY', 124.99, 76.08, 126.00, 79.12, 76.08, 11200, 120.90, 126.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('69', 'CNY', 129.99, 79.12, 133.00, 85.21, 79.12, 11550, 127.27, 133.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('70', 'CNY', 139.99, 85.21, 140.00, 91.30, 85.21, 11900, 133.63, 140.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('71', 'CNY', 144.99, 88.25, 147.00, 97.39, 88.25, 12600, 139.99, 147.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('72', 'CNY', 149.99, 91.30, 154.00, 103.47, 91.30, 13300, 146.36, 154.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('73', 'CNY', 159.99, 97.39, 161.00, 109.56, 97.39, 14000, 152.72, 161.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('74', 'CNY', 169.99, 103.47, 168.00, 115.65, 103.47, 14700, 159.08, 168.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('75', 'CNY', 174.99, 106.52, 175.00, 121.73, 106.52, 15400, 171.81, 175.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('76', 'CNY', 199.99, 121.73, 210.00, 146.08, 121.73, 18200, 203.63, 210.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('77', 'CNY', 249.99, 152.17, 245.00, 170.43, 152.17, 21000, 241.81, 245.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('78', 'CNY', 299.99, 182.60, 280.00, 194.78, 182.60, 24500, 273.63, 280.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('79', 'CNY', 324.99, 197.82, 315.00, 219.12, 197.82, 27300, 318.18, 315.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('80', 'CNY', 349.99, 213.04, 350.00, 243.47, 213.04, 29750, 349.99, 350.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('81', 'CNY', 399.99, 243.47, 420.00, 292.17, 243.47, 35000, 413.63, 420.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('82', 'CNY', 499.99, 304.34, 490.00, 340.86, 304.34, 42000, 477.27, 490.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('83', 'CNY', 549.99, 334.78, 560.00, 389.56, 334.78, 49000, 540.90, 560.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('84', 'CNY', 599.99, 365.21, 630.00, 438.25, 365.21, 56000, 604.54, 630.00, '15-07-2011')"];
    [queries addObject:@"INSERT INTO tiers (tier, currency_code, price, royalty, royalty_in_usd, royalty_in_eur, royalty_in_gbp, royalty_in_jpy, royalty_in_aud, royalty_in_cad, from_date) VALUES ('85', 'CNY', 699.99, 426.08, 700.00, 486.95, 426.08, 59500, 668.18, 700.00, '15-07-2011')"];
    
    for (NSString *query in queries) {
        sqlite3_prepare_v2(_db, [query UTF8String], -1, &statement, NULL);
        sqlite3_step(statement);	
        sqlite3_finalize(statement);
    }
    
    [queries release];
     
    [self addSchema:10 version:@"1.5.2"];
}

- (void)updateTo153 {
    NSMutableArray *curriencies = [[NSMutableArray alloc] init];
    
    [curriencies addObject:@"INSERT INTO 'currencies' ('currency_code', 'tier_currency_code', 'version') VALUES ('USD', 'USD', 3)"];
    [curriencies addObject:@"INSERT INTO 'currencies' ('currency_code', 'tier_currency_code', 'version') VALUES ('MXN', 'MXN', 3)"];
    [curriencies addObject:@"INSERT INTO 'currencies' ('currency_code', 'tier_currency_code', 'version') VALUES ('CAD', 'CAD', 3)"];
    [curriencies addObject:@"INSERT INTO 'currencies' ('currency_code', 'tier_currency_code', 'version') VALUES ('GBP', 'GBP', 3)"];
    [curriencies addObject:@"INSERT INTO 'currencies' ('currency_code', 'tier_currency_code', 'version') VALUES ('EUR', 'EUR', 3)"];
    [curriencies addObject:@"INSERT INTO 'currencies' ('currency_code', 'tier_currency_code', 'version') VALUES ('CHF', 'CHF', 3)"];
    [curriencies addObject:@"INSERT INTO 'currencies' ('currency_code', 'tier_currency_code', 'version') VALUES ('NOK', 'NOK', 3)"];
    [curriencies addObject:@"INSERT INTO 'currencies' ('currency_code', 'tier_currency_code', 'version') VALUES ('AUD', 'AUD', 3)"];
    [curriencies addObject:@"INSERT INTO 'currencies' ('currency_code', 'tier_currency_code', 'version') VALUES ('NZD', 'NZD', 3)"];
    [curriencies addObject:@"INSERT INTO 'currencies' ('currency_code', 'tier_currency_code', 'version') VALUES ('JPY', 'JPY', 3)"];
    [curriencies addObject:@"INSERT INTO 'currencies' ('currency_code', 'tier_currency_code', 'version') VALUES ('MXN', 'MXP', 3)"];
    [curriencies addObject:@"INSERT INTO 'currencies' ('currency_code', 'tier_currency_code', 'version') VALUES ('DKK', 'DKK', 3)"];
    [curriencies addObject:@"INSERT INTO 'currencies' ('currency_code', 'tier_currency_code', 'version') VALUES ('SEK', 'SEK', 3)"];
    [curriencies addObject:@"INSERT INTO 'currencies' ('currency_code', 'tier_currency_code', 'version') VALUES ('CNY', 'CNY', 3)"];
    
    for (NSString *curriency in curriencies) {
        sqlite3_stmt *statement;
        
        sqlite3_prepare_v2(_db, [curriency UTF8String], -1, &statement, NULL);
        sqlite3_step(statement);	
        sqlite3_finalize(statement);
    }
    
    [curriencies release];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Tiers.v3" ofType:@"sql"];
    
    NSMutableArray *queries = [[NSMutableArray alloc] init];
    
    [queries addObjectsFromArray:[[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByString:@"\n"]];
     
    for (NSString *query in queries) {
        sqlite3_stmt *statement;
        
        sqlite3_prepare_v2(_db, [query UTF8String], -1, &statement, NULL);
        sqlite3_step(statement);	
        sqlite3_finalize(statement);
    }
    
    [queries release];
    
    NSString *sql = @"UPDATE 'tiers' SET version = 3 WHERE version IS NULL";
    sqlite3_stmt *statement;
    
    sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL);
	sqlite3_step(statement);	
	sqlite3_finalize(statement);
    
    sql = @"UPDATE 'tiers' SET to_date = '01-03-2012' WHERE from_date = '2011-07-20'";
    
    sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL);
	sqlite3_step(statement);	
	sqlite3_finalize(statement);
    
    [self addSchema:11 version:@"1.5.3"];
}

@end
