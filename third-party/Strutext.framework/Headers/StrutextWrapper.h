//
//  Strutext.h
//  strutext-ios
//
//  Created by Dmitry Shelonin on 20/12/2018.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Strutext : NSObject
+ (void)configure;
/**
 Обрабатывает входящий набор слов и возвращает для них множества лемм

 @param words входящие нелемматизированные слова
 @return массив множеств лемм для переданных слов
 */
- (NSArray<NSSet<NSString *> *> *)handle:(NSArray<NSString *> *)words;
@end

NS_ASSUME_NONNULL_END
