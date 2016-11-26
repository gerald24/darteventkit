//
//  EventJsonSerialization.m
//  darteventkit
//
//  Created by gerald on 25.11.16.
//  Copyright © 2016 Gerald Leeb. All rights reserved.
//

#import "EventJsonSerialization.h"
#import <EventKit/EventKit.h>

@implementation EventJsonSerialization
// private
+ (void) addIfNotNil: (NSMutableDictionary*) dictionary value: (id) value forKey: (NSString*) key {
    if (value == nil || [value isEqualToString: @""]) {
        return;
    }
    [dictionary setObject: value forKey: key];
}

// private
+ (NSDictionary*) dictionaryForEvent: (EKEvent*) event usingDateFormatter: (NSDateFormatter*)dateFormatter {
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
    
    [dictionary setObject: [dateFormatter stringFromDate: event.startDate]  forKey: @"startDate"];
    [dictionary setObject: [dateFormatter stringFromDate: event.endDate]  forKey: @"endDate"];
    [self addIfNotNil: dictionary value:event.title forKey:@"title"];
    [self addIfNotNil: dictionary value:event.location forKey:@"location"];
    [self addIfNotNil: dictionary value:event.notes forKey:@"notes"];
    [dictionary setObject: [NSString stringWithFormat:@"%lf", [event.endDate timeIntervalSinceDate: event.startDate] / 60] forKey: @"duration"];
    
    return dictionary;
}

+ (NSString*) eventsAsJsonForCalendarNamed: (NSString*) calendarName {
    EKEventStore* eventStore = [[EKEventStore alloc] init];
    
    if ([EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent] != EKAuthorizationStatusAuthorized) {
        EKEventStoreRequestAccessCompletionHandler result;
        [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:result];
        return nil;
    }
    
    EKCalendar* calendar = [eventStore defaultCalendarForNewEvents];
    for (EKCalendar* cal in [eventStore calendarsForEntityType: EKEntityTypeEvent]) {
        if ([cal.title isEqual: calendarName])
            calendar = cal;
    }
    if (calendar  == nil) {
        return @"{error: 'calendar not found'}";
    }
    
    NSCalendar* gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    
// currently recent 2 years - may pass from-to as parameter someday
    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSDateComponents* dateComponents = [gregorian components: unitFlags fromDate: [NSDate date]];
    [dateComponents setDay: 31];
    [dateComponents setHour: 23];
    [dateComponents setMinute: 59];
    [dateComponents setSecond: 59];
    NSDate* endDate = [gregorian dateFromComponents: dateComponents];
    
    [dateComponents setYear: (dateComponents.year - 2)];
    [dateComponents setDay: 1];
    [dateComponents setHour: 0];
    [dateComponents setMinute: 0];
    [dateComponents setSecond: 0];
    NSDate* startDate = [gregorian dateFromComponents: dateComponents];
    
    NSPredicate* predicate = [eventStore predicateForEventsWithStartDate: startDate
                                                                 endDate: endDate
                                                               calendars: [NSArray arrayWithObject: calendar]];

    NSArray* unsortedEvents = [eventStore eventsMatchingPredicate: predicate];
    
    NSMutableArray* sortedEvents = [unsortedEvents mutableCopy];
    NSSortDescriptor* desc = [[NSSortDescriptor alloc] initWithKey: @"startDate" ascending: NO];
    [sortedEvents sortUsingDescriptors: [NSArray arrayWithObject: desc]];
    
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    [df setCalendar: gregorian];
    [df setDateFormat:@"yyyy-MM-dd HH:mm"];
    
    NSMutableArray* events = [NSMutableArray array];
    for (EKEvent* ekEvent in sortedEvents) {
        [events addObject: [self dictionaryForEvent: ekEvent usingDateFormatter: df]];
    }
    
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:events options:0 error:nil];
    return  [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end
