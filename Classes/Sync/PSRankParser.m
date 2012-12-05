//
//  RankParser.m
//  Prismo
//
//  Created by Sergey Lenkov on 24.05.10.
//  Copyright 2010 Sergey Lenkov. All rights reserved.
//

#import "PSRankParser.h"

@implementation PSRankParser

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
    
    NSDate *lastUpdate = [defaults objectForKey:@"Last Ranks Update"];
    NSNumber *number = [defaults objectForKey:@"Update Ranks Every"];
    
    if ([number intValue] == 0) {
        number = [NSNumber numberWithInt:2];
    }
    
    if ([[NSDate date] timeIntervalSince1970] - [lastUpdate timeIntervalSince1970] > 3600.0 * [number intValue]) {
        [defaults removeObjectForKey:@"Last Ranks Update Key"];
        [defaults synchronize];
    }
    
    [defaults setObject:[NSDate date] forKey:@"Last Ranks Update"];
	[defaults setObject:@"Unknown" forKey:@"Last Ranks Update Status"];
    
    NSDictionary *selectedCategories = [defaults objectForKey:@"Selected Tops"];
    NSMutableArray *categories = [[NSMutableArray alloc] init];
    
    for (PSCategory *category in data.categories) {
         if ([[selectedCategories objectForKey:[NSString stringWithFormat:@"%ld", category.identifier]] boolValue]) {
             [categories addObject:category];
         }
    }
    
    NSDictionary *selectedStores = [defaults objectForKey:@"Selected Stores"];
    NSMutableArray *stores = [[NSMutableArray alloc] init];
    
    for (PSStore *store in data.stores) {
        if ([[selectedStores objectForKey:[NSString stringWithFormat:@"%ld", store.identifier]] boolValue]) {
            [stores addObject:store];
        }
    }
    
    NSString *lastSuccessKey = [defaults objectForKey:@"Last Ranks Update Key"];
    
    NSMutableArray *tops = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < [categories count]; i++) {
        PSCategory *category = [categories objectAtIndex:i];
        
        for (int i = 0; i < [stores count]; i++) {
            PSStore *store = [stores objectAtIndex:i];
            
            NSString *type = @"App Store";
            
            if (category.type == 2 || category.type == 3) {
                type = @"Mac App Store";
            }
            
            PSTop *top = [[PSTop alloc] init];
                
            top.category = category;
            top.store = store;
            top.name = [NSString stringWithFormat:@"%@ - %@ - %@", type, category.name, store.name];
                
            [tops addObject:top];
            [top release];
        }
    }
    
    [categories release];
    [stores release];
    
    [tops sortUsingSelector:@selector(compareName:)];
    
    for (PSTop *top in tops) {
        if (isCanceled) {
            [defaults setObject:@"Canceled" forKey:@"Last Ranks Update Status"];
			break;
		}

        [self changePhaseWithMessage:top.name];

        if ([lastSuccessKey length] > 0 && [top.name compare:lastSuccessKey] == NSOrderedAscending) {
            [self incrementProgressIndicatorBy:1.0];
            continue;
        }
        
        for (int i = 0; i < [data.pops count]; i++) {	
            top.pop = [data.pops objectAtIndex:i];
            
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com/WebObjects/MZStore.woa/wa/viewTop?id=%ld&popId=%ld&genreId=%ld&mt=12", top.category.identifier, top.pop.identifier, top.category.genre]];
            
            ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
        
            request.timeOutSeconds = 60;
            request.shouldRedirect = NO;
        
            if (top.category.type == 0 || top.category.type == 1) {
                [request addRequestHeader:@"User-Agent" value:@"iTunes/11.0 (Macintosh; OS X 10.7.4) AppleWebKit/534.56.5"];
                [request addRequestHeader:@"X-Apple-Store-Front" value:[NSString stringWithFormat:@"%ld,12", top.store.identifier]];
            } else {
                [request addRequestHeader:@"User-Agent" value:@"MacAppStore/1.1.2 (Macintosh; U; Intel Mac OS X 10.7.5; en) AppleWebKit/534.56.5"];
                [request addRequestHeader:@"X-Apple-Store-Front" value:[NSString stringWithFormat:@"%ld,13", top.store.identifier]];
            }
        
            [request addRequestHeader:@"X-Apple-Partner" value:@"origin.0"];
            [request addRequestHeader:@"X-Apple-Connection-Type" value:@"WiFi"];
            
            [request startSynchronous];
        
            NSError *error = [request error];
        
            if (error) {
                isCanceled = YES;
                [GrowlApplicationBridge notifyWithTitle:@"Ranks" description:[error localizedDescription] notificationName:@"New event" iconData:nil priority:0 isSticky:NO clickContext:nil];
                [defaults setObject:[error localizedDescription] forKey:@"Last Ranks Update Status"];
            
                [tops release];
                [pool release];
            
                return;
            }
        
            NSString *response = request.responseString;

            NSArray *items = [response componentsSeparatedByString:@"<div rating-software="];
        
            for (int i = 0; i < [items count]; i++) {
                NSArray *lines = [[items objectAtIndex:i] componentsSeparatedByString:@"\n"];
                NSString *item = @"";
            
                for (NSString *line in lines) {
                    line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    line = [line stringByRemovingNewLinesAndWhitespace];
                
                    if ([line length] > 0) {
                        item = [item stringByAppendingString:line];
                    }
                }
            
                for (PSApplication *application in data.applications) {
                    if ([item isMatchedByRegex:[NSString stringWithFormat:@"adam-id=\"%ld\"", application.identifier]]) {
                        NSString *place = [item stringByMatching:@"<span class=\"index\">.*?([0-9]+).*</span>" capture:1];

                        if (place != nil) {
                            PSRank *rank = [[PSRank alloc] initWithPrimaryKey:-1 database:_db];
                        
                            rank.store = top.store;
                            rank.category = top.category;
                            rank.pop = top.pop;
                            rank.application = application;
                            rank.place = [place intValue];
                            rank.date = [NSDate date];
                        
                            [rank save];
                            [rank release];                                
                        }
                    }
                }
            }
            
            [pool release];
        }
        
        [defaults setObject:top.name forKey:@"Last Ranks Update Key"];
        [defaults synchronize];
        
        [self incrementProgressIndicatorBy:1.0];
    }
    
    [tops release];
    
    [defaults removeObjectForKey:@"Last Ranks Update Key"];
    
    if (!isCanceled) {
        [defaults setObject:@"Ranks checked successfully" forKey:@"Last Ranks Update Status"];
    }
    
    [defaults synchronize];
}

#pragma mark -
#pragma mark Delegate
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
