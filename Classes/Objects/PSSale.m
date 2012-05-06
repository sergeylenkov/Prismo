//
//  PSSale.m
//  Prismo
//
//  Created by Sergey Lenkov on 30.05.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import "PSSale.h"

@implementation PSSale

@synthesize total;
@synthesize downloads;
@synthesize sales;
@synthesize updates;
@synthesize refunds;
@synthesize revenue;
@synthesize date;
@synthesize description;
@synthesize details;
@synthesize isDetail;

- (void)dealloc {
    [total release];
	[downloads release];
	[sales release];		
	[updates release];
	[refunds release];
	[revenue release];
	[date release];
	[description release];
	[details release];
	[super dealloc];
}

- (id)init {
    self = [super init];

    if (self) {
        self.total = [NSNumber numberWithInt:0];
        self.downloads = [NSNumber numberWithInt:0];
        self.sales = [NSNumber numberWithInt:0];
        self.updates = [NSNumber numberWithInt:0];
        self.refunds = [NSNumber numberWithInt:0];
        self.revenue = [NSNumber numberWithInt:0];
        self.description = @"";
        self.isDetail = NO;
    }
    
    return self;
}

- (NSComparisonResult)compareTotal:(PSSale *)sale {
	if ([total intValue] < [sale.total intValue]) {
		return NSOrderedAscending;
	} else if ([total intValue] > [sale.total intValue]) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

- (NSComparisonResult)compareDownloads:(PSSale *)sale {
	if ([downloads intValue] < [sale.downloads intValue]) {
		return NSOrderedAscending;
	} else if ([downloads intValue] > [sale.downloads intValue]) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

- (NSComparisonResult)compareSales:(PSSale *)sale {
	if ([sales intValue] < [sale.sales intValue]) {
		return NSOrderedAscending;
	} else if ([sales intValue] > [sale.sales intValue]) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

- (NSComparisonResult)compareUpdates:(PSSale *)sale {
	if ([updates intValue] < [sale.updates intValue]) {
		return NSOrderedAscending;
	} else if ([updates intValue] > [sale.updates intValue]) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

- (NSComparisonResult)compareRefunds:(PSSale *)sale {
	if ([refunds intValue] < [sale.refunds intValue]) {
		return NSOrderedAscending;
	} else if ([refunds intValue] > [sale.refunds intValue]) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

- (NSComparisonResult)compareRevenue:(PSSale *)sale {
	if ([revenue floatValue] < [sale.revenue floatValue]) {
		return NSOrderedAscending;
	} else if ([revenue floatValue] > [sale.revenue floatValue]) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

- (NSComparisonResult)compareDate:(PSSale *)sale {
	if ([date timeIntervalSince1970] < [sale.date timeIntervalSince1970]) {
		return NSOrderedAscending;
	} else if ([date timeIntervalSince1970] > [sale.date timeIntervalSince1970]) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

- (NSComparisonResult)compareDescription:(PSSale *)sale {
    return [description compare:sale.description];
}

@end
