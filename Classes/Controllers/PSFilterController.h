//
//  PSFilterController.h
//  Prismo
//
//  Created by Sergey Lenkov on 29.10.11.
//  Copyright (c) 2011 Sergey Lenkov. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum __PSGraphGroupBy {
    PSGraphGroupByDay = 0,
    PSGraphGroupByWeek = 1,
    PSGraphGroupByMonth = 2
} PSGraphGroupBy;

typedef enum __PSGraphType {
    PSGraphTypeTotal = 0,
    PSGraphTypeDownloads = 1,
    PSGraphTypeSales = 2,
    PSGraphTypeUpdates = 3,
    PSGraphTypeRevenue = 4,
    PSGraphTypeRefunds = 5
} PSGraphType;

@class PSFilterController;

@protocol PSFilterControllerDelegate <NSObject>

- (void)filterDidChanged:(PSFilterController *)controller;

@end
                            
@interface PSFilterController : NSWindowController {
    id <PSFilterControllerDelegate> delegate;
}

@property (nonatomic, assign) id <PSFilterControllerDelegate> delegate;

- (void)initialization;
- (void)filterDidChanged;

@end
