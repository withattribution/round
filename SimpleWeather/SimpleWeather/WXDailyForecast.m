//
//  WXDailyForecast.m
//  SimpleWeather
//
//  Created by peanut on 6/5/15.
//  Copyright (c) 2015 peanut. All rights reserved.
//

#import "WXDailyForecast.h"

@implementation WXDailyForecast

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  NSMutableDictionary *paths = [[super JSONKeyPathsByPropertyKey] mutableCopy];
  paths[@"tempHigh"] = @"temp.max";
  paths[@"tempLow"] = @"temp.min";
  return paths;
}

@end
