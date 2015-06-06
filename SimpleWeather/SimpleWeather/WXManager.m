//
//  WXManager.m
//  SimpleWeather
//
//  Created by peanut on 6/5/15.
//  Copyright (c) 2015 peanut. All rights reserved.
//

#import "WXManager.h"
#import "WXClient.h"
#import <TSMessages/TSMessage.h>

@interface WXManager ()

@property (nonatomic, strong, readwrite) CLLocation *currentLocation;
@property (nonatomic, strong, readwrite) WXCondition *currentCondition;
@property (nonatomic, strong, readwrite) NSArray *hourlyForecast;
@property (nonatomic, strong, readwrite) NSArray *dailyForecast;

@property (nonatomic, strong) CLLocationManager *locationManger;
@property (nonatomic, assign) BOOL isFirstUpdate;
@property (nonatomic, strong) WXClient *client;

@end

@implementation WXManager

+ (instancetype)sharedManager {
  static id _sharedManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedManager = [[self alloc] init];
  });
  
  return _sharedManager;
}

- (id)init {
  if (self = [super init]) {
    _locationManger = [[CLLocationManager alloc] init];
    _locationManger.delegate = self;
    [_locationManger requestWhenInUseAuthorization];
    
    _client = [[WXClient alloc] init];
    
    [[[[RACObserve(self, currentLocation)
        ignore:nil]
       flattenMap:^(CLLocation *newLocation) {
         return [RACSignal merge:@[
                                   [self updateCurrentConditions],
                                   [self updateDailyForecast],
                                   [self updateHourlyForecast],
                                   ]];
       }] deliverOn:RACScheduler.mainThreadScheduler]
     subscribeError:^(NSError *error){
       [TSMessage showNotificationWithTitle:@"Error"
                                   subtitle:@"There was a problem fetching the latest weather"
                                       type:TSMessageNotificationTypeError];
     }];
  }
  return self;
}

- (RACSignal *)updateCurrentConditions {
  return [[self.client fetchCurrentConditionsForLocation:self.currentLocation.coordinate]
          doNext:^(WXCondition *condition){
            
            self.currentCondition = condition;
          }];
}

- (RACSignal *)updateHourlyForecast {
  return [[self.client fetchHourlyForecastForLocation:self.currentLocation.coordinate]
          doNext:^(NSArray *conditions) {
            self.hourlyForecast = conditions;
          }];
}

- (RACSignal *)updateDailyForecast {
  return [[self.client fetchDailyForecastForLocation:self.currentLocation.coordinate]
          doNext:^(NSArray *conditions){
            self.dailyForecast = conditions;
          }];
}

- (void)findCurrentLocation {
  self.isFirstUpdate = YES;
  [self.locationManger startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
  if (self.isFirstUpdate) {
    self.isFirstUpdate = NO;
    return;
  }
  
  CLLocation *location = [locations lastObject];
  if (location.horizontalAccuracy > 0) {
    self.currentLocation = location;
    [self.locationManger stopUpdatingLocation];
  }
}



@end
