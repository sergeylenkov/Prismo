//
//  PSUpdater.h
//  Prismo
//
//  Created by Sergey Lenkov on 06.08.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PSUpdater : NSObject {
    sqlite3 *_db;
}

- (id)initWithDatabase:(sqlite3 *)db;
- (void)update;
- (void)backup:(NSString *)version;
- (void)addSchema:(NSInteger)schema version:(NSString *)version;
- (int)intFromVersion:(NSString *)version;
- (NSString *)versionFromInt:(int)version;
- (BOOL)isVersionExists:(NSString *)version;

- (void)updateTo139;
- (void)updateTo141;
- (void)updateTo143;
- (void)updateTo146;
- (void)updateTo150;
- (void)updateTo151;
- (void)updateTo152;
- (void)updateTo153;

@end
