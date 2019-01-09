//
//  ObjC.m
//  TelegramUI
//
//  Created by Dmitry Shelonin on 29/12/2018.
//  Copyright © 2018 Telegram. All rights reserved.
//

#import "ObjC.h"

@implementation ObjC
+ (BOOL)catchException:(void (^)())tryBlock error:(NSError * _Nullable __autoreleasing *)error {
    @try {
        tryBlock();
        return YES;
    } @catch (NSException *exception) {
        NSLog(@"EXCEPTION: %@", exception);
        *error = [NSError errorWithDomain:exception.name code:0 userInfo:exception.userInfo];
        return NO;
    }
}
@end
