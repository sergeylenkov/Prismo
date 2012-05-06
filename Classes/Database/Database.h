//
//  Database.h
//  
//
//  Created by Sergey Lenkov on 06.10.10.
//  Copyright 2010 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <sqlite3.h>

@interface Database : NSObject {

}

+ (sqlite3 *)sharedDatabase;
+ (void)close;
+ (void)reindex;
+ (NSString *)path;

@end
