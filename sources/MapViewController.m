//
//  MapViewController.m
//  Cinequest
//
//  Created by Luca Severini on 12/2/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

#import "CinequestAppDelegate.h"
#import "MapViewController.h"
#import "Venue.h"

#define ALTITUDE 2000.0

@implementation MapViewController

@synthesize mapView;
@synthesize openInMapsBtn;
@synthesize directionsBtn;
@synthesize trackingBtn;
@synthesize bottomBar;
@synthesize mapItem;
@synthesize placemark;
@synthesize venueAnnotation;
@synthesize venue;

- (id) initWithNibName:(NSString*)nibName andVenue:(Venue*)theVenue
{
    self = [super initWithNibName:nibName bundle:nil];
    if(self != nil)
	{
		NSDictionary *venues = appDelegate.venuesDictionary;
		self.venue = [venues objectForKey:theVenue.ID];
	}
	
    return self;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
	
	UISegmentedControl *switchTitle = [[UISegmentedControl alloc] initWithFrame:CGRectMake(98.5, 7.5, 123.0, 29.0)];
	[switchTitle setSegmentedControlStyle:UISegmentedControlStyleBar];
	[switchTitle insertSegmentWithTitle:@"Venue Location" atIndex:0 animated:NO];
	[switchTitle setSelectedSegmentIndex:0];
	NSDictionary *attribute = [NSDictionary dictionaryWithObject:[UIFont boldSystemFontOfSize:16.0f] forKey:UITextAttributeFont];
	[switchTitle setTitleTextAttributes:attribute forState:UIControlStateNormal];
	self.navigationItem.titleView = switchTitle;

    trackingBtn = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    directionsBtn = [[UIBarButtonItem alloc] initWithTitle:@"Directions" style:UIBarButtonItemStylePlain target:self action:@selector(directions:)];
    openInMapsBtn = [[UIBarButtonItem alloc] initWithTitle:@"Open in Maps" style:UIBarButtonItemStylePlain target:self action:@selector(openInMaps:)];
    NSArray *bottomBarItems = [[NSArray alloc] initWithObjects:trackingBtn, flexSpace, directionsBtn, flexSpace, openInMapsBtn, nil];
    [self.bottomBar setItems:bottomBarItems animated:NO];

    [self.mapView setUserTrackingMode:MKUserTrackingModeNone animated:NO];
	
	self.mapView.hidden = YES;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	
	NSString *venueName = [[venue.name componentsSeparatedByString:@"-"] objectAtIndex:0];
	
	// Set location to be searched
	NSString *location = [NSString stringWithFormat:@"%@, %@ %@, %@, %@ %@", venueName, venue.address1, venue.address2, venue.city, venue.state, venue.zip];
	
	CLGeocoder *geocoder = [CLGeocoder new];
	[geocoder geocodeAddressString:location completionHandler:
	^(NSArray *placemarks, NSError *error)
	{
		if(error == nil)
		{
			NSLog(@"Shows location of venue %@ in maps", venue.shortName);

			// Convert the CLPlacemark to an MKPlacemark
			// Note: There's no error checking for a failed geocode
			CLPlacemark *geocodedPlacemark = [placemarks objectAtIndex:0];
			placemark = [[MKPlacemark alloc] initWithCoordinate:geocodedPlacemark.location.coordinate addressDictionary:geocodedPlacemark.addressDictionary];

			venueAnnotation = [MKPointAnnotation new];
			venueAnnotation.coordinate = placemark.coordinate;
			venueAnnotation.title = venueName;
			venueAnnotation.subtitle = nil;

			// Create a map item for the geocoded address to pass to Maps app
			mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
			[mapItem setName:venue.name];

			[mapView addAnnotation:venueAnnotation];

            MKMapCamera* camera = [MKMapCamera
                                   cameraLookingAtCenterCoordinate:(CLLocationCoordinate2D)venueAnnotation.coordinate
                                   fromEyeCoordinate:(CLLocationCoordinate2D)venueAnnotation.coordinate
                                   eyeAltitude:(CLLocationDistance)ALTITUDE];
            [mapView setCamera:camera animated:NO];
			
			self.mapView.hidden = NO;
            
			MKCoordinateRegion thisRegion = MKCoordinateRegionMakeWithDistance(venueAnnotation.coordinate, 1610 * 3, 1610 * 3); // 3 miles
			[mapView setRegion:thisRegion animated:NO];
		}
		else
		{
			self.mapView.hidden = NO;

			NSLog(@"Location of venue %@ not found", venue.shortName);
		}
	}];
}

- (void) mapView:(MKMapView*)aMapView didAddAnnotationViews:(NSArray*)views
{
	[aMapView selectAnnotation:venueAnnotation animated:YES];
}

- (MKAnnotationView*) mapView:(MKMapView*)aMapView viewForAnnotation:(id<MKAnnotation>)annotation
{
	if(annotation == self.venueAnnotation)
	{
		NSString *title = annotation.title;
		
		MKPinAnnotationView *pinView = (MKPinAnnotationView*)[aMapView dequeueReusableAnnotationViewWithIdentifier:title];
		if(pinView == nil)
		{
			pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:title];
		}
		
		pinView.canShowCallout = YES;
		pinView.animatesDrop = YES;
		
		return pinView;
	}
	else
	{
		return nil;
	}
}

- (IBAction) openInMaps:(id)sender
{
	[self.mapItem openInMapsWithLaunchOptions:nil];
	
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) directions:(id)sender
{
	[self showRouteFrom:mapView.userLocation to:venueAnnotation];
}

- (void) showRouteFrom:(id<MKAnnotation>)from to:(id<MKAnnotation>)to
{
	if(![appDelegate connectedToNetwork])
	{
#pragma message "Better to show a popup to warn the user?"
		NSLog(@"NO CONNECTION. Can't show route");
		return;
	}

    routes = [self calculateRoutesFrom:from.coordinate to:to.coordinate];
    NSInteger numberOfSteps = routes.count;
	
    CLLocationCoordinate2D coordinates[numberOfSteps];
    for(NSInteger index = 0; index < numberOfSteps; index++)
    {
        CLLocation *location = [routes objectAtIndex:index];
        coordinates[index] = location.coordinate;
    }
	
	MKPolyline *polyLine = [MKPolyline polylineWithCoordinates:coordinates count:numberOfSteps];
	if([mapView respondsToSelector:@selector(addOverlay:level:)])
	{
#ifdef __IPHONE_7_0
		[mapView addOverlay:polyLine level:MKOverlayLevelAboveRoads]; 	// This code compiles only with iOS SDK version 7 or later
#endif
	}
	else
	{
		[mapView addOverlay:polyLine];
	}
	
    [self centerMap];
}

- (NSArray*) calculateRoutesFrom:(CLLocationCoordinate2D)from to:(CLLocationCoordinate2D)to
{
    NSString* saddr = [NSString stringWithFormat:@"%f,%f", from.latitude, from.longitude];
    NSString* daddr = [NSString stringWithFormat:@"%f,%f", to.latitude, to.longitude];
	
    NSString* apiUrlStr = [NSString stringWithFormat:@"http://maps.google.com/maps?output=dragdir&saddr=%@&daddr=%@", saddr, daddr];
    NSURL* apiUrl = [NSURL URLWithString:apiUrlStr];
    
    NSError* error = nil;
    NSString *apiResponse = [NSString stringWithContentsOfURL:apiUrl encoding:NSASCIIStringEncoding error:&error];
	
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"points:\\\"([^\\\"]*)\\\"" options:0 error:NULL];
	NSTextCheckingResult *match = [regex firstMatchInString:apiResponse options:0 range:NSMakeRange(0, [apiResponse length])];
	NSString *encodedPoints = [apiResponse substringWithRange:[match rangeAtIndex:1]];
	
    return [self decodePolyLine:[encodedPoints mutableCopy]];
}

- (NSMutableArray*) decodePolyLine:(NSMutableString*)encoded
{
    [encoded replaceOccurrencesOfString:@"\\\\" withString:@"\\" options:NSLiteralSearch range:NSMakeRange(0, [encoded length])];
	
    NSInteger len = [encoded length];
    NSInteger index = 0;
    NSInteger lat = 0;
    NSInteger lng = 0;
    NSMutableArray *array = [NSMutableArray new];
	
    while(index < len)
    {
        NSInteger ch = 0;
		
        NSInteger shift = 0;
        NSInteger result = 0;
        do
        {
            ch = [encoded characterAtIndex:index++] - 63;
            result |= (ch & 0x1f) << shift;
            shift += 5;
        }
		while (ch >= 0x20);
        
		NSInteger dlat = ((result & 1) ? ~(result >> 1) : (result >> 1));
        lat += dlat;
		
        shift = 0;
        result = 0;
        do
        {
            ch = [encoded characterAtIndex:index++] - 63;
            result |= (ch & 0x1f) << shift;
            shift += 5;
        }
		while (ch >= 0x20);
		
        NSInteger dlng = ((result & 1) ? ~(result >> 1) : (result >> 1));
        lng += dlng;
		
        NSNumber *latitude = [[NSNumber alloc] initWithFloat:lat * 1e-5];
        NSNumber *longitude = [[NSNumber alloc] initWithFloat:lng * 1e-5];
		
		CLLocation *loc = [[CLLocation alloc] initWithLatitude:[latitude floatValue] longitude:[longitude floatValue]];
        [array addObject:loc];
    }
	
    return array;
}

- (void) centerMap
{
    MKCoordinateRegion region;
    CLLocationDegrees maxLat = -90.0;
    CLLocationDegrees maxLon = -180.0;
    CLLocationDegrees minLat = 90.0;
    CLLocationDegrees minLon = 180.0;
	
	CLLocation *start =  [routes firstObject];
	CLLocation *end =  [routes lastObject];
	
	// Compute the area the map view will be centered upon
	CGFloat startLat = start.coordinate.latitude;
	CGFloat startLon = start.coordinate.longitude;
	CGFloat endLat = end.coordinate.latitude;
	CGFloat endLon = end.coordinate.longitude;

	if(start.coordinate.latitude < end.coordinate.latitude)
	{
		// Dec start latitude
		startLat -= 0.01;
		// Inc end latitude
		endLat += 0.01;
	}
	else
	{
		// Inc start latitude
		startLat += 0.01;
		// Dec end latitude
		endLat -= 0.01;
	}
	
	if(start.coordinate.longitude < end.coordinate.longitude)
	{
		// Dec start longitude
		startLon -= 0.01;
		// Inc end longitude
		endLon += 0.01;
	}
	else
	{
		// Inc start longitude
		startLon += 0.01;
		// Dec end longitude
		endLon -= 0.01;
	}
	
	NSInteger count = routes.count;
    for(NSInteger idx = 0; idx < count; idx++)
    {
        CLLocation* currentLocation;
		
		if(idx == 0)
		{
			currentLocation = [[CLLocation alloc] initWithLatitude:startLat longitude:startLon];
		}
		else if(idx == count - 1)
		{
			currentLocation = [[CLLocation alloc] initWithLatitude:endLat longitude:endLon];
		}
		else
		{
			currentLocation = [routes objectAtIndex:idx];
		}
		
        if(currentLocation.coordinate.latitude > maxLat)
		{
            maxLat = currentLocation.coordinate.latitude;
		}
		
        if(currentLocation.coordinate.latitude < minLat)
		{
            minLat = currentLocation.coordinate.latitude;
		}
		
        if(currentLocation.coordinate.longitude > maxLon)
		{
            maxLon = currentLocation.coordinate.longitude;
		}
		
        if(currentLocation.coordinate.longitude < minLon)
		{
            minLon = currentLocation.coordinate.longitude;
		}
    }
	
    region.center.latitude = (maxLat + minLat) / 2.0;
    region.center.longitude = (maxLon + minLon) / 2.0;
    region.span.latitudeDelta = 0.01;
    region.span.longitudeDelta = 0.01;
    region.span.latitudeDelta = ((maxLat - minLat) < 0.0) ? 100.0 : (maxLat - minLat);
    region.span.longitudeDelta = ((maxLon - minLon) < 0.0) ? 100.0 : (maxLon - minLon);
	
    [mapView setRegion:region animated:YES];
}

- (MKOverlayView*) mapView:(MKMapView*)mapView viewForOverlay:(id<MKOverlay>)overlay
{
    MKPolylineView *polylineView = [[MKPolylineView alloc] initWithPolyline:overlay];
    polylineView.strokeColor = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.8];
    polylineView.lineWidth = 10.0;
	
    return polylineView;
}

@end
