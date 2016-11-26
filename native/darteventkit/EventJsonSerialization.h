//
//  EventJsonSerialization.h
//  darteventkit
//
//  Created by gerald on 25.11.16.
//  Copyright © 2016 Gerald Leeb. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EventJsonSerialization : NSObject
+ (NSString*) eventsAsJsonForCalendarNamed: (NSString*) calendarName;
@end
