//
//  ContactsModel.m
//  ContactsDemo
//
//  Created by shuanghui xu on 2017/7/14.
//  Copyright © 2017年 shuanghui xu. All rights reserved.
//

#import "ContactsModel.h"

@implementation ContactsModel

- (instancetype)initWithName:(NSString *)name num:(NSString *)num {
    if (self = [super init]) {
        self.name = name;
        self.num = num;
    }
    return self;
}

@end
