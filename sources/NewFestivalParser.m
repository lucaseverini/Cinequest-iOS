//
//  NewFestivalParser.m
//  Cinequest
//
//  Created by Hai Nguyen on 11/28/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "NewFestivalParser.h"

#import "CinequestAppDelegate.h"
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

@interface NewFestivalParser(){
    NSSet *neglectKeysFromFeed;
}

@end

@implementation NewFestivalParser

@synthesize shows;

- (id) init
{
    self = [super init];
    if(self != nil)
    {
        delegate = appDelegate;
        shows = [[NSMutableArray alloc] init];
        neglectKeysFromFeed = [NSMutableSet setWithObjects:@"Submission ID",@"ShortID",@"EventType", nil];
    }
    
    return self;
}

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
                [festival.films addObject:film];
                [shorts setObject:film forKey:show.ID];
                [self addItem:film to:festival.alphabetToFilmsDictionary];
            } else if ([eventType count] > 1) {
                // skipping Show that has more than 1 EventType
                [errorString appendFormat:@"Show with ID: %@ has more than 1 EventType\n", show.ID];
                continue;
            } else if ([eventType containsObject:@"Film"]) {
                Film *film = [self getFilmFrom:show];
                [festival.films addObject:film];
                [shorts setObject:film forKey:show.ID];
                [self addItem:film to:festival.alphabetToFilmsDictionary];
            } else if ([eventType containsObject:@"Forum"]) {
                Forum *forum = [self getForumFrom:show];
                [festival.forums addObject:forum];
                [shorts setObject:forum forKey:show.ID];
            } else if ([eventType containsObject:@"Special"]) {
                Special *special = [self getSpecialFrom:show];
                [festival.specials addObject:special];
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
            [errorString appendFormat:@"Show with ID: %@ has no EventType\n", show.ID];
            item = [self getFilmFrom:show];
            [self addItem:item to:festival.alphabetToFilmsDictionary];
            [festival.films addObject:item];
        } else if ([eventType count] > 1) {
            // skipping Show that has more than 1 EventType
            [errorString appendFormat:@"Show with ID: %@ has more than 1 EventType\n", show.ID];
            continue;
        } else if ([eventType containsObject:@"Film"]) {
            item = [self getFilmFrom:show];
            [self addItem:item to:festival.alphabetToFilmsDictionary];
            [festival.films addObject:item];
        } else if ([eventType containsObject:@"Forum"]) {
            item = [self getForumFrom:show];
            [festival.forums addObject:item];
        } else if ([eventType containsObject:@"Special"]) {
            item = [self getSpecialFrom:show];
            [festival.specials addObject:item];
        }
        
        NSMutableArray *shortIDs = [show.customProperties objectForKey:@"ShortID"];
        if (shortIDs != nil) {
            for (NSString *ID in shortIDs) {
                CinequestItem *subItem = [shorts objectForKey:ID];
                if (subItem != nil) {
                    [item.shortItems addObject:subItem];
                }
            }
        }
        
        for (Showing *showing in show.currentShowings) {
            Schedule *schedule = [self getScheduleFrom:showing forItem:item];
            [item.schedules addObject:schedule];
            [festival.schedules addObject:schedule];
            
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
    
    // Add short items to the corresponding date Dictionary
    /* for (CinequestItem *shortItem in [shorts allValues]) {
        for (Schedule *shortItemSchedule in shortItem.schedules) {
            [self addItemToDictionary:shortItem with:shortItemSchedule in:festival];
        }
    } */
    
    appDelegate.festivalParsed = YES;
    
    // prepare sorted keys and indexes arrays
    
    // for DateToFilmsDictionary
    festival.sortedKeysInDateToFilmsDictionary = [self getSortedKeysFromDateDictionary:[festival dateToFilmsDictionary]];
    festival.sortedIndexesInDateToFilmsDictionary = [self getSortedIndexesFromSortedKeys:[festival sortedKeysInDateToFilmsDictionary]];
    for (NSString *key in festival.dateToFilmsDictionary) {
        NSMutableArray *films = (NSMutableArray *)[festival.dateToFilmsDictionary objectForKey:key];
        [self sortCinequestItemsByStartDate:films forKey:key];
    }
    
    // for AlphabetToFilmsDictionary
    festival.sortedKeysInAlphabetToFilmsDictionary = [self getSortedKeysFromAlphabetDictionary:[festival alphabetToFilmsDictionary]];
    for (NSString *key in festival.sortedKeysInAlphabetToFilmsDictionary) {
        NSMutableArray *films = (NSMutableArray*)[festival.alphabetToFilmsDictionary objectForKey:key];
        [self sortCinequestItemsAlphabetically:films];
    }
    
    
    // for DateToForumsDictionary
    festival.sortedKeysInDateToForumsDictionary = [self getSortedKeysFromDateDictionary:[festival dateToForumsDictionary]];
    festival.sortedIndexesInDateToForumsDictionary = [self getSortedIndexesFromSortedKeys:[festival sortedKeysInDateToForumsDictionary]];
    for (NSString *key in festival.dateToForumsDictionary) {
        NSMutableArray *forums = (NSMutableArray *)[festival.dateToForumsDictionary objectForKey:key];
        [self sortCinequestItemsByStartDate:forums forKey:key];
    }
    
    // for DateToSpecialsDictionary
    festival.sortedKeysInDateToSpecialsDictionary = [self getSortedKeysFromDateDictionary:[festival dateToSpecialsDictionary]];
    festival.sortedIndexesInDateToSpecialsDictionary = [self getSortedIndexesFromSortedKeys:[festival sortedKeysInDateToSpecialsDictionary]];
    for (NSString *key in festival.dateToSpecialsDictionary) {
        NSMutableArray *specials = (NSMutableArray *)[festival.dateToSpecialsDictionary objectForKey:key];
        [self sortCinequestItemsByStartDate:specials forKey:key];
    }
    
    return festival;
}


- (void) addItem:(CinequestItem *)item to:(NSMutableDictionary *)alphabetDictionary
{
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

- (void) addItemToDictionary:(CinequestItem *)item with:(Schedule *)schedule in:(Festival*)festival
{
    NSString *date = [schedule longDateString];
    NSMutableArray *values;
    if ([date length] > 0) {
        if ([item isKindOfClass:[Film class]]) {
            values = [festival.dateToFilmsDictionary objectForKey:date];
            if (values == nil) {
                values = [NSMutableArray array];
                [values addObject:item];
                [festival.dateToFilmsDictionary setObject:values forKey:date];
                return;
            } else {
                [values addObject:item];
            }
        } else if ([item isKindOfClass:[Forum class]]) {
            values = [festival.dateToForumsDictionary objectForKey:date];
            if (values == nil) {
                values = [NSMutableArray array];
                [values addObject:item];
                [festival.dateToForumsDictionary setObject:values forKey:date];
                return;
            } else {
                [values addObject:item];
            }
        } else if ([item isKindOfClass:[Special class]]) {
            values = [festival.dateToSpecialsDictionary objectForKey:date];
            if (values == nil) {
                values = [NSMutableArray array];
                [values addObject:item];
                [festival.dateToSpecialsDictionary setObject:values forKey:date];
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


- (VenueLocation*) getVenueLocation:(Venue *)venue
{
    VenueLocation *loc = [[VenueLocation alloc] init];
    loc.ID = venue.ID;
    loc.venueAbbreviation = [self venueAbbr:(venue.name)];
    loc.name = venue.name;
    loc.location = venue.address;
    return loc;
}

- (Schedule*) getScheduleFrom:(Showing *)showing forItem:(CinequestItem *)item
{
    Schedule *schedule = [[Schedule alloc] init];
    schedule.ID = showing.ID;
    schedule.itemID = item.ID;
    schedule.title = item.name;
    schedule.description = item.description;
    
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
    
    //To keep track of Selected User schedules after refresh of table from FilmsView, EventsView or ForumsView
    NSUInteger scheduleCount = [delegate.mySchedule count];
    if (scheduleCount) {
        for (int scheduleIdx = 0; scheduleIdx < scheduleCount; scheduleIdx++) {
            Schedule *scheduleFromCalendar = [delegate.mySchedule objectAtIndex:scheduleIdx];
            if ([scheduleFromCalendar.ID isEqualToString:schedule.ID]) {
                schedule.isSelected = YES;
                break;
            }
        }
    }
    
    return schedule;
}

- (NSString*) venueAbbr:(NSString *)name
{
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^A-Z0-9\\-]" options:0 error:&error];
    NSString *modifiedString = [regex stringByReplacingMatchesInString:name options:0 range:NSMakeRange(0, [name length]) withTemplate:@""];
	
    return modifiedString;
}

//Checks if the show is part of shorts program
- (BOOL) isPartOfShorts:(NSString *)shortDescription
{
    NSString *string = @"Part of Shorts Program";
    
    return ([shortDescription rangeOfString:string].location != NSNotFound);
}

- (Film*) getFilmFrom:(Show *)show
{
    Film *film = [[Film alloc] init];
    
    film.ID = show.ID;
    film.name = show.name;
    film.description = show.shortDescription;
    film.imageURL = show.thumbImageURL;
    film.infoLink = show.infoLink;
    film.director = [self get:show.customProperties forkey:@"Director"];
    film.producer = [self get:show.customProperties forkey:@"Producer"];
    film.cinematographer = [self get:show.customProperties forkey:@"Cinematographer"];
    film.editor  =  [self get:show.customProperties forkey:@"Editor"];
    film.cast = [self get:show.customProperties forkey:@"Cast"];
    film.country = [self get:show.customProperties forkey:@"Production Country"];
    film.language = [self get:show.customProperties forkey:@"Language"];
    film.genre = [self get:show.customProperties forkey:@"Genre"];
    
    //Create webContent for Film Detail according to the sequence numbers from Feed
    NSArray *sortedSequence = [[show.sequenceDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
    film.webString = @"";
    
    //Only compute webstring if the CustomProperty contains Sequence elements
    if ([sortedSequence count]) {
        film.webString = [film.webString stringByAppendingFormat:@"<h4>Film Info</h4>"];
        for (NSNumber *num in sortedSequence) {
            NSString *strKey = [show.sequenceDictionary objectForKey:num];
            NSString *strValue = [self get:show.customProperties forkey:[show.sequenceDictionary objectForKey:num]];
            if ([strKey isEqualToString:@"Director"]) {
                film.webString = [film.webString stringByAppendingFormat:@"<h4>Cast/Crew Info</h4>"];
            }
            film.webString = [film.webString stringByAppendingFormat:@"<b>%@</b>: %@<br/>",strKey,strValue];
        }
    }
    
    return film;
}

- (Forum*) getForumFrom:(Show *)show
{
    Forum *forum = [[Forum alloc] init];
    
    forum.ID = show.ID;
    forum.name = show.name;
    forum.description = show.shortDescription;
    forum.imageURL = show.thumbImageURL;
    forum.infoLink = show.infoLink;
    
    return forum;
}

- (Special*) getSpecialFrom:(Show *)show
{
    Special *special = [[Special alloc] init];
    
    special.ID = show.ID;
    special.name = show.name;
    special.description = show.shortDescription;
    special.imageURL = show.thumbImageURL;
    special.infoLink = show.infoLink;
    special.director = [self get:show.customProperties forkey:@"Director"];
    special.producer = [self get:show.customProperties forkey:@"Producer"];
    special.cinematographer = [self get:show.customProperties forkey:@"Cinematographer"];
    special.editor  =  [self get:show.customProperties forkey:@"Editor"];
    special.cast = [self get:show.customProperties forkey:@"Cast"];
    special.country = [self get:show.customProperties forkey:@"Production Country"];
    special.language = [self get:show.customProperties forkey:@"Language"];
    special.genre = [self get:show.customProperties forkey:@"Genre"];
    
    return special;
}


- (NSString*) get:(NSMutableDictionary *)custom forkey:(NSString*) key
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

- (NSMutableArray*) getSortedKeysFromAlphabetDictionary:(NSMutableDictionary *)dictionary
{
    NSMutableArray *sortedKeys = (NSMutableArray *)[[dictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
    return sortedKeys;
}

- (void) sortCinequestItemsAlphabetically:(NSMutableArray *)cinequestItems
{
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    [cinequestItems sortUsingDescriptors:[NSArray arrayWithObject:sort]];
}

- (void) sortCinequestItemsByStartDate:(NSMutableArray *)cinequestItems forKey:(NSString *)key
{
    [cinequestItems sortUsingComparator:^(id object1, id object2) {
        Film *film1 = (Film *)object1;
        Film *film2 = (Film *)object2;
        
        Schedule *schedule1;
        for (Schedule *schedule in film1.schedules) {
            if ([schedule.longDateString isEqualToString:key])
                schedule1 = schedule;
        }
        
        Schedule *schedule2;
        for (Schedule *schedule in film2.schedules) {
            if ([schedule.longDateString isEqualToString:key])
                schedule2 = schedule;
        }
        
        NSDate *date1 = schedule1.startDate;
        NSDate *date2 = schedule2.startDate;
        
        return [date1 compare:date2];
    }];
}

- (NSMutableArray*) getSortedKeysFromDateDictionary:(NSMutableDictionary *)dictionary
{
    NSMutableArray *sortedKeys = (NSMutableArray *)[dictionary allKeys];
    
    sortedKeys = (NSMutableArray*)[sortedKeys sortedArrayUsingComparator:
	^(id object1, id object2)
	{
        NSString *day1 = (NSString *)object1;
        NSString *day2 = (NSString *)object2;
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        
        [dateFormatter setDateFormat:@"EEEE, MMMM d"];
        NSDate *date1 = [dateFormatter dateFromString:day1];
        NSDate *date2 = [dateFormatter dateFromString:day2];
        
        return [date1 compare:date2];
    }];
    
    return sortedKeys;
}

- (NSMutableArray*) getSortedIndexesFromSortedKeys:(NSMutableArray *)sortedKeysArray
{
    NSMutableArray *sortedIndexes = [[NSMutableArray alloc] init];
    for (NSString *date in sortedKeysArray)
	{
        [sortedIndexes addObject:[[date componentsSeparatedByString:@" "] objectAtIndex: 2]];
    }
	
    return sortedIndexes;
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
	if([atsFeed childCount] >= 3)
	{
		DDXMLElement *arrayOfShows = (DDXMLElement*)[atsFeed childAtIndex:2];
		for (int idx = 0; idx < [arrayOfShows childCount]; idx++)
		{
			DDXMLElement *showElement = (DDXMLElement*)[arrayOfShows childAtIndex:idx];
			
			Show *show = [[Show alloc] init];
			for (int elemIdx = 0; elemIdx < [showElement childCount]; elemIdx++)
			{
				/* Should I declare showChild outside this block? */
				DDXMLElement *showChild = (DDXMLElement*)[showElement childAtIndex:elemIdx];
				if ([[showChild name] isEqualToString:@"ID"])
				{
					show.ID = [showChild stringValue];
				}
				else if ([[showChild name] isEqualToString:@"Name"])
				{
					show.name = [showChild stringValue];
				}
				else if ([[showChild name] isEqualToString:@"Duration"])
				{
					show.duration = [[showChild stringValue] intValue];
				}
				else if ([[showChild name] isEqualToString:@"ShortDescription"])
				{
					show.shortDescription = [showChild stringValue];
				}
				else if ([[showChild name] isEqualToString:@"ThumbImage"])
				{
					show.thumbImageURL = [showChild stringValue];
				}
				else if ([[showChild name] isEqualToString:@"EventImage"])
				{
					show.eventImageURL = [showChild stringValue];
				}
				else if ([[showChild name] isEqualToString:@"InfoLink"])
				{
					show.infoLink = [showChild stringValue];
				}
				else if ([[showChild name] isEqualToString:@"CustomProperties"])
				{
					// showChild here is an array of CustomerProperty
					// Not sure if this is a safe approach
					for (int childIdx = 0; childIdx < [showChild childCount]; childIdx++)
					{
						DDXMLElement *customProperty = (DDXMLElement*)[showChild childAtIndex:childIdx];
						if ([[[customProperty childAtIndex:0] name] isEqualToString:@"Name"])
						{
							NSString *customPropertyName = [[customProperty childAtIndex:0] stringValue];
							NSMutableArray *values = [show.customProperties objectForKey:customPropertyName];
							if (values == nil)
							{
								values = [NSMutableArray array];
								[show.customProperties setObject:values forKey:customPropertyName];
							}
							
							if ([[[customProperty childAtIndex:4] name] isEqualToString:@"Value"])
							{
								NSString *customPropertyValue = [[customProperty childAtIndex:4] stringValue];
								[values addObject:customPropertyValue];
							}
                            
                            //Store Sequence Numbers with value Name of Property
                            if ([[[customProperty childAtIndex:2] name]isEqualToString:@"Sequence"] && ![[show.sequenceDictionary allValues] containsObject:customPropertyName]) {
                                //Neglect sequence number for Submission ID, ShortID, EventType
                                if (![neglectKeysFromFeed containsObject:customPropertyName]) {
                                    NSNumber *num = @([[[customProperty childAtIndex:2] stringValue] intValue]);
                                    [show.sequenceDictionary setObject:customPropertyName forKey:num];
                                }
                            }
						}
					}
					
				}
				else if ([[showChild name] isEqualToString:@"CurrentShowings"])
				{
					// showChild here is an array of Showing
					for (int childIdx = 0; childIdx < [showChild childCount]; childIdx++)
					{
						DDXMLElement *showingElement = (DDXMLElement*)[showChild childAtIndex:childIdx];
						Showing *showing = [[Showing alloc] init];
						
						for (int childElemIdx = 0; childElemIdx < [showingElement childCount]; childElemIdx++)
						{
							DDXMLElement *showingChild = (DDXMLElement*)[showingElement childAtIndex:childElemIdx];
							
							if ([[showingChild name] isEqualToString:@"ID"])
							{
								showing.ID = [showingChild stringValue];
							}
							else if ([[showingChild name] isEqualToString:@"StartDate"])
							{
								showing.startDate = [showingChild stringValue];
							}
							else if ([[showingChild name] isEqualToString:@"EndDate"])
							{
								showing.endDate = [showingChild stringValue];
							}
							else if ([[showingChild name] isEqualToString:@"ShortDescription"])
							{
								showing.shortDescription = [showingChild stringValue];
							}
							else if ([[showingChild name] isEqualToString:@"Venue"])
							{
								for (int showingChildIdx = 0; showingChildIdx < [showingChild childCount]; showingChildIdx++)
								{
									DDXMLElement *venueChild = (DDXMLElement*)[showingChild childAtIndex:showingChildIdx];
									if ([[venueChild name] isEqualToString:@"VenueID"])
									{
										showing.venue.ID = [venueChild stringValue];
									}
									else if ([[venueChild name] isEqualToString:@"VenueName"])
									{
										showing.venue.name = [venueChild stringValue];
									}
									else if ([[venueChild name] isEqualToString:@"VenueAddress1"])
									{
										showing.venue.address = [venueChild stringValue];
									}
								}
							}
						}
						
						[show.currentShowings addObject:showing];
					}
				}
			}
            
            //Do not add show when there are no schedules and its not a part of shorts program
            if (!([show.currentShowings count] == 0 && ![self isPartOfShorts:show.shortDescription])) {
                [self.shows addObject:show];
            }
		}
    }
}

@end
