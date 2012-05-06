//
//  PSApplication.h
//  Prismo
//
//  Created by Sergey Lenkov on 30.05.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PSApplication : NSObject {
    sqlite3 *_db;
    NSInteger identifier;
	NSString *name;
    NSString *type;
    NSString *account;
}

@property (nonatomic, assign) NSInteger identifier;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *account;

- (id)initWithPrimaryKey:(NSInteger)pk database:(sqlite3 *)db;

@end
