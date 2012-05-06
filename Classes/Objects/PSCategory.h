//
//  PSCategory.h
//  Prismo
//
//  Created by Sergey Lenkov on 30.05.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PSCategory : NSObject {
    sqlite3 *_db;
	NSInteger identifier;
	NSString *name;
	NSInteger genre;
    NSInteger type;
}

@property (nonatomic, assign) NSInteger identifier;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger genre;
@property (nonatomic, assign) NSInteger type;

- (id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db;

@end
