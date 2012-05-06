//
//  PSCategory.m
//  Prismo
//
//  Created by Sergey Lenkov on 30.05.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSCategory.h"

@implementation PSCategory

@synthesize identifier;
@synthesize name;
@synthesize genre;
@synthesize type;

- (void)dealloc {
	[name release];
	[super dealloc];
}

- (id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db {
    self = [super init];
    
    if (self) {
        _db = db;
        self.identifier = pk;
        
        NSString *sql = @"SELECT name, genre_id, type_id FROM categories WHERE id = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_int(statement, 1, identifier);
            
            if (sqlite3_step(statement) == SQLITE_ROW) {
                self.name = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
                self.genre = sqlite3_column_int(statement, 1);
                self.type = sqlite3_column_int(statement, 2);
            }
        }
        
        sqlite3_finalize(statement);
    }
    
    return self;
}

@end
