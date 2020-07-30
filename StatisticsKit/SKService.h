//
//  SKService.h
//  StatisticsKit
//
//  Created by MAN on 2020/7/10.
//  Copyright © 2020 iOS. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SKService : NSObject

+ (BOOL)startKitWithServer:(NSString *)server storeUrl:(NSString *)store option:(NSDictionary *)option;

@end

NS_ASSUME_NONNULL_END
