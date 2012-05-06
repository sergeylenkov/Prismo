//
//  PSApplication.m
//  Prismo
//
//  Created by Sergey Lenkov on 30.05.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSApplication.h"

@implementation PSApplication

@synthesize identifier;
@synthesize name;
@synthesize type;
@synthesize account;

- (void)dealloc {
	[name release];
    [type release];
    [account release];
	[super dealloc];
}

- (id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db {
    self = [super init];
    
    if (self) {
        _db = db;
        self.identifier = pk;
        
        NSString *sql = @"SELECT name, type, account FROM applications WHERE id = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_int(statement, 1, identifier);
            
            if (sqlite3_step(statement) == SQLITE_ROW) {
                self.name = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
                self.type = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)];
                self.account = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 2)];
            }
        }
        
        sqlite3_finalize(statement);
    }
    
    return self;
}

@end
