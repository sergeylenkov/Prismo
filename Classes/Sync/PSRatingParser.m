//
//  RatingParser.m
//  Prismo
//
//  Created by Sergey Lenkov on 09.04.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSRatingParser.h"

@implementation PSRatingParser

@synthesize isCanceled;
@synthesize delegate;

- (id)initWithDatabase:(sqlite3 *)db {
    self = [super init];
    
	if (self) {
		_db = db;
	}
	
	return self;
}

- (void)parse {
    PSData *data = [PSData sharedData];
	
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:[NSDate date] forKey:@"Last Ratings Update"];
	[defaults setObject:@"Unknown" forKey:@"Last Ratings Update Status"];
    
	NSMutableArray *ratings = [[NSMutableArray alloc] init];

    NSDictionary *selectedApps = [defaults objectForKey:@"Selected Apps"];
    NSMutableArray *applications = [[NSMutableArray alloc] init];
    
    for (PSApplication *application in data.applications) {
        if ([[selectedApps objectForKey:[NSString stringWithFormat:@"%d", application.identifier]] boolValue]) {
            [applications addObject:application];
        }
    }
    
	for (int i = 0; i < [applications count]; i++) {
		if (isCanceled) {
            [defaults setObject:@"Canceled" forKey:@"Last Ratings Update Status"];
			break;
		}
		
		PSApplication *application = [applications objectAtIndex:i];
        
        [ratings removeAllObjects];
        
		for (int i = 0; i < [data.stores count]; i++) {
			if (isCanceled) {
                [defaults setObject:@"Canceled" forKey:@"Last Ratings Update Status"];
				break;
			}
            
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			PSStore *store = [data.stores objectAtIndex:i];
			
			[self changePhaseWithMessage:[NSString stringWithFormat:@"%@ - %@", application.name, store.name]];
            
            NSString *url = [NSString stringWithFormat:@"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=%d&pageNumber=0&sortOrdering=2&type=Purple+Software", application.identifier];
            ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
            
            request.timeOutSeconds = 60;
            request.shouldRedirect = NO;
            
            [request addRequestHeader:@"User-Agent" value:@"iTunes/10.1.1 (Macintosh; Intel Mac OS X 10.6.6) AppleWebKit/533.19.4"];
            [request addRequestHeader:@"X-Apple-Store-Front" value:[NSString stringWithFormat:@"%d,12", store.identifier]];
            [request addRequestHeader:@"X-Apple-Partner" value:@"origin.0"];
            [request addRequestHeader:@"X-Apple-Connection-Type" value:@"WiFi"];
            
            [request startSynchronous];
            
            NSError *error = [request error];
            
            if (error) {
                isCanceled = YES;
                [GrowlApplicationBridge notifyWithTitle:@"Ratings" description:[error localizedDescription] notificationName:@"New event" iconData:nil priority:0 isSticky:NO clickContext:nil];
                
                [defaults setObject:[error localizedDescription] forKey:@"Last Ratings Update Status"];
                
				[pool release];
				
				return;
			}
            
            NSString *response = [[NSString alloc] initWithData:[request responseData] encoding:NSUTF8StringEncoding];

            @try {                          
                int stars5 = 0;
                int stars4 = 0;
                int stars3 = 0;
                int stars2 = 0;
                int stars1 = 0;
            
                NSArray *components = [response arrayOfCaptureComponentsMatchedByRegex:@"alt=\"([0-9]+).+, ([0-9]+).+\""];
                
                for (NSArray *component in components) {
                    if ([[component objectAtIndex:1] intValue] == 5) {
                        stars5 = [[component objectAtIndex:2] intValue];
                    }
                    
                    if ([[component objectAtIndex:1] intValue] == 4) {
                        stars4 = [[component objectAtIndex:2] intValue];
                    }
                    
                    if ([[component objectAtIndex:1] intValue] == 3) {
                        stars3 = [[component objectAtIndex:2] intValue];
                    }
                    
                    if ([[component objectAtIndex:1] intValue] == 2) {
                        stars2 = [[component objectAtIndex:2] intValue];
                    }
                    
                    if ([[component objectAtIndex:1] intValue] == 1) {
                        stars1 = [[component objectAtIndex:2] intValue];
                    }
                }
                                
                if (stars5 > 0 || stars4 > 0 || stars3 > 0 || stars2 > 0 || stars1 > 0) {
                    PSRating *rating = [[PSRating alloc] initWithPrimaryKey:-1 database:_db];
                    
                    rating.stars5 = stars5;
                    rating.stars4 = stars4;
                    rating.stars3 = stars3;
                    rating.stars2 = stars2;
                    rating.stars1 = stars1;
                    
                    float average = ((5.0 * stars5) + (4.0 * stars4) + (3.0 * stars3) + (2.0 * stars2) + (1.0 * stars1)) / (stars5 + stars4 + stars3 + stars2 + stars1);
                    rating.average = [NSNumber numberWithFloat:average];

                    rating.store = store;
                    rating.application = application;
                    rating.date = [NSDate date];
                
                    [ratings addObject:rating];
                    [rating release];
                }
            }
            @catch (NSException *exception) {
                //
            }
            @finally {
                //
            }
                        
			[self incrementProgressIndicatorBy:1.0];			
			[pool release];
		}
        
        [self importRatings:ratings];
	}
	
    [ratings release];
    [applications release];
    
    if (!isCanceled) {
        [defaults setObject:@"Ratings updated successfully" forKey:@"Last Ratings Update Status"];
    }
    
    [defaults synchronize];
}

- (void)importRatings:(NSArray *)ratings {
	if (ratings == nil || [ratings count] == 0) {
		return;
	}
	
	PSRating *rating = [ratings lastObject];
    [rating deleteRatingsForApplication];	
	
	for (PSRating *rating in ratings) {
		[rating save];
	}
}


#pragma mark -
#pragma mark Delegate Protocol
#pragma mark -

- (void)startProgressAnimationWithTitle:(NSString *)title maxValue:(NSInteger)max indeterminate:(BOOL)indeterminate {
	if (delegate) {
		[delegate startProgressAnimationWithTitle:title maxValue:max indeterminate:indeterminate];
	}
}

- (void)stopProgressAnimation {
	if (delegate) {
		[delegate stopProgressAnimation];
	}
}

- (void)incrementProgressIndicatorBy:(double)value {
	if (delegate) {
		[delegate incrementProgressIndicatorBy:value];
	}
}

- (void)changePhaseWithMessage:(NSString *)message {
	if (delegate) {
		[delegate changePhaseWithMessage:message];
	}
}

@end
