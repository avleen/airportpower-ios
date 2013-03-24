//
//  KVStore.h
//  Airport Power
//
//  Created by Avleen Vig on 3/22/13.
//  Copyright (c) 2013 WraithNet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface KVStore : NSManagedObject

@property (nonatomic, retain) NSNumber *welcomeSeen;
@property (nonatomic, retain) NSString *lastCameraPosition;

@end
