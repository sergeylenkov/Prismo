//
//  PSAppsController.h
//  Prismo
//
//  Created by Sergey Lenkov on 11.02.12.
//  Copyright (c) 2012 Sergey Lenkov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSApplication.h"

@interface PSAppsController : NSObject {
    IBOutlet NSTableView *view;
    NSMutableArray *apps;
    NSMutableDictionary *selection;
    NSUserDefaults *defaults;
}

- (void)initialization;
- (void)refresh;

@end
