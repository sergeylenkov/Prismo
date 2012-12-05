//
//  PSReviewsAndRatingsController.m
//  Prismo
//
//  Created by Sergey Lenkov on 01.10.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSReviewsAndRatingsController.h"

@implementation PSReviewsAndRatingsController

@synthesize application;

- (void)dealloc {
	[application release];
	[formatter release];
	[reviewsController release];
    [ratingsController release];
	[super dealloc];
}

- (void)awakeFromNib {
	formatter = [[NSNumberFormatter alloc] init];
	
	[formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[formatter setNumberStyle:NSNumberFormatterDecimalStyle];
}

- (void)initialization {
	if ([defaults objectForKey:[NSString stringWithFormat:@"%ld Ratings View Index", application.identifier]] == nil) {
		[changeViewButton setSelectedSegment:0];
	} else {
		int index = [[defaults objectForKey:[NSString stringWithFormat:@"%ld Ratings View Index", application.identifier]] intValue];
		[changeViewButton setSelectedSegment:index];
	}
			
	[self viewChanged:self];	
}

- (void)refresh {
    PSData *data = [PSData sharedData];

    reviewsController.reviews = [data reviewsForApplication:application];
	ratingsController.ratings = [data ratingsForApplication:application];
}

- (BOOL)isCanPrint {
    return YES;
}

- (BOOL)isCanExport {
    return YES;
}

- (void)exportToFile:(NSURL *)fileName {
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init]  autorelease];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	
    NSString *csv = @"";
    
    if ([changeViewButton selectedSegment] == 0) {
        csv = @"\"DATE\",\"STARS\",\"STORE\",\"NICK\",\"TITLE\",\"REVIEW\"\n";
	
        for (PSReview *review in reviewsController.reviews) {
            NSString *text = [review.text stringByReplacingOccurrencesOfString:@"\"" withString:@"'"];
            NSString *line = [NSString stringWithFormat:@"\"%@\",\"%ld\",\"%@\",\"%@\",\"%@\",\"%@\"\n", [dateFormatter stringFromDate:review.date], review.rating, review.store.name, review.name, review.title, text];
            csv = [csv stringByAppendingString:line];
        }
    } else {
        csv = @"\"STORE\",\"AVERAGE\",\"5 STARS\",\"4 STARS\",\"3 STARS\",\"2 STARS\",\"1 STAR\"\n";
	
        for (PSRating *rating in ratingsController.ratings) {
            NSString *line = [NSString stringWithFormat:@"\"%@\",\"%.2f\",\"%ld\",\"%ld\",\"%ld\",\"%ld\",\"%ld\"\n", rating.store.name, [rating.average floatValue], rating.stars5, rating.stars4, rating.stars3, rating.stars2, rating.stars1];
            csv = [csv stringByAppendingString:line];
        }
    }
    
	[csv writeToURL:fileName atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

#pragma mark -
#pragma mark IBAction
#pragma mark -

- (IBAction)viewChanged:(id)sender {
    [reviewsView removeFromSuperview];
	[ratingsView removeFromSuperview];	
	
	if ([changeViewButton selectedSegment] == 0) {
		[reviewsView setFrame:[contentView bounds]];
		[contentView addSubview:reviewsView];
        
        printableView = reviewsController.printableView;
	}
	
	if ([changeViewButton selectedSegment] == 1) {
		[ratingsView setFrame:[contentView bounds]];
		[contentView addSubview:ratingsView];
        
        printableView = ratingsController.view;
	}	
	
	[defaults setObject:[NSNumber numberWithInt:[changeViewButton selectedSegment]] forKey:[NSString stringWithFormat:@"%ld Ratings View Index", application.identifier]];
}

@end
