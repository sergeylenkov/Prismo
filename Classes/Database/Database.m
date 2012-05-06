//
//  Database.m
//  
//
//  Created by Sergey Lenkov on 06.10.10.
//  Copyright 2010 Sergey Lenkov. All rights reserved.
//

#import "Database.h"

static sqlite3 *_sharedDatabase = nil;
static NSString *_path = nil;

@implementation Database

+ (sqlite3 *)sharedDatabase {
    if (_sharedDatabase == nil) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSString *path = [paths objectAtIndex:0];  	
        path = [path stringByAppendingPathComponent:APPLICATION_SUPPORT_FOLDER];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if (![fileManager fileExistsAtPath:path isDirectory:nil]) {
            [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        path = [path stringByAppendingPathComponent:DATABASE];
        _path = [path copy];
        
        if (![fileManager fileExistsAtPath:path]) {
            NSString *defaultPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:DATABASE];
            [fileManager copyItemAtPath:defaultPath toPath:path error:nil];
        }
        
        if (sqlite3_open([path UTF8String], &_sharedDatabase) != SQLITE_OK) {
            sqlite3_close(_sharedDatabase);	
        }
    }
    
	return _sharedDatabase;
}

+ (void)close {
	sqlite3_close(_sharedDatabase);
    _sharedDatabase = nil;
}

+ (void)reindex {
	NSString *sql = @"REINDEX";
	sqlite3_stmt *statement;
	
	sqlite3_prepare_v2(_sharedDatabase, [sql UTF8String], -1, &statement, NULL);
	sqlite3_step(statement);	
	sqlite3_finalize(statement);
	
	sql = @"BEGIN TRANSACTION; VACUUM; COMMIT;";
	
	sqlite3_prepare_v2(_sharedDatabase, [sql UTF8String], -1, &statement, NULL);
	sqlite3_step(statement);
	sqlite3_finalize(statement);
}

+ (NSString *)path {
    return _path;
}

@end
