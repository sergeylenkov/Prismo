//
//  PSTopsController.h
//  Prismo
//
//  Created by Sergey Lenkov on 08.02.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSCategory.h"

@interface PSTopsController : NSObject {
    IBOutlet NSTableView *view;
    NSMutableArray *tops;
    NSMutableDictionary *selection;
    NSUserDefaults *defaults;
}

- (void)initialization;
- (void)refresh;

@end
