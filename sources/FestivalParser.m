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
#import "Schedule.h"
#import "VenueLocation.h"
#import "DataProvider.h"
#import "Forum.h"
#import "Special.h"

@implementation FestivalParser

@synthesize shows;

- (id) init
{
 	self = [super init];
	if(self != nil)
	{
		shows = [[NSMutableArray alloc] init];
	}
	
    return self;
}

/* - (Festival*) parseFestival
{	
    [self parseShows];
	
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
        
        // Shows that include only Short Films are not included in festival.films
        // festival.films contains only feature films and short films
        // 
        
        NSMutableArray *shortIDs = [show.customProperties objectForKey:@"ShortID"];
        if (shortIDs != nil) {
            for (NSString *ID in shortIDs) {
                Film *shortFilm = [shortFilms objectForKey:ID];
                [item.films addObject:shortFilm];
            }
        }
        
        for (Showing *showing in show.currentShowings) {
            Schedule *schedule = [self getSchedule:showing forItem:item];
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
	
	appDelegate.festivalParsed = YES;
	
    return festival;
}
*/

- (Festival*) parseFestival
{
    [self parseShows];
	
    Festival *festival = [[Festival alloc] init];
    NSMutableDictionary *shorts = [[NSMutableDictionary alloc] init];
    
    NSMutableSet *uniqueVenues = [[NSMutableSet alloc] init];
    
    // Remove the partial shows from shows
    // Add them to partialShows, grouped by their title
    
    // errorString: for logging error
    NSMutableString *errorString = [[NSMutableString alloc] init];
    
    NSMutableArray *discardedShows = [[NSMutableArray alloc] init];
    for (Show *show in shows) {
        if ([show.currentShowings count] == 0) {
            [discardedShows addObject:show];
            
            NSMutableArray *eventType = [show.customProperties objectForKey:@"EventType"];
            if (eventType == nil) {
                [errorString appendFormat:@"Show with ID: %@ has no EventType\n", show.ID];
                // consider a Show with no EventType a Film now
                // but skip when the xml feed is fixed
                Film *film = [self getFilmFrom:show];
                [shorts setObject:film forKey:show.ID];
                [self addItem:film to:festival.sortedFilms];
            } else if ([eventType count] > 1) {
                // skipping Show that has more than 1 EventType
                continue;
            } else if ([eventType containsObject:@"Film"]) {
                Film *film = [self getFilmFrom:show];
                [shorts setObject:film forKey:show.ID];
                [self addItem:film to:festival.sortedFilms];
            } else if ([eventType containsObject:@"Forum"]) {
                Forum *forum = [self getForumFrom:show];
                [shorts setObject:forum forKey:show.ID];
            } else if ([eventType containsObject:@"Special"]) {
                Special *special = [self getSpecialFrom:show];
                [shorts setObject:special forKey:show.ID];
            }
        }
    }
    
    [shows removeObjectsInArray:discardedShows];
    
    for (Show *show in shows) {
        
        CinequestItem *item;
        
        NSMutableArray *eventType = [show.customProperties objectForKey:@"EventType"];
        if (eventType == nil) {
            [errorString appendFormat:@"Show with ID: %@ has no EventType\n", show.ID];
            // consider a Show with no EventType a Film now
            // but skip when the xml feed is fixed
            item = [self getFilmFrom:show];
            [self addItem:item to:festival.sortedFilms];
        } else if ([eventType count] > 1) {
            // skipping Show that has more than 1 EventType
            continue;
        } else if ([eventType containsObject:@"Film"]) {
            item = [self getFilmFrom:show];
            [self addItem:item to:festival.sortedFilms];
        } else if ([eventType containsObject:@"Forum"]) {
            item = [self getForumFrom:show];
        } else if ([eventType containsObject:@"Special"]) {
            item = [self getSpecialFrom:show];
        }
        
        NSMutableArray *shortIDs = [show.customProperties objectForKey:@"ShortID"];
        if (shortIDs != nil) {
            for (NSString *ID in shortIDs) {
                CinequestItem *subItem = [shorts objectForKey:ID];
                [item.shortItems addObject:subItem];
            }
        }
        
        for (Showing *showing in show.currentShowings) {
            Schedule *schedule = [self getScheduleFrom:showing forItem:item];
            [item.schedules addObject:schedule];
            
            [self addItemToDictionary:item with:schedule in:festival];
            
            if (![uniqueVenues containsObject:schedule.venue]) {
                [uniqueVenues addObject:schedule.venue];
                [festival.venueLocations addObject:[self getVenueLocation:showing.venue]];
            }
            
            for (CinequestItem *cinequestItem in item.shortItems) {
                [cinequestItem.schedules addObject:schedule];
            }
        }
        
    }
    
    for (CinequestItem *shortItem in [shorts allValues]) {
        for (Schedule *shortItemSchedule in shortItem.schedules) {
            [self addItemToDictionary:shortItem with:shortItemSchedule in:festival];
        }
    }
    
	appDelegate.festivalParsed = YES;
	
    return festival;
}


- (void) addItem:(CinequestItem *)item to:(NSMutableDictionary *)alphabetDictionary {
    NSString *itemName = [item name];
    itemName = [itemName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([itemName length] > 0) {
        NSString *firstLetter = [itemName substringToIndex:1];
        firstLetter = [firstLetter uppercaseString];
        NSMutableArray *values = [alphabetDictionary objectForKey:firstLetter];
        if (values == nil) {
            values = [NSMutableArray array];
            [values addObject:item];
            [alphabetDictionary setObject:values forKey:firstLetter];
            return;
        } else {
            [values addObject:item];
        }
    }
}

- (void) addItemToDictionary:(CinequestItem *)item with:(Schedule *)schedule in:(Festival*)festival{
    NSString *date = [schedule longDateString];
    NSMutableArray *values;
    if ([date length] > 0) {
        if ([item isKindOfClass:[Film class]]) {
            values = [festival.sortedSchedules objectForKey:date];
            if (values == nil) {
                values = [NSMutableArray array];
                [values addObject:item];
                [festival.sortedSchedules setObject:values forKey:date];
                return;
            } else {
                [values addObject:item];
            }
        } else if ([item isKindOfClass:[Forum class]]) {
            values = [festival.sortedForums objectForKey:date];
            if (values == nil) {
                values = [NSMutableArray array];
                [values addObject:item];
                [festival.sortedForums setObject:values forKey:date];
                return;
            } else {
                [values addObject:item];
            }
        } else if ([item isKindOfClass:[Special class]]) {
            values = [festival.sortedSpecials objectForKey:date];
            if (values == nil) {
                values = [NSMutableArray array];
                [values addObject:item];
                [festival.sortedSpecials setObject:values forKey:date];
                return;
            } else {
                [values addObject:item];
            }
        }
    }
}

- (NSMutableArray *)getShows
{
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

- (Schedule *) getScheduleFrom:(Showing *) showing forItem:(CinequestItem *)item
{
    Schedule *schedule = [[Schedule alloc] init];
    schedule.ID = showing.ID;
    schedule.itemID = item.ID;
    schedule.title = item.name;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    NSDate *date = [dateFormatter dateFromString:showing.startDate];
    schedule.startDate = date;
    
    [dateFormatter setDateFormat:@"h:mm a"];
    schedule.startTime = [dateFormatter stringFromDate:date];
    
    [dateFormatter setDateFormat:@"EEE, MMM d"];
    schedule.dateString = [dateFormatter stringFromDate:date];
    
    [dateFormatter setDateFormat:@"EEEE, MMMM d"];
    schedule.longDateString = [dateFormatter stringFromDate:date];
    
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    date = [dateFormatter dateFromString:showing.endDate];
    schedule.endDate = date;
    
    [dateFormatter setDateFormat:@"h:mm a"];
    schedule.endTime = [dateFormatter stringFromDate:date];
    
    schedule.venue = [self venueAbbr:showing.venue.name];
    
    schedule.venueItem = [showing venue];
    
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

- (Film *)getFilmFrom:(Show *)show
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
                                 
- (Forum *)getForumFrom:(Show *)show
{
    Forum *forum = [[Forum alloc] init];
    return forum;
}

- (Special *)getSpecialFrom:(Show *)show
{
    Special *special = [[Special alloc] init];
    return special;
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

- (void) parseShows
{
	NSData *htmldata = [[appDelegate dataProvider] mainFeed];
	
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
			else if ([[showChild name] isEqualToString:@"Name"]) {
				show.name = [showChild stringValue];
			}
			else if ([[showChild name] isEqualToString:@"Duration"]) {
				show.duration = [[showChild stringValue] intValue];
			}
			else if ([[showChild name] isEqualToString:@"ShortDescription"]) {
				show.shortDescription = [showChild stringValue];
			}
			else if ([[showChild name] isEqualToString:@"ThumbImage"]) {
				show.thumbImageURL = [showChild stringValue];
			}
			else if ([[showChild name] isEqualToString:@"EventImage"]) {
				show.eventImageURL = [showChild stringValue];
			}
			else if ([[showChild name] isEqualToString:@"InfoLink"]) {
				show.infoLink = [showChild stringValue];
			}
			else if ([[showChild name] isEqualToString:@"CustomProperties"]) {
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
			else if ([[showChild name] isEqualToString:@"CurrentShowings"]) {
				// showChild here is an array of Showing
				for (int k = 0; k < [showChild childCount]; k++) {
					DDXMLElement *showingElement = (DDXMLElement*)[showChild childAtIndex:k];
					Showing *showing = [[Showing alloc] init];
					
					for (int l = 0; l < [showingElement childCount]; l++) {
						DDXMLElement *showingChild = (DDXMLElement*)[showingElement childAtIndex:l];
						
						if ([[showingChild name] isEqualToString:@"ID"]) {
							showing.ID = [showingChild stringValue];
						}
						else if ([[showingChild name] isEqualToString:@"StartDate"]) {
							showing.startDate = [showingChild stringValue];
						}
						else if ([[showingChild name] isEqualToString:@"EndDate"]) {
							showing.endDate = [showingChild stringValue];
						}
						else if ([[showingChild name] isEqualToString:@"ShortDescription"]) {
							showing.shortDescription = [showingChild stringValue];
						}
						else if ([[showingChild name] isEqualToString:@"Venue"]) {
							for (int m = 0; m < [showingChild childCount]; m++) {
								DDXMLElement *venueChild = (DDXMLElement*)[showingChild childAtIndex:m];
								if ([[venueChild name] isEqualToString:@"VenueID"]) {
									showing.venue.ID = [venueChild stringValue];
								}
								else if ([[venueChild name] isEqualToString:@"VenueName"]) {
									showing.venue.name = [venueChild stringValue];
								}
								else if ([[venueChild name] isEqualToString:@"VenueAddress1"]) {
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
} // end parseShow

@end
