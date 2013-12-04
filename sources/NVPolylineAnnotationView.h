//
//  NVPolylineAnnotationView.h
//  CineQuest
//
//  Created by Luca Severini on 12-03-2013.
//  Derived from code written by William Lachance, Craig Spitzkoff and Nicolas Neubauer.
//

#import "NVPolylineAnnotation.h"


@interface NVPolylineAnnotationView : MKAnnotationView
{
	MKMapView * _mapView;
	UIView * _internalView;
}

@property (nonatomic, assign) CGPoint centerOffset;

- (id) initWithAnnotation:(NVPolylineAnnotation*)annotation mapView:(MKMapView*)mapView;

@end
