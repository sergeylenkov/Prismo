//
//  PSMapDetailsController.h
//  Prismo
//
//  Created by Sergey Lenkov on 01.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ImageAndTextCell.h"
#import "PSCountrySale.h"

@interface PSMapDetailsController : NSObject {
	IBOutlet NSTableView *view;
	NSMutableArray *_sales;
	NSString *lastIdentifier;
	BOOL sortAscending;
	NSNumberFormatter *formatter;
	NSNumberFormatter *numberFormatter;
	NSUserDefaults *defaults;
}

@property (assign) NSTableView *view;
@property (nonatomic, retain) NSMutableArray *sales;
	
- (void)refresh;
- (void)sortTableView:(NSTableView *)tableView byIdentifier:(NSString *)identifier ascending:(BOOL)order;

@end
