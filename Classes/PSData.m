//
//  PSData.m
//  Prismo
//
//  Created by Sergey Lenkov on 21.11.10.
//  Copyright 2010 Sergey Lenkov. All rights reserved.
//

#import "PSData.h"

static PSData *sharedInstance = nil;

@implementation PSData

@synthesize db = _db;
@synthesize applications = _applications;
@synthesize purchases = _purchases;
@synthesize subscriptions = _subscriptions;
@synthesize allSaleItems = _allSaleItems;
@synthesize stores = _stores;
@synthesize categories = _categories;
@synthesize countries = _countries;
@synthesize saleTypes = _saleTypes;
@synthesize updateTypes = _updateTypes;
@synthesize appTypes = _appTypes;
@synthesize pops = _pops;
@synthesize currencyColumn = _currencyColumn;
@synthesize currencySymbol = _currencySymbol;
@synthesize graphTypes = _graphTypes;

+ (PSData *)sharedData {
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [[PSData alloc] init];
        }
    }
    
    return sharedInstance;
}

- (id)init {
    self = [super init];
    
    if (self) {
        _db = [Database sharedDatabase];
        
        _applications = [[NSMutableArray alloc] init];
        _purchases = [[NSMutableArray alloc] init];
        _subscriptions = [[NSMutableArray alloc] init];
        _allSaleItems = [[NSMutableArray alloc] init];
        _stores = [[NSMutableArray alloc] init];
        _categories = [[NSMutableArray alloc] init];
        _countries = [[NSMutableArray alloc] init];
        _pops = [[NSMutableArray alloc] init];
        _countriesDictionary = [[NSMutableDictionary alloc] init];
        
        _saleTypes = [[NSArray arrayWithObjects:@"1", @"IA1", @"IA9", @"IAY", @"1T", @"1F", @"F1", @"FI1", nil] retain];
        _updateTypes = [[NSArray arrayWithObjects:@"7", @"7T", @"7F", @"F7", nil] retain];
        _appTypes = [[NSArray arrayWithObjects:@"1", @"1T", @"1F", @"F1", nil] retain];
        
        _euroZoneCodes = @"'AT', 'BE', 'BG', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'DE', 'GR', 'HU', 'IE', 'IT', 'LV', 'LT', 'LU', 'MT', 'NL', 'PL', 'PT', 'RO', 'SK', 'SI', 'ES', 'SE'";
        _americasCodes = @"'AI', 'AG', 'AR', 'BS', 'BB', 'BZ', 'BM', 'BO', 'BR', 'IO', 'KY', 'CL', 'CO', 'CR', 'DM', 'DO', 'EC', 'SV', 'GD', 'GT', 'GY', 'HN', 'JM', 'MS', 'NI', 'PA', 'PY', 'PE', 'KN', 'LC', 'VC', 'SR', 'TT', 'TC', 'US', 'UY', 'VE'";
        
        _graphTypes = [[NSArray arrayWithObjects:@"Total", @"Downloads", @"Sales", @"Updates", @"Revenue", nil] retain];
        
        defaults = [NSUserDefaults standardUserDefaults];
    }
    
    return self;
}

- (void)dealloc {
    [_applications release];
    [_purchases release];
	[_subscriptions release];
    [_allSaleItems release];
    [_stores release];
    [_categories release];
    [_pops release];
    [_countries release];
    [_countriesDictionary release];
    [_saleTypes release];
    [_updateTypes release];
    [_appTypes release];
    [_currencyColumn release];
    [_currencySymbol release];
    [_euroZoneCodes release];
    [_americasCodes release];
    [_graphTypes release];
    
    [super dealloc];
}

- (NSString *)currencyColumn {    
    int currencyIndex = [[defaults objectForKey:@"Currency"] intValue];
    
    switch (currencyIndex) {
        case 0:
            _currencyColumn = @"royalty_in_usd";
            break;
        case 1:
            _currencyColumn = @"royalty_in_eur";
            break;
        case 2:
            _currencyColumn = @"royalty_in_gbp";
            break;
        case 3:
            _currencyColumn = @"royalty_in_jpy";
            break;
        case 4:
            _currencyColumn = @"royalty_in_aud";
            break;
        case 5:
            _currencyColumn = @"royalty_in_cad";
            break;
        default:
            _currencyColumn = @"royalty_in_usd";
            break;
    }
    
    return _currencyColumn;
}

- (NSString *)currencySymbol {
    int currencyIndex = [[defaults objectForKey:@"Currency"] intValue];
    
    _currencySymbol = @"$";
    
    if (currencyIndex == 1) {
        _currencySymbol = @"€";
    }
    
    if (currencyIndex == 2) {
        _currencySymbol = @"£";
    }
    
    if (currencyIndex == 3) {
        _currencySymbol = @"¥";
    }
    
    return _currencySymbol;
}

- (NSString *)countryNameByCode:(NSString *)code {
    return [_countriesDictionary objectForKey:code];
}

- (void)reloadData {
    [self reloadReferences];
}

- (void)reloadReferences {
    [_applications removeAllObjects];
    [_purchases removeAllObjects];
    [_subscriptions removeAllObjects];
    [_allSaleItems removeAllObjects];
    [_stores removeAllObjects];
    [_pops removeAllObjects];
    [_countries removeAllObjects];
    [_categories removeAllObjects];
    [_countriesDictionary removeAllObjects];
    
    NSString *sql = @"SELECT id FROM applications ORDER BY name";
	sqlite3_stmt *statement;
    
	if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
			PSApplication *application = [[PSApplication alloc] initWithPrimaryKey:sqlite3_column_int(statement, 0) database:_db];
            
			if ([application.type isEqualToString:@"iphone"] || [application.type isEqualToString:@"ipad"] || [application.type isEqualToString:@"universal"] || [application.type isEqualToString:@"mac"]) {
                [_applications addObject:application];
                [_allSaleItems addObject:application];
            }
            
            if ([application.type isEqualToString:@"in-app"]) {
                [_purchases addObject:application];
                [_allSaleItems addObject:application];
            }
            
            if ([application.type isEqualToString:@"subscription"]) {
                [_subscriptions addObject:application];
                [_allSaleItems addObject:application];
            }

			[application release];
		}
	}
	
	sqlite3_finalize(statement);
    
    sql = @"SELECT id FROM stores ORDER BY name";
    
	if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
            PSStore *store = [[PSStore alloc] initWithPrimaryKey:sqlite3_column_int(statement, 0) database:_db];
            
            [_stores addObject:store];
            [store release];
		}
	}
	
	sqlite3_finalize(statement);
    
    sql = @"SELECT id FROM pops ORDER BY name";
	
	if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
			PSPop *pop = [[PSPop alloc] initWithPrimaryKey:sqlite3_column_int(statement, 0) database:_db];
            
			[_pops addObject:pop];
			[pop release];
		}
	}
	
	sqlite3_finalize(statement);
    
    sql = @"SELECT code, name FROM countries ORDER BY name";
	
	if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
			PSCountry *country = [[PSCountry alloc] init];
            
			country.code = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
			country.name = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)];
            
            [_countriesDictionary setObject:country.name forKey:country.code];
			[_countries addObject:country];
            
			[country release];
		}
	}
	
	sqlite3_finalize(statement);  
    
    sql = @"SELECT id FROM categories ORDER BY type_id, genre_id";
	
	if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
            PSCategory *category = [[PSCategory alloc] initWithPrimaryKey:sqlite3_column_int(statement, 0) database:_db];
            
            [_categories addObject:category];
            [category release];
		}
	}
	
	sqlite3_finalize(statement);
}

- (NSInteger)newReviewsCount {
    NSInteger count = 0;
    
    NSString *sql = @"SELECT COUNT(*) FROM reviews WHERE is_new = 1";
    sqlite3_stmt *statement;
    
	if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
		if (sqlite3_step(statement) == SQLITE_ROW) {
			count = sqlite3_column_int(statement, 0);
		}
	}
	
	sqlite3_finalize(statement);
    
    return count;
}

- (NSInteger)totalDownloads {
    NSInteger count = 0;
    
    NSString *sql = @"SELECT TOTAL(units) FROM sales";
    sqlite3_stmt *statement;
    
	if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
		if (sqlite3_step(statement) == SQLITE_ROW) {
			count = sqlite3_column_int(statement, 0);
		}
	}
	
	sqlite3_finalize(statement);
    
    return count;
}

- (NSArray *)salesFromDate:(NSDate *)from toDate:(NSDate *)to {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT date, \
                                                        SUM(ABS(units)) AS total, \
                                                        SUM(units * %@) AS royalty, \
                                                        SUM(CASE WHEN type_id IN ('7', '7T', '7F', 'F7') THEN units ELSE 0 END) AS updates, \
                                                        SUM(CASE WHEN units < 0 THEN ABS(units) ELSE 0 END) AS refunds, \
                                                        SUM(CASE WHEN (type_id IN ('1', 'IA1', 'IA9', 'IAY', '1T', '1F', 'F1', 'FI1') AND royalty > 0.0 AND units > 0) THEN units ELSE 0 END) AS sales \
                                                 FROM sales WHERE date >= ? AND date <= ? GROUP BY date ORDER BY date", self.currencyColumn];
    sqlite3_stmt *statement;
    
	if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [[from dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 2, [[to dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
        
		while (sqlite3_step(statement) == SQLITE_ROW) {
			PSSale *sale = [[PSSale alloc] init];
            
            sale.date = [NSDate dateFromDbString:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)]];
            sale.total = [NSNumber numberWithInt:sqlite3_column_int(statement, 1)];
            sale.sales = [NSNumber numberWithInt:sqlite3_column_int(statement, 5)];
            sale.updates = [NSNumber numberWithInt:sqlite3_column_int(statement, 3)];
            sale.refunds = [NSNumber numberWithInt:sqlite3_column_int(statement, 4)];
            sale.revenue = [NSNumber numberWithDouble:sqlite3_column_double(statement, 2)];
            sale.downloads = [NSNumber numberWithInt:sqlite3_column_int(statement, 1) - sqlite3_column_int(statement, 5) - sqlite3_column_int(statement, 3) - sqlite3_column_int(statement, 4)];

            [result addObject:sale];
            [sale release];
		}
	}
	
	sqlite3_finalize(statement);
    
    return [result autorelease];
}

- (NSArray *)salesFromDate:(NSDate *)from toDate:(NSDate *)to application:(PSApplication *)application {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT date, \
                                                        SUM(ABS(units)) AS total, \
                                                        SUM(units * %@) AS royalty, \
                                                        SUM(CASE WHEN type_id IN ('7', '7T', '7F', 'F7') THEN units ELSE 0 END) AS updates, \
                                                        SUM(CASE WHEN units < 0 THEN ABS(units) ELSE 0 END) AS refunds, \
                                                        SUM(CASE WHEN (type_id IN ('1', 'IA1', 'IA9', 'IAY', '1T', '1F', 'F1', 'FI1') AND royalty > 0.0 AND units > 0) THEN units ELSE 0 END) AS sales \
                                                   FROM sales WHERE apple_id = ? AND (date >= ? AND date <= ?) GROUP BY date ORDER BY date", self.currencyColumn];
    sqlite3_stmt *statement;
    
    
	if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [[NSString stringWithFormat:@"%d", application.identifier] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 2, [[from dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 3, [[to dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
        
		while (sqlite3_step(statement) == SQLITE_ROW) {
			PSSale *sale = [[PSSale alloc] init];
            
            sale.date = [NSDate dateFromDbString:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)]];
            sale.total = [NSNumber numberWithInt:sqlite3_column_int(statement, 1)];
            sale.sales = [NSNumber numberWithInt:sqlite3_column_int(statement, 5)];
            sale.updates = [NSNumber numberWithInt:sqlite3_column_int(statement, 3)];
            sale.refunds = [NSNumber numberWithInt:sqlite3_column_int(statement, 4)];
            sale.revenue = [NSNumber numberWithDouble:sqlite3_column_double(statement, 2)];
            sale.downloads = [NSNumber numberWithInt:sqlite3_column_int(statement, 1) - sqlite3_column_int(statement, 5) - sqlite3_column_int(statement, 3) - sqlite3_column_int(statement, 4)];
            
            [result addObject:sale];
            [sale release];
		}
	}
	
	sqlite3_finalize(statement);
    
    return [result autorelease];
}

- (PSSale *)saleForDate:(NSDate *)date {
    int total = 0;
    int downloads = 0;
    int sales = 0;
    int updates = 0;
    int refunds = 0;
    float revenue = 0.0;
    
    NSString *sql = [NSString stringWithFormat:@"SELECT SUM(ABS(units)) AS total, \
                     SUM(units * %@) AS royalty, \
                     SUM(CASE WHEN type_id IN ('7', '7T', '7F', 'F7') THEN units ELSE 0 END) AS updates, \
                     SUM(CASE WHEN units < 0 THEN ABS(units) ELSE 0 END) AS refunds, \
                     SUM(CASE WHEN (type_id IN ('1', 'IA1', 'IA9', 'IAY', '1T', '1F', 'F1', 'FI1') AND royalty > 0.0 AND units > 0) THEN units ELSE 0 END) AS sales \
                     FROM sales WHERE date = ?", self.currencyColumn];
    sqlite3_stmt *statement;
    
    
	if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [[date dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
        
		while (sqlite3_step(statement) == SQLITE_ROW) {
			total = sqlite3_column_int(statement, 0);
            sales = sqlite3_column_int(statement, 4);
            updates = sqlite3_column_int(statement, 2);
            refunds = sqlite3_column_int(statement, 3);
            revenue = sqlite3_column_double(statement, 1);
            downloads = sqlite3_column_int(statement, 0) - sqlite3_column_int(statement, 4) - sqlite3_column_int(statement, 2) - sqlite3_column_int(statement, 3);
		}
	}
	
	sqlite3_finalize(statement);
    
    PSSale *sale = [[PSSale alloc] init];
    
    sale.date = date;
    sale.total = [NSNumber numberWithInt:total];
    sale.sales = [NSNumber numberWithInt:sales];
    sale.updates = [NSNumber numberWithInt:updates];
    sale.refunds = [NSNumber numberWithInt:refunds];
    sale.revenue = [NSNumber numberWithDouble:revenue];
    sale.downloads = [NSNumber numberWithInt:downloads];
    
    return [sale autorelease];
}

- (PSSale *)saleForDate:(NSDate *)date application:(PSApplication *)application {
    int total = 0;
    int downloads = 0;
    int sales = 0;
    int updates = 0;
    int refunds = 0;
    float revenue = 0.0;
    
    NSString *sql = [NSString stringWithFormat:@"SELECT SUM(ABS(units)) AS total, \
                                                        SUM(units * %@) AS royalty, \
                                                        SUM(CASE WHEN type_id IN ('7', '7T', '7F', 'F7') THEN units ELSE 0 END) AS updates, \
                                                        SUM(CASE WHEN units < 0 THEN ABS(units) ELSE 0 END) AS refunds, \
                                                        SUM(CASE WHEN (type_id IN ('1', 'IA1', 'IA9', 'IAY', '1T', '1F', 'F1', 'FI1') AND royalty > 0.0 AND units > 0) THEN units ELSE 0 END) AS sales \
                                                   FROM sales WHERE apple_id = ? AND date = ?", self.currencyColumn];
    sqlite3_stmt *statement;
    
    
	if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [[NSString stringWithFormat:@"%d", application.identifier] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 2, [[date dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
        
		while (sqlite3_step(statement) == SQLITE_ROW) {
			total = sqlite3_column_int(statement, 0);
            sales = sqlite3_column_int(statement, 4);
            updates = sqlite3_column_int(statement, 2);
            refunds = sqlite3_column_int(statement, 3);
            revenue = sqlite3_column_double(statement, 1);
            downloads = sqlite3_column_int(statement, 0) - sqlite3_column_int(statement, 4) - sqlite3_column_int(statement, 2) - sqlite3_column_int(statement, 3);
		}
	}
	
	sqlite3_finalize(statement);
    
    PSSale *sale = [[PSSale alloc] init];
    
    sale.date = date;
    sale.total = [NSNumber numberWithInt:total];
    sale.sales = [NSNumber numberWithInt:sales];
    sale.updates = [NSNumber numberWithInt:updates];
    sale.refunds = [NSNumber numberWithInt:refunds];
    sale.revenue = [NSNumber numberWithDouble:revenue];
    sale.downloads = [NSNumber numberWithInt:downloads];
    
    return [sale autorelease];
}

- (PSSale *)totalSaleFromDate:(NSDate *)from toDate:(NSDate *)to application:(PSApplication *)application {
    int total = 0;
    int downloads = 0;
    int sales = 0;
    int updates = 0;
    int refunds = 0;
    float revenue = 0.0;
    
    NSString *sql = [NSString stringWithFormat:@"SELECT SUM(ABS(units)) AS total, \
                     SUM(units * %@) AS royalty, \
                     SUM(CASE WHEN type_id IN ('7', '7T', '7F', 'F7') THEN units ELSE 0 END) AS updates, \
                     SUM(CASE WHEN units < 0 THEN ABS(units) ELSE 0 END) AS refunds, \
                     SUM(CASE WHEN (type_id IN ('1', 'IA1', 'IA9', 'IAY', '1T', '1F', 'F1', 'FI1') AND royalty > 0.0 AND units > 0) THEN units ELSE 0 END) AS sales \
                     FROM sales WHERE apple_id = ? AND (date >= ? AND date <= ?)", self.currencyColumn];
    sqlite3_stmt *statement;
    
    
	if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [[NSString stringWithFormat:@"%d", application.identifier] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 2, [[from dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 3, [[to dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
        
		while (sqlite3_step(statement) == SQLITE_ROW) {
			total = sqlite3_column_int(statement, 0);
            sales = sqlite3_column_int(statement, 4);
            updates = sqlite3_column_int(statement, 2);
            refunds = sqlite3_column_int(statement, 3);
            revenue = sqlite3_column_double(statement, 1);
            downloads = sqlite3_column_int(statement, 0) - sqlite3_column_int(statement, 4) - sqlite3_column_int(statement, 2) - sqlite3_column_int(statement, 3);
		}
	}
	
	sqlite3_finalize(statement);
    
    PSSale *sale = [[PSSale alloc] init];
    
    sale.total = [NSNumber numberWithInt:total];
    sale.sales = [NSNumber numberWithInt:sales];
    sale.updates = [NSNumber numberWithInt:updates];
    sale.refunds = [NSNumber numberWithInt:refunds];
    sale.revenue = [NSNumber numberWithDouble:revenue];
    sale.downloads = [NSNumber numberWithInt:downloads];
    
    return [sale autorelease];
}

- (PSSale *)totalSaleForApplication:(PSApplication *)application {
    int total = 0;
    int downloads = 0;
    int sales = 0;
    int updates = 0;
    int refunds = 0;
    float revenue = 0.0;
    
    NSString *sql = [NSString stringWithFormat:@"SELECT SUM(ABS(units)) AS total, \
                                                        SUM(units * %@) AS royalty, \
                                                        SUM(CASE WHEN type_id IN ('7', '7T', '7F', 'F7') THEN units ELSE 0 END) AS updates, \
                                                        SUM(CASE WHEN units < 0 THEN ABS(units) ELSE 0 END) AS refunds, \
                                                        SUM(CASE WHEN (type_id IN ('1', 'IA1', 'IA9', 'IAY', '1T', '1F', 'F1', 'FI1') AND royalty > 0.0 AND units > 0) THEN units ELSE 0 END) AS sales \
                                                   FROM sales WHERE apple_id = ?", self.currencyColumn];
    sqlite3_stmt *statement;
    
    
	if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [[NSString stringWithFormat:@"%d", application.identifier] UTF8String], -1, SQLITE_TRANSIENT);
        
		if (sqlite3_step(statement) == SQLITE_ROW) {
            total = sqlite3_column_int(statement, 0);
            sales = sqlite3_column_int(statement, 4);
            updates = sqlite3_column_int(statement, 2);
            refunds = sqlite3_column_int(statement, 3);
            revenue = sqlite3_column_double(statement, 1);
            downloads = sqlite3_column_int(statement, 0) - sqlite3_column_int(statement, 4) - sqlite3_column_int(statement, 2) - sqlite3_column_int(statement, 3);
		}
	}
	
	sqlite3_finalize(statement);
    
    PSSale *sale = [[PSSale alloc] init];
    
    sale.total = [NSNumber numberWithInt:total];
    sale.sales = [NSNumber numberWithInt:sales];
    sale.updates = [NSNumber numberWithInt:updates];
    sale.refunds = [NSNumber numberWithInt:refunds];
    sale.revenue = [NSNumber numberWithDouble:revenue];
    sale.downloads = [NSNumber numberWithInt:downloads];
    
    return [sale autorelease];
}

- (PSSale *)totalSale {
    int total = 0;
    int downloads = 0;
    int sales = 0;
    int updates = 0;
    int refunds = 0;
    float revenue = 0.0;
    
    NSString *sql = [NSString stringWithFormat:@"SELECT SUM(ABS(units)) AS total, \
                                                        SUM(units * %@) AS royalty, \
                                                        SUM(CASE WHEN type_id IN ('7', '7T', '7F', 'F7') THEN units ELSE 0 END) AS updates, \
                                                        SUM(CASE WHEN units < 0 THEN ABS(units) ELSE 0 END) AS refunds, \
                                                        SUM(CASE WHEN (type_id IN ('1', 'IA1', 'IA9', 'IAY', '1T', '1F', 'F1', 'FI1') AND royalty > 0.0 AND units > 0) THEN units ELSE 0 END) AS sales \
                                                 FROM sales", self.currencyColumn];
    sqlite3_stmt *statement;
    
    
	if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
		if (sqlite3_step(statement) == SQLITE_ROW) {
            total = sqlite3_column_int(statement, 0);
            sales = sqlite3_column_int(statement, 4);
            updates = sqlite3_column_int(statement, 2);
            refunds = sqlite3_column_int(statement, 3);
            revenue = sqlite3_column_double(statement, 1);
            downloads = sqlite3_column_int(statement, 0) - sqlite3_column_int(statement, 4) - sqlite3_column_int(statement, 2) - sqlite3_column_int(statement, 3);
		}
	}
	
	sqlite3_finalize(statement);
    
    PSSale *sale = [[PSSale alloc] init];
    
    sale.total = [NSNumber numberWithInt:total];
    sale.sales = [NSNumber numberWithInt:sales];
    sale.updates = [NSNumber numberWithInt:updates];
    sale.refunds = [NSNumber numberWithInt:refunds];
    sale.revenue = [NSNumber numberWithDouble:revenue];
    sale.downloads = [NSNumber numberWithInt:downloads];
    
    return [sale autorelease];
}

- (NSArray *)salesByCountriesFromDate:(NSDate *)from toDate:(NSDate *)to {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT country_code, \
                                                        SUM(ABS(units)) AS total, \
                                                        SUM(units * %@) AS royalty, \
                                                        SUM(CASE WHEN type_id IN ('7', '7T', '7F', 'F7') THEN units ELSE 0 END) AS updates, \
                                                        SUM(CASE WHEN units < 0 THEN ABS(units) ELSE 0 END) AS refunds, \
                                                        SUM(CASE WHEN (type_id IN ('1', 'IA1', 'IA9', 'IAY', '1T', '1F', 'F1', 'FI1') AND royalty > 0.0 AND units > 0) THEN units ELSE 0 END) AS sales \
                                                FROM sales WHERE date >= ? AND date <= ? GROUP BY country_code", self.currencyColumn];
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [[from dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 2, [[to dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
        
        while (sqlite3_step(statement) == SQLITE_ROW) {
            PSCountrySale *sale = [[PSCountrySale alloc] init];
            
            sale.code = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
            sale.total = [NSNumber numberWithInt:sqlite3_column_int(statement, 1)];
            sale.sales = [NSNumber numberWithInt:sqlite3_column_int(statement, 5)];
            sale.updates = [NSNumber numberWithInt:sqlite3_column_int(statement, 3)];
            sale.refunds = [NSNumber numberWithInt:sqlite3_column_int(statement, 4)];
            sale.revenue = [NSNumber numberWithDouble:sqlite3_column_double(statement, 2)];
            sale.downloads = [NSNumber numberWithInt:sqlite3_column_int(statement, 1) - sqlite3_column_int(statement, 5) - sqlite3_column_int(statement, 3) - sqlite3_column_int(statement, 4)];

            [result addObject:sale];
            [sale release];
        }
    }
    
    sqlite3_finalize(statement);
    
    return [result autorelease];
}

- (NSArray *)salesByCountriesFromDate:(NSDate *)from toDate:(NSDate *)to application:(PSApplication *)application {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT country_code, \
                                                        SUM(ABS(units)) AS total, \
                                                        SUM(units * %@) AS royalty, \
                                                        SUM(CASE WHEN type_id IN ('7', '7T', '7F', 'F7') THEN units ELSE 0 END) AS updates, \
                                                        SUM(CASE WHEN units < 0 THEN ABS(units) ELSE 0 END) AS refunds, \
                                                        SUM(CASE WHEN (type_id IN ('1', 'IA1', 'IA9', 'IAY', '1T', '1F', 'F1', 'FI1') AND royalty > 0.0 AND units > 0) THEN units ELSE 0 END) AS sales \
                                                FROM sales WHERE apple_id = ? AND (date >= ? AND date <= ?) GROUP BY country_code", self.currencyColumn];
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [[NSString stringWithFormat:@"%d", application.identifier] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 2, [[from dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 3, [[to dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
        
        while (sqlite3_step(statement) == SQLITE_ROW) {
            PSCountrySale *sale = [[PSCountrySale alloc] init];
            
            sale.code = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
            sale.total = [NSNumber numberWithInt:sqlite3_column_int(statement, 1)];
            sale.sales = [NSNumber numberWithInt:sqlite3_column_int(statement, 5)];
            sale.updates = [NSNumber numberWithInt:sqlite3_column_int(statement, 3)];
            sale.refunds = [NSNumber numberWithInt:sqlite3_column_int(statement, 4)];
            sale.revenue = [NSNumber numberWithDouble:sqlite3_column_double(statement, 2)];
            sale.downloads = [NSNumber numberWithInt:sqlite3_column_int(statement, 1) - sqlite3_column_int(statement, 5) - sqlite3_column_int(statement, 3) - sqlite3_column_int(statement, 4)];
            
            [result addObject:sale];
            [sale release];
        }
    }
    
    sqlite3_finalize(statement);
    
    return [result autorelease];
}

- (NSDictionary *)revenueByCurrenciesFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate {
	NSString *sql = @"SELECT c.tier_currency_code, TOTAL(s.units * s.royalty) FROM currencies c, sales s \
                       WHERE c.currency_code = s.currency_code AND c.version = 2 AND s.date >= ? AND s.date <= ? AND s.type_id IN ('1', 'IA1', 'IA9', 'IAY', '1T', '1F', 'F1') \
                    GROUP BY c.tier_currency_code ORDER BY c.tier_currency_code";
	sqlite3_stmt *statement;
	
	NSMutableArray *objects = [[NSMutableArray alloc] init];
	NSMutableArray *keys = [[NSMutableArray alloc] init];
	
	if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_text(statement, 1, [[fromDate dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 2, [[toDate dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
		
		while (sqlite3_step(statement) == SQLITE_ROW) {
			[keys addObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)]];
			[objects addObject:[NSNumber numberWithDouble:sqlite3_column_double(statement, 1)]];
		}
	}
	
	sqlite3_finalize(statement);
	
	NSDictionary *dict = [[[NSDictionary alloc] initWithObjects:objects forKeys:keys] autorelease];
	
	[objects release];
	[keys release];
	
	return dict;
}

- (NSNumber *)revenueForRegion:(NSString *)region fromDate:(NSDate *)fromDate toDate:(NSDate *)toDate {
	float amount = 0.0;
	
	if ([region isEqualToString:@"EUROPE"]) {
		NSString *sql = [NSString stringWithFormat:@"SELECT TOTAL(units * %@) FROM sales WHERE country_code IN (%@) AND date >= ? AND date <= ? AND type_id IN ('1', 'IA1', 'IA9', 'IAY', '1T', '1F', 'F1')", self.currencyColumn, _euroZoneCodes];
		sqlite3_stmt *statement;

		if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
			sqlite3_bind_text(statement, 1, [[fromDate dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [[toDate dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
			
			if (sqlite3_step(statement) == SQLITE_ROW) {
				amount = sqlite3_column_double(statement, 0);
			}
		}
		
		sqlite3_finalize(statement);
	} else if ([region isEqualToString:@"AMERICAS"]) {
        NSString *sql = [NSString stringWithFormat:@"SELECT TOTAL(units * %@) FROM sales WHERE country_code IN (%@) AND date >= ? AND date <= ? AND type_id IN ('1', 'IA1', 'IA9', 'IAY', '1T', '1F', 'F1')", self.currencyColumn, _americasCodes];
		sqlite3_stmt *statement;

		if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
			sqlite3_bind_text(statement, 1, [[fromDate dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [[toDate dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
			
			if (sqlite3_step(statement) == SQLITE_ROW) {
				amount = sqlite3_column_double(statement, 0);
			}
		}
		
		sqlite3_finalize(statement);
    } else {
		NSString *sql = [NSString stringWithFormat:@"SELECT TOTAL(units * %@) FROM sales WHERE country_code = ? AND date >= ? AND date <= ? AND type_id IN ('1', 'IA1', 'IA9', 'IAY', '1T', '1F', 'F1')", self.currencyColumn];
		sqlite3_stmt *statement;
		
		if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
			sqlite3_bind_text(statement, 1, [region UTF8String], -1, SQLITE_TRANSIENT);
			sqlite3_bind_text(statement, 2, [[fromDate dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, [[toDate dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
			
			if (sqlite3_step(statement) == SQLITE_ROW) {
				amount = sqlite3_column_double(statement, 0);
			}
		}
		
		sqlite3_finalize(statement);
	}
    
	return [NSNumber numberWithFloat:amount];
}

- (NSNumber *)revenueFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate {
	NSString *sql = [NSString stringWithFormat:@"SELECT TOTAL(units * %@) FROM sales WHERE date >= ? AND date <= ? AND type_id IN ('1', 'IA1', 'IA9', 'IAY', '1T', '1F', 'F1')", self.currencyColumn];
	sqlite3_stmt *statement;
	float amount = 0.0;
	
	if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_text(statement, 1, [[fromDate dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 2, [[toDate dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
        
		if (sqlite3_step(statement) == SQLITE_ROW) {
			amount = sqlite3_column_double(statement, 0);
		}
	}
	
	sqlite3_finalize(statement);
    
	return [NSNumber numberWithFloat:amount];
}

- (NSDate *)minDateForTop:(PSTop *)top application:(PSApplication *)application {
    NSString *sql = @"SELECT MIN(date) FROM ranks WHERE store_id = ? AND category_id = ? AND application_id = ? AND pop_id = ?";
    sqlite3_stmt *statement;
    NSDate *date = [NSDate date];

    if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_int(statement, 1, top.store.identifier);
        sqlite3_bind_int(statement, 2, top.category.identifier);
        sqlite3_bind_int(statement, 3, application.identifier);
        sqlite3_bind_int(statement, 4, top.pop.identifier);
                                         
		if (sqlite3_step(statement) == SQLITE_ROW && sqlite3_column_text(statement, 0) != NULL) {
			date = [NSDate dateFromDbString:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)]];
		}
	}
	
	sqlite3_finalize(statement);
    
    return date;
}

- (NSDate *)maxDateForTop:(PSTop *)top application:(PSApplication *)application {
    NSString *sql = @"SELECT MAX(date) FROM ranks WHERE store_id = ? AND category_id = ? AND application_id = ? AND pop_id = ?";
    sqlite3_stmt *statement;
    NSDate *date = [NSDate date];
    
    if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
		sqlite3_bind_int(statement, 1, top.store.identifier);
        sqlite3_bind_int(statement, 2, top.category.identifier);
        sqlite3_bind_int(statement, 3, application.identifier);
        sqlite3_bind_int(statement, 4, top.pop.identifier);
        
		if (sqlite3_step(statement) == SQLITE_ROW && sqlite3_column_text(statement, 0) != NULL) {
			date = [NSDate dateFromDbString:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)]];
		}
	}
	
	sqlite3_finalize(statement);
    
    return date;
}

- (NSDate *)minSaleDate {
    NSString *sql = @"SELECT MIN(date) FROM sales";
    sqlite3_stmt *statement;
    NSDate *date = [NSDate date];
    
    if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
		if (sqlite3_step(statement) == SQLITE_ROW && sqlite3_column_text(statement, 0) != NULL) {
			date = [NSDate dateFromDbString:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)]];
		}
	}
	
	sqlite3_finalize(statement);
    
    return date;
}

- (NSDate *)maxSaleDate {
    NSString *sql = @"SELECT MAX(date) FROM sales";
    sqlite3_stmt *statement;
    NSDate *date = [NSDate date];
    
    if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
		if (sqlite3_step(statement) == SQLITE_ROW && sqlite3_column_text(statement, 0) != NULL) {
			date = [NSDate dateFromDbString:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)]];
		}
	}
	
	sqlite3_finalize(statement);
    
    return date;
}

- (NSDate *)minSaleDateForApplication:(PSApplication *)application {
    NSString *sql = @"SELECT MIN(date) FROM sales WHERE apple_id = ?";
    sqlite3_stmt *statement;
    NSDate *date = [NSDate date];
    
    if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [[NSString stringWithFormat:@"%d", application.identifier] UTF8String], -1, SQLITE_TRANSIENT);
        
		if (sqlite3_step(statement) == SQLITE_ROW && sqlite3_column_text(statement, 0) != NULL) {
			date = [NSDate dateFromDbString:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)]];
		}
	}
	
	sqlite3_finalize(statement);
    
    return date;
}

- (NSDate *)maxSaleDateForApplication:(PSApplication *)application {
    NSString *sql = @"SELECT MAX(date) FROM sales WHERE apple_id = ?";
    sqlite3_stmt *statement;
    NSDate *date = [NSDate date];
    
    if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [[NSString stringWithFormat:@"%d", application.identifier] UTF8String], -1, SQLITE_TRANSIENT);
        
		if (sqlite3_step(statement) == SQLITE_ROW && sqlite3_column_text(statement, 0) != NULL) {
			date = [NSDate dateFromDbString:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)]];
		}
	}
	
	sqlite3_finalize(statement);
    
    return date;
}

- (NSArray *)reviewsForApplication:(PSApplication *)application {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    NSString *sql = @"SELECT id FROM reviews WHERE application_id = ?";
    sqlite3_stmt *statement;
    
	if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_int(statement, 1, application.identifier);
        
		while (sqlite3_step(statement) == SQLITE_ROW) {
			PSReview *review = [[PSReview alloc] initWithPrimaryKey:sqlite3_column_int(statement, 0) database:_db];
            
			[result addObject:review];
			[review release];
		}
	}
	
	sqlite3_finalize(statement);
    
    return [result autorelease];
}

- (NSArray *)ratingsForApplication:(PSApplication *)application {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    NSString *sql = @"SELECT id FROM ratings WHERE application_id = ?";
    sqlite3_stmt *statement;
    
	if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_int(statement, 1, application.identifier);
        
		while (sqlite3_step(statement) == SQLITE_ROW) {
			PSRating *rating = [[PSRating alloc] initWithPrimaryKey:sqlite3_column_int(statement, 0) database:_db];            
            
			[result addObject:rating];
			[rating release];
		}
	}
	
	sqlite3_finalize(statement);
    
    return [result autorelease];
}

- (NSArray *)ranksForApplication:(PSApplication *)application {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    NSString *sql = @"SELECT id FROM ranks WHERE application_id = ?";
    sqlite3_stmt *statement;
    
	if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_int(statement, 1, application.identifier);
        
		while (sqlite3_step(statement) == SQLITE_ROW) {
			PSRank *rank = [[PSRank alloc] initWithPrimaryKey:sqlite3_column_int(statement, 0) database:_db];
            
			[result addObject:rank];
			[rank release];
		}
	}
	
	sqlite3_finalize(statement);
    
    return [result autorelease];
}

- (NSArray *)ranksFromDate:(NSDate *)from toDate:(NSDate *)to application:(PSApplication *)application top:(PSTop *)top {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    NSString *sql = @"SELECT id FROM ranks WHERE application_id = ? AND store_id = ? AND category_id = ? AND pop_id = ? AND date >= ? AND date <= ?";
    sqlite3_stmt *statement;
    
	if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_int(statement, 1, application.identifier);
        sqlite3_bind_int(statement, 2, top.store.identifier);
        sqlite3_bind_int(statement, 3, top.category.identifier);
        sqlite3_bind_int(statement, 4, top.pop.identifier);
        sqlite3_bind_text(statement, 5, [[from dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(statement, 6, [[to dbDateFormat] UTF8String], -1, SQLITE_TRANSIENT);
        
		while (sqlite3_step(statement) == SQLITE_ROW) {
			PSRank *rank = [[PSRank alloc] initWithPrimaryKey:sqlite3_column_int(statement, 0) database:_db];
            
			[result addObject:rank];
			[rank release];
		}
	}
	
	sqlite3_finalize(statement);
    
    return [result autorelease];
}

@end
