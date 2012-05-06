//
//  OutlineItem.h
//  Prismo
//
//  Created by Sergey Lenkov on 04.06.11.
//  Copyright 2011 Sergey Lenkov. All rights reserved.
//

#import <Foundation/Foundation.h>

enum PSOutlineItemType {
    PSOutlineItemTypeGroup = 0,
    PSOutlineItemTypeReport = 1,
    PSOutlineItemTypeApp = 2,
    PSOutlineItemTypeReviews = 3,
    PSOutlineItemTypeRanks = 4
};

@interface PSOutlineItem : NSObject {
    NSString *name;
    enum PSOutlineItemType type;
    id object;
}

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) enum PSOutlineItemType type;
@property (nonatomic, retain) id object;

@end
