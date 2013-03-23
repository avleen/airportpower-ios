//
//  ViewController.m
//  Airport Power
//
//  Created by Avleen Vig on 3/21/13.
//  Copyright (c) 2013 WraithNet. All rights reserved.
//

#import "ViewController.h"

#import <GoogleMaps/GoogleMaps.h>
#import "KVStore.h"

@interface ViewController ()

@end

/* @implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
 */

@implementation ViewController {
    GMSMapView *mapView_;
    NSInteger zoomedOnce;
}

@synthesize locationManager, currentLocation, selectedMarker, mapView, toolbar;

// You don't need to modify the default initWithNibName:bundle: method.


-(void)viewDidLoad {
    // Initial welcome message
    [self welcomeMessage];
    
    // Turn on location stuff
    locationManager = [[CLLocationManager alloc] init];
    [locationManager setDelegate:self];
    [locationManager startUpdatingLocation];
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    
    // Ads stuff, loaded last.
    bannerView_ = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
    bannerView_.adUnitID = @"a1514566d702e35";
    bannerView_.rootViewController = self;
    [self.view addSubview:bannerView_];

    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:0.0
                                                            longitude:0.0
                                                                 zoom:3];
    // mapView_ = [[GMSMapView alloc] initWithFrame:mapView.bounds];
    mapView_ = [GMSMapView mapWithFrame:CGRectMake(0, 0, mapView.frame.size.width, mapView.bounds.size.height) camera:camera];
    mapView_.myLocationEnabled = YES;
    mapView_.delegate = self;
    [self.mapView addSubview: mapView_];
    [self GetAndDownloadMarkers];
    // Jump to the last known location, so that we don't just *sit* there.
    [self zoomToMyLocationWarn];
    
    [bannerView_ loadRequest:[GADRequest request]];
}


- (void)welcomeMessage {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"welcomeSeen==1"];
    NSNumber *resultNumber = [KVStore numberOfEntitiesWithPredicate:predicate];
    if ([resultNumber intValue] == 1) {
        return;
    }
    
    NSString *msg = @"Airport Power is a crowdsourced app!\n"
    "You'll notice that currently we don't list every power outlet.\n"
    "This app needs YOU to make it a success!\n\n"
    "When you're at an airport and see a power outlet, simply press the "
    "menu key, followed by the Submit Power Location button.\n"
    "You'll help other people find power, and their submissions will help you in return!\n\n"
    "Click \"Tweet This\" to let others know about this app!";
    [self makePopup:msg];
    KVStore *newKV = [KVStore createEntity];
    newKV.welcomeSeen = [NSNumber numberWithInt:[@"1" intValue]];
    [[NSManagedObjectContext defaultContext] MR_saveOnlySelfAndWait];
}

- (void)mapView_:(GMSMapView *)mapView_ didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    if (coordinate.longitude == currentLocation.coordinate.longitude &&
        coordinate.latitude == currentLocation.coordinate.latitude) {
        NSLog(@"Tapped current location");
    }
}

- (void)GetAndDownloadMarkers {
    // Default to Central Park, NY
    float lat = (currentLocation != nil) ? currentLocation.coordinate.latitude : 40.774875;
    float lng = (currentLocation != nil) ? currentLocation.coordinate.longitude : -73.970682;
    NSData *data = [NSData dataWithContentsOfURL:
                    [NSURL URLWithString:
                     [NSString stringWithFormat:@"http://airportpower.silverwraith.com/get_markers/?lat=%f&lng=%f",lat,lng]]];
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    for (NSDictionary *marker in json) {
        GMSMarkerOptions *mapoptions = [[GMSMarkerOptions alloc] init];
        float lat = [[marker objectForKey:@"lat"] floatValue];
        float lng = [[marker objectForKey:@"lng"] floatValue];
        integer_t marker_id  = [[marker objectForKey:@"marker_id"] integerValue];
        mapoptions.position = CLLocationCoordinate2DMake(lat, lng);
        mapoptions.title = [NSString stringWithFormat:@"%d", marker_id];
        [mapView_ addMarkerWithOptions:mapoptions];
    }

}

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(id<GMSMarker>)marker {
    selectedMarker = [marker title];
    NSString *actionSheetTitle = @"Is this power location still here?"; //Action Sheet Title
    NSString *itsgone = @"Nope, it's gone."; //Action Sheet Button Titles
    NSString *stillhere = @"Yes, still here!";
    NSString *cancelTitle = @"Cancel";
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:actionSheetTitle
                                  delegate:self
                                  cancelButtonTitle:cancelTitle
                                  destructiveButtonTitle:itsgone
                                  otherButtonTitles:stillhere, nil];
    [actionSheet showInView:self.view];

    return YES;
}

- (void)makePopup:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Airport Power"
                                                    message: message
                                                   delegate: self
                                          cancelButtonTitle:@"Ok!"
                                          otherButtonTitles:nil];
    [alert show];
    return;

}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    CLLocationDegrees lng = currentLocation.coordinate.longitude;
    CLLocationDegrees lat = currentLocation.coordinate.latitude;
    float accuracy = currentLocation.horizontalAccuracy;
    NSLog(@" Lng, Lat, Accuracy: %f, %f, %f", lng, lat, accuracy);
    NSString *UUID = [[NSUserDefaults standardUserDefaults] objectForKey:@"com.silverwraith.Airport-Power.uuid"];
    NSString *score;
    NSString *action;
    NSString *url;
    NSString *popupMsg;

    if([title isEqualToString:@"Cancel"]) {
        return;
    } else if ([title isEqualToString:@"Ok!"]) {
        return;
    } else if ([title isEqualToString:@"Nope, it's gone"]) {
        score = @"-1";
        action = @"update";
    } else if([title isEqualToString:@"Yes, still here!"]) {
        score = @"1";
        action = @"update";
    } else if ([title isEqualToString:@"Yes! There's power here!"]) {
        score = @"0";
        action = @"newlocation";
    } else {
        return;
    }
    
    if (action == @"update") {
        url = [NSString stringWithFormat:@"http://airportpower.silverwraith.com/marker_report/?lat=%f&lng=%f&deviceId=%@&regId=nokey&marker_id=%@&score=%@", lat,lng,UUID,selectedMarker,score];
        popupMsg = @"Thank you! Your vote has been counted.";
    } else if (action == @"newlocation") {
        url = [NSString stringWithFormat:@"http://airportpower.silverwraith.com/user_submit/?lat=%f&lng=%f&deviceId=%@&regId=nokey&accuracy=%f", lat,lng,UUID,accuracy];
        if (currentLocation.horizontalAccuracy > 5) {
            popupMsg = @"Thank you! Your GPS accuracy is currently %0.f meters. Your submission will be published shortly.";
        } else {
            popupMsg = @"Thank you! Your submission will be published shortly.";
        }
    } else {
        NSLog(@"Unknown action for action sheet delegate");
        return;
    }
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:0 timeoutInterval:5];
    NSURLResponse* response=nil;
    NSError* error=nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    [self makePopup:popupMsg];
    return;
}

- (IBAction)showActionSheet:(id)sender {
    NSString *actionSheetTitle = @"Really submit a new power outlet at your location?"; //Action Sheet Title
    NSString *powerhere = @"Yes! There's power here!"; //Action Sheet Button Titles
    NSString *cancelTitle = @"No, no power here";
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:actionSheetTitle
                                  delegate:self
                                  cancelButtonTitle:cancelTitle
                                  destructiveButtonTitle: nil
                                  otherButtonTitles: powerhere, nil];
    if (currentLocation == nil) {
        [self makePopup:@"Waiting for GPS location."];
    } else {
        [actionSheet showInView:self.view];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    //NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
}

- (void) zoomToMyLocationFoo {
    // Default to Central Park, NY
    float lat = (currentLocation != nil) ? currentLocation.coordinate.latitude : 40.774875;
    float lng = (currentLocation != nil) ? currentLocation.coordinate.longitude : -73.970682;
    [ mapView_ setCamera:[GMSCameraPosition cameraWithLatitude:lat
                                                     longitude:lng
                                                          zoom:13]];
}
- (IBAction) zoomToMyLocation:(id)sender {
    // Default to Central Park, NY
    float lat = (currentLocation != nil) ? currentLocation.coordinate.latitude : 40.774875;
    float lng = (currentLocation != nil) ? currentLocation.coordinate.longitude : -73.970682;
    if (currentLocation == nil) {
        [self makePopup:@"Waiting for GPS location. We'll jump to your location as soon as we get it. In the mean time, here's Central Park."];
    }
    [ mapView_ setCamera:[GMSCameraPosition cameraWithLatitude:lat
                                                     longitude:lng
                                                          zoom:13]];
}

- (void) zoomToMyLocationWarn {
    // Default to Central Park, NY
    float lat = (currentLocation != nil) ? currentLocation.coordinate.latitude : 40.774875;
    float lng = (currentLocation != nil) ? currentLocation.coordinate.longitude : -73.970682;
    if (currentLocation == nil) {
        [self makePopup:@"Waiting for GPS location. We'll jump to your location as soon as we get it. In the mean time, here's Central Park."];
    }
    [ mapView_ setCamera:[GMSCameraPosition cameraWithLatitude:lat
                                                     longitude:lng
                                                          zoom:13]];
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    NSLog(@"Location changed");
    self.currentLocation = newLocation;
    if (zoomedOnce != 1) {
        zoomedOnce = 1;
        [self zoomToMyLocationFoo];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if(error.code == kCLErrorDenied) {
        NSLog(@"Stopped getting location updates");
        [locationManager stopUpdatingLocation];
    } else if(error.code == kCLErrorLocationUnknown) {
        // retry
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error retrieving location"
                                                        message:[error description]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)viewDidUnload {
    toolbar = nil;
    mapView = nil;
    [self setSubmitButton:nil];
    [self setMyLocationButton:nil];
    [super viewDidUnload];
}
@end