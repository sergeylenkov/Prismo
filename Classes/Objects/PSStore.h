//
//  Store.h
//  Prismo
//
//  Created by Sergey Lenkov on 30.05.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PSStore : NSObject {
    sqlite3 *_db;
	NSInteger identifier;
	NSString *name;
}

@property (nonatomic, assign) NSInteger identifier;
@property (nonatomic, copy) NSString *name;

- (id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db;

@end
