//
//  ViewController.m
//  significant
//
//  Created by Antoine d'Otreppe - Movify on 17/10/14.
//  Copyright (c) 2014 Aspyct. All rights reserved.
//

#import "ViewController.h"

@import CoreLocation;
@import MapKit;

@interface ViewController () <CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *map;
@property CLLocationManager *locationManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    [self.locationManager requestAlwaysAuthorization];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.locationManager requestAlwaysAuthorization];
    
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [documentPaths objectAtIndex:0];
    NSString *logPath = [[NSString alloc] initWithFormat:@"%@",[documentsDir stringByAppendingPathComponent:@"points.csv"]];
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:logPath];
    
    if (fileHandle == nil) {
        return;
    }
    
    NSData *data = [fileHandle readDataToEndOfFile];
    NSString *dataAsString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *lines = [dataAsString componentsSeparatedByString:@"\n"];
    
    for (NSString *line in lines) {
        NSArray *numbers = [line componentsSeparatedByString:@","];
        
        if (numbers.count == 3) {
            double latitude = ((NSString *)numbers[0]).doubleValue;
            double longitude = ((NSString *)numbers[1]).doubleValue;
            
            MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
            point.coordinate = CLLocationCoordinate2DMake(latitude, longitude);
            point.title = numbers[2];
            
            [self.map addAnnotation:point];
        }
        else {
            NSLog(@"Invalid line");
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Could not get location: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    for (CLLocation *location in locations) {
        [self recordLocation:location];
    }
}

- (void)recordLocation:(CLLocation *)location
{
    NSString *text = [NSString stringWithFormat:@"%f,%f,%f\n", location.coordinate.latitude, location.coordinate.longitude, location.timestamp.timeIntervalSince1970];
    
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [documentPaths objectAtIndex:0];
    NSString *logPath = [[NSString alloc] initWithFormat:@"%@",[documentsDir stringByAppendingPathComponent:@"points.csv"]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:logPath]) {
        [[NSFileManager defaultManager] createFileAtPath:logPath contents:nil attributes:nil];
    }
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logPath];
    
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[text dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle closeFile];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        [self.locationManager startMonitoringSignificantLocationChanges];
    }
    else {
        NSLog(@"Please accept location tracking");
    }
}

@end
