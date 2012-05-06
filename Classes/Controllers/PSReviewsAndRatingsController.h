//
//  PSReviewsAndRatingsController.h
//  Prismo
//
//  Created by Sergey Lenkov on 01.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PSApplication.h"
#import "PSDataController.h"
#import "PSReviewsController.h"
#import "PSRatingsController.h"

@interface PSReviewsAndRatingsController : PSDataController {
	IBOutlet NSView *ratingsView;
	IBOutlet NSView *reviewsView;
	IBOutlet NSView *contentView;
	IBOutlet NSSegmentedControl *changeViewButton;
	IBOutlet PSReviewsController *reviewsController;
	IBOutlet PSRatingsController *ratingsController;
	PSApplication *application;
	NSNumberFormatter *formatter;
}

@property (nonatomic, retain) PSApplication *application;

- (IBAction)viewChanged:(id)sender;

@end
