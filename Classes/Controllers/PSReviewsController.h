//
//  PSReviewsController.h
//  Prismo
//
//  Created by Sergey Lenkov on 01.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "PSReview.h"

@interface PSReviewsController : NSObject {
	IBOutlet NSTableView *view;
	IBOutlet WebView *reviewTextView;
	IBOutlet NSSplitView *splitView;
	NSMutableArray *_reviews;
	NSString *lastIdentifier;
	BOOL sortAscending;
	NSUserDefaults *defaults;
}

@property (nonatomic, retain) NSArray *reviews;
@property (nonatomic, retain, readonly) NSView *printableView;

- (void)refresh;
- (void)sortTableView:(NSTableView *)tableView byIdentifier:(NSString *)identifier ascending:(BOOL)order;
- (void)tableViewSelectionDidChange:(NSNotification *)notification;
- (void)showReview:(PSReview *)review;

@end
