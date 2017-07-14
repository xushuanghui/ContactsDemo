//
//  ContactsHelp.m
//  ContactsDemo
//
//  Created by shuanghui xu on 2017/7/14.
//  Copyright © 2017年 shuanghui xu. All rights reserved.
//

#import "ContactsHelp.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <Contacts/Contacts.h>
#import <ContactsUI/ContactsUI.h>


#define iOS9 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0)

@interface ContactsHelp () <CNContactPickerDelegate, ABPeoplePickerNavigationControllerDelegate>
@property(nonatomic, strong) ContactsModel *contactModel;
@property(nonatomic, strong) ContactBlock myBlock;

@end

@implementation ContactsHelp

+ (NSMutableArray *)getAllPhoneInfo {
    return iOS9 ? [self getContactsFromContacts] : [self getContactsFromAddressBook];
}

- (void)getOnePhoneInfoWithUI:(UIViewController *)target callBack:(void (^)(ContactsModel *))block {
    if (iOS9) {
        [self getContactsFromContactUI:target];
    } else {
        [self getContactsFromAddressBookUI:target];
    }
    self.myBlock = block;
}

#pragma mark - AddressBookUI
- (void)getContactsFromAddressBookUI:(UIViewController *)target {
    ABPeoplePickerNavigationController *pickerVC = [[ABPeoplePickerNavigationController alloc] init];
    pickerVC.peoplePickerDelegate = self;
    [target presentViewController:pickerVC animated:YES completion:nil];
}

- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker didSelectPerson:(ABRecordRef)person {
    ABMultiValueRef phonesRef = ABRecordCopyValue(person, kABPersonPhoneProperty);
    if (!phonesRef) { return; }
    NSString *phoneValue = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phonesRef, 0);
    
    CFStringRef lastNameRef = ABRecordCopyValue(person, kABPersonLastNameProperty);
    CFStringRef firstNameRef = ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSString *lastname = (__bridge_transfer NSString *)(lastNameRef);
    NSString *firstname = (__bridge_transfer NSString *)(firstNameRef);
    NSString *name = [NSString stringWithFormat:@"%@%@", lastname == NULL ? @"" : lastname, firstname == NULL ? @"" : firstname];
    NSLog(@"姓名: %@", name);
    
    ContactsModel *model = [[ContactsModel alloc] initWithName:name num:phoneValue];
    NSLog(@"电话号码: %@", phoneValue);
    
    CFRelease(phonesRef);
    if (self.myBlock) self.myBlock(model);
}

#pragma mark - ContactsUI
- (void)getContactsFromContactUI:(UIViewController *)target {
    CNContactPickerViewController *pickerVC = [[CNContactPickerViewController alloc] init];
    pickerVC.delegate = self;
    [target presentViewController:pickerVC animated:YES completion:nil];
}

- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContact:(CNContact *)contact {
    NSString *name = [NSString stringWithFormat:@"%@%@", contact.familyName == NULL ? @"" : contact.familyName, contact.givenName == NULL ? @"" : contact.givenName];
    NSLog(@"姓名: %@", name);
    
    CNPhoneNumber *phoneNumber = [contact.phoneNumbers[0] value];
    ContactsModel *model = [[ContactsModel alloc] initWithName:name num:[NSString stringWithFormat:@"%@", phoneNumber.stringValue]];
    NSLog(@"电话号码: %@", phoneNumber.stringValue);
    
    if (self.myBlock) self.myBlock(model);
}

#pragma mark - AddressBook
+ (NSMutableArray *)getContactsFromAddressBook {
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    CFErrorRef myError = NULL;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &myError);
    if (myError) {
        [self showErrorAlert];
        if (addressBook) CFRelease(addressBook);
        return nil;
    }
    
    __block NSMutableArray *contactModels = [NSMutableArray array];
    if (status == kABAuthorizationStatusNotDetermined) {  // 用户还没有决定是否授权你的程序进行访问
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            if (granted) {
                contactModels = [self getAddressBookInfo:addressBook];
            } else {
                [self showErrorAlert];
                if (addressBook) CFRelease(addressBook);
            }
        });
        // 用户已拒绝 或 iOS设备上的家长控制或其它一些许可配置阻止程序与通讯录数据库进行交互
    } else if (status == kABAuthorizationStatusDenied || status == kABAuthorizationStatusRestricted) {
        [self showErrorAlert];
        if (addressBook) CFRelease(addressBook);
    } else if (status == kABAuthorizationStatusAuthorized) {  // 用户已授权
        contactModels = [self getAddressBookInfo:addressBook];
    }
    return contactModels;
}

+ (NSMutableArray *)getAddressBookInfo:(ABAddressBookRef)addressBook {
    CFArrayRef peopleArray = ABAddressBookCopyArrayOfAllPeople(addressBook);
    NSInteger peopleCount = CFArrayGetCount(peopleArray);
    NSMutableArray *contactModels = [NSMutableArray array];
    
    for (int i = 0; i < peopleCount; i++) {
        ABRecordRef person = CFArrayGetValueAtIndex(peopleArray, i);
        ABMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
        if (phones) {
            NSString *lastName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
            NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
            NSString *name = [NSString stringWithFormat:@"%@%@", lastName == NULL ? @"" : lastName, firstName == NULL ? @"" : firstName];
            NSLog(@"姓名: %@", name);
            
            CFIndex phoneCount = ABMultiValueGetCount(phones);
            for (int j = 0; j < phoneCount; j++) {
                NSString *phoneValue = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phones, j);
                NSLog(@"电话号码: %@", phoneValue);
                ContactsModel *model = [[ContactsModel alloc] initWithName:name num:phoneValue];
                [contactModels addObject:model];
            }
        }
        CFRelease(phones);
    }
    
    if (addressBook) CFRelease(addressBook);
    if (peopleArray) CFRelease(peopleArray);
    
    return contactModels;
}


#pragma mark - Contacts
+ (NSMutableArray *)getContactsFromContacts {
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    CNContactStore *store = [[CNContactStore alloc] init];
    __block NSMutableArray *contactModels = [NSMutableArray array];
    
    if (status == CNAuthorizationStatusNotDetermined) { // 用户还没有决定是否授权你的程序进行访问
        [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (granted) {
                contactModels = [self getContactsInfo:store];
            } else {
                [self showErrorAlert];
            }
        }];
        // 用户已拒绝 或 iOS设备上的家长控制或其它一些许可配置阻止程序与通讯录数据库进行交互
    } else if (status == CNAuthorizationStatusDenied || status == CNAuthorizationStatusRestricted) {
        [self showErrorAlert];
    } else if (status == CNAuthorizationStatusAuthorized) { // 用户已授权
        contactModels = [self getContactsInfo:store];
    }
    
    return contactModels;
}

+ (NSMutableArray *)getContactsInfo:(CNContactStore *)store {
    NSArray *keys = @[CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey];
    CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:keys];
    NSMutableArray *contactModels = [NSMutableArray array];
    
    [store enumerateContactsWithFetchRequest:request error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
        NSString *name = [NSString stringWithFormat:@"%@%@", contact.familyName == NULL ? @"" : contact.familyName, contact.givenName == NULL ? @"" : contact.givenName];
        NSLog(@"姓名: %@", name);
        
        for (CNLabeledValue *labeledValue in contact.phoneNumbers) {
            CNPhoneNumber *phoneNumber = labeledValue.value;
            NSLog(@"电话号码: %@", phoneNumber.stringValue);
            ContactsModel *model = [[ContactsModel alloc] initWithName:name num:phoneNumber.stringValue];
            [contactModels addObject:model];
        }
    }];
    
    return contactModels;
}

#pragma mark - Error
+ (void)showErrorAlert {
    NSLog(@"授权失败, 请允许app访问您的通讯录, 在手机的”设置-隐私-通讯录“选项中设置允许");
}


@end
