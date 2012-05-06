//
//  PSRankDetailsController.h
//  Prismo
//
//  Created by Sergey Lenkov on 01.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PSRank.h"

@interface PSRankDetailsController : NSObject {
	IBOutlet NSTableView *view;
	NSMutableArray *_ranks;
	NSNumberFormatter *formatter;
	NSString *lastIdentifier;
	BOOL sortAscending;
	NSUserDefaults *defaults;
}

@property (nonatomic, assign) NSTableView *view;
@property (nonatomic, retain) NSArray *ranks;

- (void)refresh;
- (void)sortTableView:(NSTableView *)tableView byIdentifier:(NSString *)identifier ascending:(BOOL)order;

@end
