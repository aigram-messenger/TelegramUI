//
//  ObjC.h
//  TelegramUI
//
//  Created by Dmitry Shelonin on 29/12/2018.
//  Copyright © 2018 Telegram. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ObjC : NSObject
+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error;
@end

NS_ASSUME_NONNULL_END
