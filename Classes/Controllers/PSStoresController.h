//
//  PSStoresController.h
//  Prismo
//
//  Created by Sergey Lenkov on 16.03.12.
//  Copyright (c) 2012 Sergey Lenkov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSStore.h"

@interface PSStoresController : NSObject {
    IBOutlet NSTableView *view;
    NSMutableArray *stores;
    NSMutableDictionary *selection;
    NSUserDefaults *defaults;
}

- (void)initialization;
- (void)refresh;

@end
