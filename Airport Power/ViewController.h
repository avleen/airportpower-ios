//
//  ViewController.h
//  Airport Power
//
//  Created by Avleen Vig on 3/21/13.
//  Copyright (c) 2013 WraithNet. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <GoogleMaps/GoogleMaps.h>
#import "GADBannerView.h"

@interface ViewController : UIViewController <UIAlertViewDelegate, UIActionSheetDelegate, GMSMapViewDelegate, CLLocationManagerDelegate> {
    IBOutlet UIToolbar *toolbar;
    IBOutlet GMSMapView *mapView;
    GADBannerView *bannerView_;
    CLLocationManager *locationManager;
}

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *currentLocation;
@property (strong, nonatomic) NSString *selectedMarker;
@property (strong, nonatomic) IBOutlet GMSMapView *mapView;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *submitButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *myLocationButton;


- (void)makePopup:(NSString *)message;
- (IBAction)showActionSheet:(id)sender;
- (IBAction)zoomToMyLocation:(id)sender;

@end
