//
//  AppDelegate.m
//  Airport Power
//
//  Created by Avleen Vig on 3/21/13.
//  Copyright (c) 2013 WraithNet. All rights reserved.
//


#import "AppDelegate.h"
#import "AirportPower.h"
#import "ViewController.h"

#import <BugSense-iOS/BugSenseController.h>
#import <GoogleMaps/GoogleMaps.h>
#import "Reachability.h"

@implementation AppDelegate

static BOOL appserverReachable = NO;
Reachability *reach = nil;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    [GMSServices provideAPIKey:GOOGLE_API_KEY];
    [BugSenseController sharedControllerWithBugSenseAPIKey:BUGSENSE_API_KEY];

    [self generateUUID];

    // Initialise the data store
    [MagicalRecord setupCoreDataStack];
    
    // Initialise the reachability lib
    reach = [Reachability reachabilityWithHostname:@"airportpower.silverwraith.com"];
    
    // start the notifier which will cause the reachability object to retain itself!
    [reach startNotifier];


    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.viewController = [[ViewController alloc] initWithNibName:@"ViewController_iPhone" bundle:nil];
    } else {
        self.viewController = [[ViewController alloc] initWithNibName:@"ViewController_iPad" bundle:nil];
    }
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

-(NSString *)generateUUID
{
    NSString *UUID = [[NSUserDefaults standardUserDefaults] objectForKey:@"com.silverwraith.Airport-Power.uuid"];
    if (!UUID)
    {
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        CFStringRef string = CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
        UUID = [(__bridge NSString*)string stringByReplacingOccurrencesOfString:@"-" withString:@""];
        [[NSUserDefaults standardUserDefaults] setValue:UUID forKey:@"com.silverwraith.Airport-Power.uuid"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return UUID;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [MagicalRecord cleanUp];
    [reach stopNotifier];
}

@end
