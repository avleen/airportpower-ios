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
//    NSInteger zoomedOnce;
    KVStore *persistentData;
}

@synthesize locationManager, currentLocation, selectedMarker,
            mapView, toolbar;

const NSString *actionUpdate = @"update";
const NSString *actionNewLocation = @"newLocation";

-(void)viewDidLoad {
    
    // Set up our KVStore if needed
    //
    NSUInteger count = [KVStore countOfEntities];
    if (count != 1) {
        KVStore *newKV = [KVStore createEntity];
        newKV.welcomeSeen = [NSNumber numberWithInt:0];
        newKV.lastCameraPosition = @"";
        [[NSManagedObjectContext defaultContext] MR_saveOnlySelfAndWait];
    }
    persistentData = [KVStore MR_findFirst];

    // Initial welcome message
    [self welcomeMessage];
    
    [bannerView setAdSize:kGADAdSizeBanner];
    [bannerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    bannerView.adUnitID = @"a1514566d702e35";
    bannerView.rootViewController = self;
    
    GMSCameraPosition *camera = self.lastKnownCameraPosition;
    if (camera == nil) {
        camera = [GMSCameraPosition cameraWithLatitude:0.0
                                             longitude:0.0
                                                  zoom:3.0];
    }
    [mapView setCamera:camera];
    [mapView setMyLocationEnabled:YES];
    [mapView setDelegate:self];

    [self GetAndDownloadMarkers];

    // Turn on location stuff
    locationManager = [[CLLocationManager alloc] init];
    [locationManager setDelegate:self];
    [locationManager startUpdatingLocation];
    locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;

    [bannerView loadRequest:[GADRequest request]];
}

- (void)welcomeMessage {

    if ([persistentData.welcomeSeen integerValue] == 1) {
        return;
    }
    
    [self makePopup:NSLocalizedString(@"welcome_message", nil)];
        
    persistentData.welcomeSeen = [NSNumber numberWithInt:1];
    [[NSManagedObjectContext defaultContext] MR_saveOnlySelfAndWait];
}

- (GMSCameraPosition *)lastKnownCameraPosition {

    CGFloat lat, lon, zoom;
    
    if (persistentData.lastCameraPosition == nil) {
        return nil;
    }
    
    NSArray *posData = [persistentData.lastCameraPosition componentsSeparatedByString:@"|"];
    if ([posData count] != 3) {
        return nil;
    }
    
    lat = [[posData objectAtIndex:0] floatValue];
    lon = [[posData objectAtIndex:1] floatValue];
    zoom = [[posData objectAtIndex:2] floatValue];
    
    return [GMSCameraPosition cameraWithLatitude:lat
                                       longitude:lon
                                            zoom:zoom];
}


- (void)saveCameraPosition {
    GMSCameraPosition *camera = [mapView camera];

    NSString *serializedPosition = [NSString stringWithFormat:@"%f|%f|%f",
                                    camera.target.latitude, camera.target.longitude, camera.zoom];
    persistentData.lastCameraPosition = serializedPosition;
    [[NSManagedObjectContext defaultContext] MR_saveOnlySelfAndWait];
}

- (void)mapView:(GMSMapView *)mapView didChangeCameraPosition:(GMSCameraPosition *)position {
    [self saveCameraPosition];
    NSLog(@"Saving camera location");
}

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    if (coordinate.longitude == currentLocation.coordinate.longitude &&
        coordinate.latitude == currentLocation.coordinate.latitude) {
        NSLog(@"Tapped current location");
    }

}

- (void)GetAndDownloadMarkers {
    
    static UIImage *greenMarker = nil;

    
    if (greenMarker == nil) {
        greenMarker = [UIImage imageNamed:@"green_marker.png"];
    }
    
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
        if (greenMarker != nil) {
            mapoptions.icon = greenMarker;
        }
        [mapView addMarkerWithOptions:mapoptions];
    }

}

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(id<GMSMarker>)marker {
    selectedMarker = [marker title];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:NSLocalizedString(@"still_here", nil)
                                  delegate:self
                                  cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                                  destructiveButtonTitle:NSLocalizedString(@"power_gone", nil)
                                  otherButtonTitles:NSLocalizedString(@"power_still_here", nil), nil];
    [actionSheet showInView:self.view];

    return YES;
}

- (void)makePopup:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"app_name", nil)
                                                    message: message
                                                   delegate: self
                                          cancelButtonTitle: NSLocalizedString(@"ok", nil)
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
    NSString *url;
    NSString *popupMsg;
    const NSString *action;

    if([title isEqualToString:NSLocalizedString(@"cancel", nil)]) {
        return;
    } else if ([title isEqualToString:NSLocalizedString(@"ok", nil)]) {
        return;
    } else if ([title isEqualToString:NSLocalizedString(@"power_gone", nil)]) {
        score = @"-1";
        action = actionUpdate;
    } else if([title isEqualToString:NSLocalizedString(@"power_still_here", nil)]) {
        score = @"1";
        action = actionUpdate;
    } else if ([title isEqualToString:NSLocalizedString(@"submit_yes", nil)]) {
        score = @"0";
        action = actionNewLocation;
    } else {
        return;
    }
    
    if (action == actionUpdate) {
        url = [NSString stringWithFormat:@"http://airportpower.silverwraith.com/marker_report/?lat=%f&lng=%f&deviceId=%@&regId=nokey&marker_id=%@&score=%@", lat,lng,UUID,selectedMarker,score];
        popupMsg = NSLocalizedString(@"thanks_vote", nil);
    } else if (action == actionNewLocation) {
        url = [NSString stringWithFormat:@"http://airportpower.silverwraith.com/user_submit/?lat=%f&lng=%f&deviceId=%@&regId=nokey&accuracy=%f", lat,lng,UUID,accuracy];
        if (currentLocation.horizontalAccuracy > 5) {
            popupMsg = NSLocalizedString(@"thanks_accuracy", nil);
        } else {
            popupMsg = NSLocalizedString(@"thanks", nil);
        }
    } else {
        NSLog(@"Unknown action for action sheet delegate");
        return;
    }
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:0 timeoutInterval:5];
    NSURLResponse *response = nil;
    NSError *error = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    [self makePopup:popupMsg];
    return;
}

- (IBAction)showActionSheet:(id)sender {

    if (currentLocation == nil) {
        [self makePopup:NSLocalizedString(@"waiting_gps", nil)];
        return;
    }
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:NSLocalizedString(@"submit_title", nil)
                                  delegate:self
                                  cancelButtonTitle:NSLocalizedString(@"submit_no", nil)
                                  destructiveButtonTitle: nil
                                  otherButtonTitles: NSLocalizedString(@"submit_yes", nil), nil];
        
    [actionSheet showInView:self.view];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    //NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
}

- (IBAction) zoomToMyLocation:(id)sender {
    // Default to Central Park, NY
    float lat = (currentLocation != nil) ? currentLocation.coordinate.latitude : 40.774875;
    float lng = (currentLocation != nil) ? currentLocation.coordinate.longitude : -73.970682;
    if (currentLocation == nil) {
        [self makePopup:NSLocalizedString(@"still_waiting_gps", nil)];
    }
    [mapView setCamera:[GMSCameraPosition cameraWithLatitude:lat
                                                     longitude:lng
                                                          zoom:13]];
    
    [self saveCameraPosition];
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    NSLog(@"Location changed");
    self.currentLocation = newLocation;
    
    // Replaced this in lieu of saved position
    //
    //    if (zoomedOnce != 1) {
    //        zoomedOnce = 1;
    //        [self zoomToMyLocation:self];
    //    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if(error.code == kCLErrorDenied) {
        NSLog(@"Stopped getting location updates");
        [locationManager stopUpdatingLocation];
    } else if(error.code == kCLErrorLocationUnknown) {
        // retry
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"error_gps", nil)
                                                        message:[error description]
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"ok", nil)
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