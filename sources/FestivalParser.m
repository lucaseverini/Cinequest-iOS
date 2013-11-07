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
#import "Film.h"
#import "Festival.h"
#import "ProgramItem.h"
#import "NewSchedule.h"
#import "VenueLocation.h"

@implementation FestivalParser

@synthesize shows;

- (id)init {
    shows = [[NSMutableArray alloc] init];
    return self;
}

- (Festival*) parseFestival:(NSString *) url
{	
    [self parseShows:url];
    Festival *festival = [[Festival alloc] init];
    NSMutableDictionary *shortFilms = [[NSMutableDictionary alloc] init];

    NSMutableSet *uniqueVenues = [[NSMutableSet alloc] init];
        
    // Remove the partial shows from shows
    // Add them to partialShows, grouped by their title
    
    NSMutableArray *discardedShows = [[NSMutableArray alloc] init];
    for (Show *show in shows) {
        if ([show.currentShowings count] == 0) {
            [discardedShows addObject:show];
            Film *film = [self getFilm:show];
            [shortFilms setObject:film forKey:show.ID];
            [festival.films addObject:film];
        }
    }
    
    [shows removeObjectsInArray:discardedShows];
    
    for (Show *show in shows) {
        ProgramItem *item = [self getProgramItem:show];
        [festival.programItems addObject:item];
        NSMutableArray *typeOfFilm = [show.customProperties objectForKey:@"Type of Film"];
        if (typeOfFilm == nil || ![typeOfFilm containsObject:@"Shorts Program"]) {
            Film *film = [self getFilm:show];
            [item.films addObject:film];
            [festival.films addObject:film];
        }
        
        NSMutableArray *shortIDs = [show.customProperties objectForKey:@"ShortID"];
        if (shortIDs != nil) {
            for (NSString *ID in shortIDs) {
                Film *shortFilm = [shortFilms objectForKey:ID];
                [item.films addObject:shortFilm];
            }
        }
        
        for (Showing *showing in show.currentShowings) {
            NewSchedule *schedule = [self getSchedule:showing forItem:item];
            [festival.schedules addObject:schedule];
            if (![uniqueVenues containsObject:schedule.venue]) {
                [uniqueVenues addObject:schedule.venue];
                [festival.venueLocations addObject:[self getVenueLocation:showing.venue]];
            }
            for (Film *film in item.films) {
                [film.schedules addObject:schedule];
            }
        }
        
        
    }
    return festival;
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
            
            Show *show = [[Show alloc] init];
            
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
                        Showing *showing = [[Showing alloc] init];
                        
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
                    }
                }
                
            }
            [self.shows addObject:show];
        }
        
    }
} // end parseShow

- (NSMutableArray *)getShows {
    return shows;
}

- (VenueLocation *) getVenueLocation:(Venue *)venue
{
    VenueLocation *loc = [[VenueLocation alloc] init];
    loc.ID = venue.ID;
    loc.venueAbbreviation = [self venueAbbr:(venue.name)];
    loc.name = venue.name;
    loc.location = venue.address;
    return loc;
}

- (NewSchedule *) getSchedule:(Showing *) showing forItem:(ProgramItem *)item
{
    NewSchedule *schedule = [[NewSchedule alloc] init];
    schedule.ID = showing.ID;
    schedule.itemID = item.ID;
    schedule.title = item.name;
    schedule.startTime = showing.startDate;
    schedule.endTime = showing.endDate;
    schedule.venue = [self venueAbbr:showing.venue.name];
    return schedule;
}

- (NSString *) venueAbbr:(NSString *)name
{
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^A-Z0-9]" options:0 error:&error];
    
    NSString *modifiedString = [regex stringByReplacingMatchesInString:name options:0 range:NSMakeRange(0, [name length]) withTemplate:@""];
    return modifiedString;
}

- (ProgramItem *) getProgramItem:(Show *)show
{
    ProgramItem *item = [[ProgramItem alloc] init];
    item.ID = show.ID;
    item.name = show.name;
    item.description = show.shortDescription;
    return item;
}

- (Film *) getFilm:(Show *) show
{
    Film *film = [[Film alloc] init];
    /* TODO: tagline and filmInfo seem unused
     * TODO: What should we do with the executive producers?
     */
    film.ID = show.ID;
    film.name = show.name;
    film.description = show.shortDescription;
    film.imageURL = show.thumbImageURL;
    film.director = [self get:show.customProperties forkey:@"Director"];
    film.producer = [self get:show.customProperties forkey:@"Producer"];
    film.cinematographer = [self get:show.customProperties forkey:@"Cinematographer"];
    film.editor  =  [self get:show.customProperties forkey:@"Editor"];
    film.cast = [self get:show.customProperties forkey:@"Cast"];
    film.country = [self get:show.customProperties forkey:@"Production Country"];
    film.language = [self get:show.customProperties forkey:@"Language"];
    film.genre = [self get:show.customProperties forkey:@"Genre"];
    return film;
}

- (NSString *) get:(NSMutableDictionary *)custom forkey:(NSString*) key
{
    NSMutableArray *value = [custom objectForKey:key];
    if (value == nil) return @"";
    if ([value count] == 1) return [value objectAtIndex:0];
    NSMutableString * result = [[NSMutableString alloc] init];
    for (int i = 0; i < [value count]; i++) {
        [result appendString:[value objectAtIndex:i]];
        if (i == [value count] - 1) {
            break;
        }
        [result appendString:@", "];
    }
    return result;
}

@end
