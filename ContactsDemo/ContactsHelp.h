//
//  ContactsHelp.h
//  ContactsDemo
//
//  Created by shuanghui xu on 2017/7/14.
//  Copyright © 2017年 shuanghui xu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "ContactsModel.h"

typedef void(^ContactBlock)(ContactsModel *contactsModel);

@interface ContactsHelp : NSObject

+ (NSMutableArray *)getAllPhoneInfo;

- (void)getOnePhoneInfoWithUI:(UIViewController *)target callBack:(ContactBlock)block;

@end
