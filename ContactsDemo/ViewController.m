//
//  ViewController.m
//  ContactsDemo
//
//  Created by shuanghui xu on 2017/7/14.
//  Copyright © 2017年 shuanghui xu. All rights reserved.
//

#import "ViewController.h"
#import "ContactsHelp.h"
#import "ContactsModel.h"

@interface ViewController ()

@property(nonatomic, strong) ContactsHelp *contactsHelp;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self btn_getAll];
}


- (IBAction)btn_getOne {
    self.contactsHelp = [[ContactsHelp alloc] init];
    [self.contactsHelp getOnePhoneInfoWithUI:self callBack:^(ContactsModel *contactModel) {
        NSLog(@"-----------");
        NSLog(@"%@", contactModel.name);
        NSLog(@"%@", contactModel.num);
    }];
}

- (IBAction)btn_getAll {
    NSMutableArray *contactModels = [ContactsHelp getAllPhoneInfo];
    if (contactModels.count > 0) {
        [contactModels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            ContactsModel *model = obj;
            NSLog(@"-----------");
            NSLog(@"%@", model.name);
            NSLog(@"%@", model.num);
        }];
    }
    
}

@end
