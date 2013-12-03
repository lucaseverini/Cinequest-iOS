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


@implementation MapViewController

@synthesize mapView;
@synthesize openInMapsBtn;
@synthesize directionsBtn;
@synthesize trackingBtn;
@synthesize bottomBar;
@synthesize mapItem;
@synthesize placemark;
@synthesize annotation;
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
	
	self.title = @"Venue Location";

    trackingBtn = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    directionsBtn = [[UIBarButtonItem alloc] initWithTitle:@"Directions" style:UIBarButtonItemStylePlain target:self action:@selector(directions:)];
    openInMapsBtn = [[UIBarButtonItem alloc] initWithTitle:@"Open in Maps" style:UIBarButtonItemStylePlain target:self action:@selector(openInMaps:)];
    NSArray *bottomBarItems = [[NSArray alloc] initWithObjects:trackingBtn, flexSpace, directionsBtn, flexSpace, openInMapsBtn, nil];
    [self.bottomBar setItems:bottomBarItems animated:NO];

    [self.mapView setUserTrackingMode:MKUserTrackingModeNone animated:NO];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	
	NSString *venueName = [[venue.name componentsSeparatedByString:@"-"] firstObject];
	
	// Set location to be searched
	NSString *location = [NSString stringWithFormat:@"%@, %@ %@, %@, %@ %@", venueName, venue.address1, venue.address2, venue.city, venue.state, venue.zip];
	
	CLGeocoder *geocoder = [[CLGeocoder alloc] init];
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

			annotation = [MKPointAnnotation new];
			annotation.coordinate = placemark.coordinate;
			annotation.title = venueName;
			annotation.subtitle = nil;

			// Create a map item for the geocoded address to pass to Maps app
			mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
			[mapItem setName:venue.name];

			[mapView addAnnotation:annotation];

			MKCoordinateRegion thisRegion = MKCoordinateRegionMakeWithDistance(annotation.coordinate, 1610 * 3, 1610 * 3); // 3 miles
			[mapView setRegion:thisRegion animated:NO];
		}
		else
		{
			NSLog(@"Location of venue %@ not found", venue.shortName);
		}
	}];
}

- (void) mapView:(MKMapView*)aMapView didAddAnnotationViews:(NSArray*)views
{
	[aMapView selectAnnotation:annotation animated:YES];
}

- (MKAnnotationView*) mapView:(MKMapView*)aMapView viewForAnnotation:(id<MKAnnotation>)theAnnotation
{
	if(theAnnotation != self.annotation)
	{
		return nil;
	}
	
    NSString *title = theAnnotation.title;
	
    MKPinAnnotationView *pinView = (MKPinAnnotationView*)[aMapView dequeueReusableAnnotationViewWithIdentifier:title];
	if(pinView == nil)
	{
		pinView = [[MKPinAnnotationView alloc] initWithAnnotation:theAnnotation reuseIdentifier:title];
	}
	
	pinView.canShowCallout = YES;
	pinView.animatesDrop = YES;
	
	return pinView;
}

- (IBAction) openInMaps:(id)sender
{
	// Pass the map item to the Maps app
	[self.mapItem openInMapsWithLaunchOptions:nil];
}

- (IBAction) directions:(id)sender
{
	NSLog(@"directions");
	
	[self showRouteFrom:mapView.userLocation to:annotation];
}

- (void) showRouteFrom:(id<MKAnnotation>)from to:(id<MKAnnotation>)to
{
    routes = [self calculateRoutesFrom:from.coordinate to:to.coordinate];
    NSInteger numberOfSteps = routes.count;
	
    CLLocationCoordinate2D coordinates[numberOfSteps];
    for(NSInteger index = 0; index < numberOfSteps; index++)
    {
        CLLocation *location = [routes objectAtIndex:index];
        CLLocationCoordinate2D coordinate = location.coordinate;
        coordinates[index] = coordinate;
    }
	
    MKPolyline *polyLine = [MKPolyline polylineWithCoordinates:coordinates count:numberOfSteps];
    [mapView addOverlay:polyLine];
	
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
    // NSString *encodedPoints = [apiResponse stringByMatching:@"points:\\\"([^\\\"]*)\\\"" capture:1L];
	
    return [self decodePolyLine:[encodedPoints mutableCopy]];
}

- (NSMutableArray*) decodePolyLine:(NSMutableString*)encoded
{
    [encoded replaceOccurrencesOfString:@"\\\\" withString:@"\\" options:NSLiteralSearch range:NSMakeRange(0, [encoded length])];
    NSInteger len = [encoded length];
    NSInteger index = 0;
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSInteger lat=0;
    NSInteger lng=0;
    while (index < len)
    {
        NSInteger b;
        NSInteger shift = 0;
        NSInteger result = 0;
        do
        {
            b = [encoded characterAtIndex:index++] - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);
        NSInteger dlat = ((result & 1) ? ~(result >> 1) : (result >> 1));
        lat += dlat;
        shift = 0;
        result = 0;
        do
        {
            b = [encoded characterAtIndex:index++] - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);
        NSInteger dlng = ((result & 1) ? ~(result >> 1) : (result >> 1));
        lng += dlng;
        NSNumber *latitude = [[NSNumber alloc] initWithFloat:lat * 1e-5];
        NSNumber *longitude = [[NSNumber alloc] initWithFloat:lng * 1e-5];
        //printf("[%f,", [latitude doubleValue]);
        //printf("%f]", [longitude doubleValue]);
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
	
    for(int idx = 0; idx < routes.count; idx++)
    {
        CLLocation* currentLocation = [routes objectAtIndex:idx];
		
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
    region.span.latitudeDelta = ((maxLat - minLat)< 0.0) ? 100.0 : (maxLat - minLat);
    region.span.longitudeDelta = ((maxLon - minLon)< 0.0) ? 100.0 : (maxLon - minLon);
	
    [mapView setRegion:region animated:YES];
}

- (MKOverlayView*) mapView:(MKMapView*)mapView viewForOverlay:(id<MKOverlay>)overlay
{
    MKPolylineView *polylineView = [[MKPolylineView alloc] initWithPolyline:overlay];
    polylineView.strokeColor = [UIColor blueColor];
    polylineView.lineWidth = 5.0;
	
    return polylineView;
}

@end
