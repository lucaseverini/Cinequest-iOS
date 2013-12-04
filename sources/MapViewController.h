//
//  MapViewController.h
//  Cinequest
//
//  Created by Luca Severini on 12/2/13.
//  Copyright (c) 2013 San Jose State University. All rights reserved.
//

@class Venue;
@class MKMapView;
@class MKPlacemark;
@class MKPointAnnotation;

@interface MapViewController : UIViewController <MKMapViewDelegate>
{
	NSArray *routes;
}

@property (nonatomic, strong) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *openInMapsBtn;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *directionsBtn;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *trackingBtn;
@property (nonatomic, strong) IBOutlet UIToolbar *bottomBar;

@property (nonatomic, strong) Venue *venue;
@property (nonatomic, strong) MKMapItem *mapItem;
@property (nonatomic, strong) MKPlacemark *placemark;
@property (nonatomic, strong) MKPointAnnotation *venueAnnotation;
@property (nonatomic, assign) BOOL showRouteInOverlayOrAnnotation;	// Show route in overlay or in annotation

- (IBAction) openInMaps:(id)sender;
- (IBAction) directions:(id)sender;

- (id) initWithNibName:(NSString*)nibName andVenue:(Venue*)theVenue;

@end
