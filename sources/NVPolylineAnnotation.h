//
//  NVPolylineAnnotation.h
//  CineQuest
//
//  Created by Luca Severini on 12-03-2013.
//  Derived from code written by William Lachance, Craig Spitzkoff and Nicolas Neubauer.
//


@interface NVPolylineAnnotation : NSObject<MKAnnotation>

- (id) initWithCoordinates:(CLLocationCoordinate2D*)coordinates count:(NSInteger)count mapView:(MKMapView*)theMapView;

@property (nonatomic, strong) NSMutableArray* points;
@property (nonatomic, strong) MKMapView* mapView;

@end
