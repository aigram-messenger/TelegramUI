//
//  ConvenientFunctions.swift
//  TelegramUI
//
//  Created by Valeriy Mikholapov on 04/04/2019.
//  Copyright © 2019 Telegram. All rights reserved.
//

@inlinable
@discardableResult
func with<T: AnyObject>(_ obj: T, _ closure: (T) -> Void) -> T {
    closure(obj)
    return obj
}
