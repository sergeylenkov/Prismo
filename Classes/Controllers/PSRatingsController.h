//
//  PSRatingsController.h
//  Prismo
//
//  Created by Sergey Lenkov on 01.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PSRating.h"

@interface PSRatingsController : NSObject {
	IBOutlet NSTableView *view;
	NSMutableArray *_ratings;
	NSString *lastIdentifier;
	BOOL sortAscending;
	NSUserDefaults *defaults;
}

@property (assign) NSTableView *view;
@property (nonatomic, retain) NSArray *ratings;

- (void)refresh;
- (void)sortTableView:(NSTableView *)tableView byIdentifier:(NSString *)identifier ascending:(BOOL)order;

@end

