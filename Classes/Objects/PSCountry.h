//
//  PSCountry.h
//  Prismo
//
//  Created by Sergey Lenkov on 30.05.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PSCountry : NSObject {
	NSString *name;
	NSString *code;
}

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *code;

@end
