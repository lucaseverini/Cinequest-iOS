//
//  FestivalParser.m
//  Cinequest
//
//  Created by Hai Nguyen on 11/4/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "CinequestAppDelegate.h"
#import "FestivalParser.h"
#import "DDXML.h"
#import "Show.h"
#import "Showing.h"
#import "Venue.h"

@implementation FestivalParser {
    Show *show;
    Showing *showing;
}

@synthesize shows;

- (id)init {
    shows = [[NSMutableArray alloc] init];
    return self;
}

+ (Festival*) parseFestival:(NSString *) url {
    return nil; // @"need to create Festival class";
}

- (void) parseShows:(NSString *) url {
    @autoreleasepool {
		NSURL *link = [NSURL URLWithString:url];
		NSData *htmldata = [NSData dataWithContentsOfURL:link];
        
        NSString* myString = [[NSString alloc] initWithData:htmldata encoding:NSUTF8StringEncoding];
        myString = [myString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        myString = [myString stringByReplacingOccurrencesOfString:@"\t" withString:@""];
        htmldata = [myString dataUsingEncoding:NSUTF8StringEncoding];
        
		DDXMLDocument *xmlDoc = [[DDXMLDocument alloc] initWithData:htmldata options:0 error:nil];
		DDXMLElement *atsFeed = [xmlDoc rootElement];
        DDXMLElement *arrayOfShows = (DDXMLElement*)[atsFeed childAtIndex:2]; // hard-coding index
        
        for (int i = 0; i < [arrayOfShows childCount]; i++) {
            DDXMLElement *showElement = (DDXMLElement*)[arrayOfShows childAtIndex:i];
            
            show = [[Show alloc] init];
            
            for (int j = 0; j<[showElement childCount]; j++) {
                /* Should I declare showChild outside this block? */
                DDXMLElement *showChild = (DDXMLElement*)[showElement childAtIndex:j];
                if ([[showChild name] isEqualToString:@"ID"]) {
                    show.ID = [showChild stringValue];
                }
                if ([[showChild name] isEqualToString:@"Name"]) {
                    show.name = [showChild stringValue];
                }
                if ([[showChild name] isEqualToString:@"Duration"]) {
                    show.duration = [[showChild stringValue] intValue];
                }
                if ([[showChild name] isEqualToString:@"ShortDescription"]) {
                    show.shortDescription = [showChild stringValue];
                }
                if ([[showChild name] isEqualToString:@"ThumbImage"]) {
                    show.thumbImageURL = [showChild stringValue];
                }
                if ([[showChild name] isEqualToString:@"EventImage"]) {
                    show.eventImageURL = [showChild stringValue];
                }
                if ([[showChild name] isEqualToString:@"InfoLink"]) {
                    show.infoLink = [showChild stringValue];
                }
                if ([[showChild name] isEqualToString:@"CustomProperties"]) {
                    // showChild here is an array of CustomerProperty
                    /* Not sure if this is a safe approach */
                    for (int k = 0; k < [showChild childCount]; k++) {
                        DDXMLElement *customProperty = (DDXMLElement*)[showChild childAtIndex:k];
                        if ([[[customProperty childAtIndex:0] name] isEqualToString:@"Name"]) {
                            NSString *customPropertyName = [[customProperty childAtIndex:0] stringValue];
                            NSMutableArray *values = [show.customProperties objectForKey:customPropertyName];
                            if (values == nil) {
                                values = [NSMutableArray array];
                                [show.customProperties setObject:values forKey:customPropertyName];
                            }
                            
                            if ([[[customProperty childAtIndex:4] name] isEqualToString:@"Value"]) {
                                NSString *customPropertyValue = [[customProperty childAtIndex:4] stringValue];
                                [values addObject:customPropertyValue];
                            }
                        }
                    }

                }
                if ([[showChild name] isEqualToString:@"CurrentShowings"]) {
                    // showChild here is an array of Showing
                    for (int k = 0; k < [showChild childCount]; k++) {
                        DDXMLElement *showingElement = (DDXMLElement*)[showChild childAtIndex:k];
                        showing = [[Showing alloc] init];
                        
                        for (int l = 0; l < [showingElement childCount]; l++) {
                            DDXMLElement *showingChild = (DDXMLElement*)[showingElement childAtIndex:l];
                            
                            if ([[showingChild name] isEqualToString:@"ID"]) {
                                showing.ID = [showingChild stringValue];
                            }
                            if ([[showingChild name] isEqualToString:@"StartDate"]) {
                                showing.startDate = [showingChild stringValue];
                            }
                            if ([[showingChild name] isEqualToString:@"EndDate"]) {
                                showing.endDate = [showingChild stringValue];
                            }
                            if ([[showingChild name] isEqualToString:@"ShortDescription"]) {
                                showing.shortDescription = [showingChild stringValue];
                            }
                            if ([[showingChild name] isEqualToString:@"Venue"]) {
                                for (int m = 0; m < [showingChild childCount]; m++) {
                                    DDXMLElement *venueChild = (DDXMLElement*)[showingChild childAtIndex:m];
                                    if ([[venueChild name] isEqualToString:@"VenueID"]) {
                                        showing.venue.ID = [venueChild stringValue];
                                    }
                                    if ([[venueChild name] isEqualToString:@"VenueName"]) {
                                        showing.venue.name = [venueChild stringValue];
                                    }
                                    if ([[venueChild name] isEqualToString:@"VenueAddress1"]) {
                                        showing.venue.address = [venueChild stringValue];
                                    }
                                }
                            }
                        }
                        
                        [show.currentShowings addObject:showing];
                        showing = nil;
                    }
                }
                
            }
            [self.shows addObject:show];
            show = nil;
        }
        
    }
}

- (NSMutableArray *)getShows {
    return shows;
}


@end
