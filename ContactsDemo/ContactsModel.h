//
//  ContactsModel.h
//  ContactsDemo
//
//  Created by shuanghui xu on 2017/7/14.
//  Copyright © 2017年 shuanghui xu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ContactsModel : NSObject

@property (nonatomic, copy) NSString *num;
@property (nonatomic, copy) NSString *name;

- (instancetype)initWithName:(NSString *)name num:(NSString *)num;


@end
