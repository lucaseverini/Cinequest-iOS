//
//  NVPolylineAnnotation.m
//  CineQuest
//
//  Created by Luca Severini on 12-03-2013.
//  Derived from code written by William Lachance, Craig Spitzkoff and Nicolas Neubauer.
//

#import "NVPolylineAnnotation.h"


@implementation NVPolylineAnnotation

@synthesize points;
@synthesize mapView;

- (id) initWithCoordinates:(CLLocationCoordinate2D*)coordinates count:(NSInteger)count mapView:(MKMapView*)theMapView
{
	self = [super init];
	if(self != nil)
	{
		self.mapView = theMapView;
		
		self.points = [[NSMutableArray alloc] initWithCapacity:count];
		for(NSInteger idx = 0; idx < count; idx++)
		{
			[points addObject:[[CLLocation alloc] initWithLatitude:coordinates[idx].latitude longitude:coordinates[idx].longitude]];
		}
	}
	
	return self;
}

- (CLLocationCoordinate2D) coordinate
{
	return [mapView centerCoordinate];
}

@end
