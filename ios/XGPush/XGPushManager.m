//
//  XGPushManager.m
//  参考了 react-native 官方 PushNotificationIOS 的代码
//  Created by Jeepeng on 16/8/5.
//  Copyright © 2016年 Jeepeng. All rights reserved.
//

#import "XGPushManager.h"
#import "XGPush.h"
#import "XGSetting.h"

#import <UserNotifications/UserNotifications.h>

#import <React/RCTBridge.h>
#import <React/RCTConvert.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTUtils.h>

NSString *const RCTLocalNotificationReceived = @"LocalNotificationReceived";
NSString *const RCTRemoteNotificationReceived = @"RemoteNotificationReceived";
NSString *const RCTRemoteNotificationsRegistered = @"RemoteNotificationsRegistered";
NSString *const RCTRegisterUserNotificationSettings = @"RegisterUserNotificationSettings";

NSString *const RCTErrorUnableToRequestPermissions = @"E_UNABLE_TO_REQUEST_PERMISSIONS";
NSString *const RCTErrorRemoteNotificationRegistrationFailed = @"E_FAILED_TO_REGISTER_FOR_REMOTE_NOTIFICATIONS";

#if !TARGET_OS_TV
@implementation RCTConvert (NSCalendarUnit)

RCT_ENUM_CONVERTER(NSCalendarUnit,
                   (@{
                      @"year": @(NSCalendarUnitYear),
                      @"month": @(NSCalendarUnitMonth),
                      @"week": @(NSCalendarUnitWeekOfYear),
                      @"day": @(NSCalendarUnitDay),
                      @"hour": @(NSCalendarUnitHour),
                      @"minute": @(NSCalendarUnitMinute)
                      }),
                   0,
                   integerValue)

@end

@interface XGPushManager ()
@property (nonatomic, strong) NSMutableDictionary *remoteNotificationCallbacks;
@end

@implementation RCTConvert (UILocalNotification)

+ (UILocalNotification *)UILocalNotification:(id)json
{
  NSDictionary<NSString *, id> *details = [self NSDictionary:json];
  UILocalNotification *notification = [UILocalNotification new];
  notification.fireDate = [RCTConvert NSDate:details[@"fireDate"]] ?: [NSDate date];
  notification.alertBody = [RCTConvert NSString:details[@"alertBody"]];
  notification.alertAction = [RCTConvert NSString:details[@"alertAction"]];
  notification.soundName = [RCTConvert NSString:details[@"soundName"]] ?: UILocalNotificationDefaultSoundName;
  notification.userInfo = [RCTConvert NSDictionary:details[@"userInfo"]];
  notification.category = [RCTConvert NSString:details[@"category"]];
  notification.repeatInterval = [RCTConvert NSCalendarUnit:details[@"repeatInterval"]];
  if (details[@"applicationIconBadgeNumber"]) {
    notification.applicationIconBadgeNumber = [RCTConvert NSInteger:details[@"applicationIconBadgeNumber"]];
  }
  return notification;
}

RCT_ENUM_CONVERTER(UIBackgroundFetchResult, (@{
  @"UIBackgroundFetchResultNewData": @(UIBackgroundFetchResultNewData),
  @"UIBackgroundFetchResultNoData": @(UIBackgroundFetchResultNoData),
  @"UIBackgroundFetchResultFailed": @(UIBackgroundFetchResultFailed),
}), UIBackgroundFetchResultNoData, integerValue)

@end
#endif //TARGET_OS_TV

@implementation XGPushManager
{
  RCTPromiseResolveBlock _requestPermissionsResolveBlock;
}

#if !TARGET_OS_TV

static NSDictionary *RCTFormatLocalNotification(UILocalNotification *notification)
{
  NSMutableDictionary *formattedLocalNotification = [NSMutableDictionary dictionary];
  if (notification.fireDate) {
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"];
    NSString *fireDateString = [formatter stringFromDate:notification.fireDate];
    formattedLocalNotification[@"fireDate"] = fireDateString;
  }
  formattedLocalNotification[@"alertAction"] = RCTNullIfNil(notification.alertAction);
  formattedLocalNotification[@"alertBody"] = RCTNullIfNil(notification.alertBody);
  formattedLocalNotification[@"applicationIconBadgeNumber"] = @(notification.applicationIconBadgeNumber);
  formattedLocalNotification[@"category"] = RCTNullIfNil(notification.category);
  formattedLocalNotification[@"soundName"] = RCTNullIfNil(notification.soundName);
  formattedLocalNotification[@"userInfo"] = RCTNullIfNil(RCTJSONClean(notification.userInfo));
  formattedLocalNotification[@"remote"] = @NO;
  return formattedLocalNotification;
}

static NSDictionary *RCTFormatUNNotification(UNNotification *notification)
{
  NSMutableDictionary *formattedNotification = [NSMutableDictionary dictionary];
  UNNotificationContent *content = notification.request.content;

  formattedNotification[@"identifier"] = notification.request.identifier;

  if (notification.date) {
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"];
    NSString *dateString = [formatter stringFromDate:notification.date];
    formattedNotification[@"date"] = dateString;
  }

  formattedNotification[@"title"] = RCTNullIfNil(content.title);
  formattedNotification[@"body"] = RCTNullIfNil(content.body);
  formattedNotification[@"category"] = RCTNullIfNil(content.categoryIdentifier);
  formattedNotification[@"thread-id"] = RCTNullIfNil(content.threadIdentifier);
  formattedNotification[@"userInfo"] = RCTNullIfNil(RCTJSONClean(content.userInfo));

  return formattedNotification;
}

#endif //TARGET_OS_TV

RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

#if !TARGET_OS_TV
- (void)startObserving
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleLocalNotificationReceived:)
                                               name:RCTLocalNotificationReceived
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleRemoteNotificationReceived:)
                                               name:RCTRemoteNotificationReceived
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleRemoteNotificationsRegistered:)
                                               name:RCTRemoteNotificationsRegistered
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleRemoteNotificationRegistrationError:)
                                               name:RCTErrorRemoteNotificationRegistrationFailed
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleRegisterUserNotificationSettings:)
                                               name:RCTRegisterUserNotificationSettings
                                             object:nil];
}

- (void)stopObserving
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"localNotificationReceived",
           @"remoteNotificationReceived",
           @"remoteNotificationsRegistered",
           @"remoteNotificationRegistrationError"];
}

+ (void)didRegisterUserNotificationSettings:(__unused UIUserNotificationSettings *)notificationSettings
{
  if ([UIApplication instancesRespondToSelector:@selector(registerForRemoteNotifications)]) {
    [RCTSharedApplication() registerForRemoteNotifications];
    [[NSNotificationCenter defaultCenter] postNotificationName:RCTRegisterUserNotificationSettings
                                                        object:self
                                                      userInfo:@{@"notificationSettings": notificationSettings}];
  }
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
  NSMutableString *hexString = [NSMutableString string];
  NSUInteger deviceTokenLength = deviceToken.length;
  const unsigned char *bytes = deviceToken.bytes;
  for (NSUInteger i = 0; i < deviceTokenLength; i++) {
    [hexString appendFormat:@"%02x", bytes[i]];
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:RCTRemoteNotificationsRegistered
                                                      object:self
                                                    userInfo:@{@"deviceToken" : [hexString copy]}];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
  [[NSNotificationCenter defaultCenter] postNotificationName:RCTErrorRemoteNotificationRegistrationFailed
                                                      object:self
                                                    userInfo:@{@"error": error}];
}

+ (void)didReceiveRemoteNotification:(NSDictionary *)notification
{
  NSDictionary *userInfo = @{@"notification": notification};
  [[NSNotificationCenter defaultCenter] postNotificationName:RCTRemoteNotificationReceived
                                                      object:self
                                                    userInfo:userInfo];
}

+ (void)didReceiveRemoteNotification:(NSDictionary *)notification
              fetchCompletionHandler:(RCTRemoteNotificationCallback)completionHandler
{
  NSDictionary *userInfo = @{@"notification": notification, @"completionHandler": completionHandler};
  [[NSNotificationCenter defaultCenter] postNotificationName:RCTRemoteNotificationReceived
                                                      object:self
                                                    userInfo:userInfo];
}

+ (void)didReceiveLocalNotification:(UILocalNotification *)notification
{
  [[NSNotificationCenter defaultCenter] postNotificationName:RCTLocalNotificationReceived
                                                      object:self
                                                    userInfo:RCTFormatLocalNotification(notification)];
}

- (void)handleLocalNotificationReceived:(NSNotification *)notification
{
  [self sendEventWithName:@"localNotificationReceived" body:notification.userInfo];
}

- (void)handleRemoteNotificationReceived:(NSNotification *)notification
{
  NSMutableDictionary *remoteNotification = [NSMutableDictionary dictionaryWithDictionary:notification.userInfo[@"notification"]];
  RCTRemoteNotificationCallback completionHandler = notification.userInfo[@"completionHandler"];
  NSString *notificationId = [[NSUUID UUID] UUIDString];
  remoteNotification[@"notificationId"] = notificationId;
  remoteNotification[@"remote"] = @YES;
  if (completionHandler) {
    if (!self.remoteNotificationCallbacks) {
      // Lazy initialization
      self.remoteNotificationCallbacks = [NSMutableDictionary dictionary];
    }
    self.remoteNotificationCallbacks[notificationId] = completionHandler;
  }

  [self sendEventWithName:@"remoteNotificationReceived" body:remoteNotification];
}

- (void)handleRemoteNotificationsRegistered:(NSNotification *)notification
{
  [self sendEventWithName:@"remoteNotificationsRegistered" body:notification.userInfo];
}

- (void)handleRemoteNotificationRegistrationError:(NSNotification *)notification
{
  NSError *error = notification.userInfo[@"error"];
  NSDictionary *errorDetails = @{
    @"message": error.localizedDescription,
    @"code": @(error.code),
    @"details": error.userInfo,
  };
  [self sendEventWithName:@"remoteNotificationRegistrationError" body:errorDetails];
}

- (void)handleRegisterUserNotificationSettings:(NSNotification *)notification
{
  if (_requestPermissionsResolveBlock == nil) {
    return;
  }

  UIUserNotificationSettings *notificationSettings = notification.userInfo[@"notificationSettings"];
  NSDictionary *notificationTypes = @{
    @"alert": @((notificationSettings.types & UIUserNotificationTypeAlert) > 0),
    @"sound": @((notificationSettings.types & UIUserNotificationTypeSound) > 0),
    @"badge": @((notificationSettings.types & UIUserNotificationTypeBadge) > 0),
  };

  _requestPermissionsResolveBlock(notificationTypes);
  _requestPermissionsResolveBlock = nil;
}

RCT_EXPORT_METHOD(onFinishRemoteNotification:(NSString *)notificationId fetchResult:(UIBackgroundFetchResult)result) {
  RCTRemoteNotificationCallback completionHandler = self.remoteNotificationCallbacks[notificationId];
  if (!completionHandler) {
    RCTLogError(@"There is no completion handler with notification id: %@", notificationId);
    return;
  }
  completionHandler(result);
  [self.remoteNotificationCallbacks removeObjectForKey:notificationId];
}

/**
 * Update the application icon badge number on the home screen
 */
RCT_EXPORT_METHOD(setApplicationIconBadgeNumber:(NSInteger)number)
{
  RCTSharedApplication().applicationIconBadgeNumber = number;
}

/**
 * Get the current application icon badge number on the home screen
 */
RCT_EXPORT_METHOD(getApplicationIconBadgeNumber:(RCTResponseSenderBlock)callback)
{
  callback(@[@(RCTSharedApplication().applicationIconBadgeNumber)]);
}

RCT_EXPORT_METHOD(requestPermissions:(NSDictionary *)permissions
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
  if (RCTRunningInAppExtension()) {
    reject(RCTErrorUnableToRequestPermissions, nil, RCTErrorWithMessage(@"Requesting push notifications is currently unavailable in an app extension"));
    return;
  }

  if (_requestPermissionsResolveBlock != nil) {
    RCTLogError(@"Cannot call requestPermissions twice before the first has returned.");
    return;
  }

  _requestPermissionsResolveBlock = resolve;

  UIUserNotificationType types = UIUserNotificationTypeNone;
  if (permissions) {
    if ([RCTConvert BOOL:permissions[@"alert"]]) {
      types |= UIUserNotificationTypeAlert;
    }
    if ([RCTConvert BOOL:permissions[@"badge"]]) {
      types |= UIUserNotificationTypeBadge;
    }
    if ([RCTConvert BOOL:permissions[@"sound"]]) {
      types |= UIUserNotificationTypeSound;
    }
  } else {
    types = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
  }

  UIUserNotificationSettings *notificationSettings =
    [UIUserNotificationSettings settingsForTypes:types categories:nil];
  [RCTSharedApplication() registerUserNotificationSettings:notificationSettings];
}

RCT_EXPORT_METHOD(abandonPermissions)
{
  [RCTSharedApplication() unregisterForRemoteNotifications];
}

RCT_EXPORT_METHOD(checkPermissions:(RCTResponseSenderBlock)callback)
{
  if (RCTRunningInAppExtension()) {
    callback(@[@{@"alert": @NO, @"badge": @NO, @"sound": @NO}]);
    return;
  }

  NSUInteger types = [RCTSharedApplication() currentUserNotificationSettings].types;
  callback(@[@{
    @"alert": @((types & UIUserNotificationTypeAlert) > 0),
    @"badge": @((types & UIUserNotificationTypeBadge) > 0),
    @"sound": @((types & UIUserNotificationTypeSound) > 0),
  }]);
}

RCT_EXPORT_METHOD(presentLocalNotification:(UILocalNotification *)notification)
{
  [RCTSharedApplication() presentLocalNotificationNow:notification];
}

RCT_EXPORT_METHOD(scheduleLocalNotification:(UILocalNotification *)notification)
{
  [RCTSharedApplication() scheduleLocalNotification:notification];
}

RCT_EXPORT_METHOD(cancelAllLocalNotifications)
{
  [RCTSharedApplication() cancelAllLocalNotifications];
}

RCT_EXPORT_METHOD(cancelLocalNotifications:(NSDictionary<NSString *, id> *)userInfo)
{
  for (UILocalNotification *notification in RCTSharedApplication().scheduledLocalNotifications) {
    __block BOOL matchesAll = YES;
    NSDictionary<NSString *, id> *notificationInfo = notification.userInfo;
    // Note: we do this with a loop instead of just `isEqualToDictionary:`
    // because we only require that all specified userInfo values match the
    // notificationInfo values - notificationInfo may contain additional values
    // which we don't care about.
    [userInfo enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
      if (![notificationInfo[key] isEqual:obj]) {
        matchesAll = NO;
        *stop = YES;
      }
    }];
    if (matchesAll) {
      [RCTSharedApplication() cancelLocalNotification:notification];
    }
  }
}

RCT_EXPORT_METHOD(getInitialNotification:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject)
{
  NSMutableDictionary<NSString *, id> *initialNotification =
    [self.bridge.launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] mutableCopy];

  UILocalNotification *initialLocalNotification =
    self.bridge.launchOptions[UIApplicationLaunchOptionsLocalNotificationKey];

  if (initialNotification) {
    initialNotification[@"remote"] = @YES;
    resolve(initialNotification);
  } else if (initialLocalNotification) {
    resolve(RCTFormatLocalNotification(initialLocalNotification));
  } else {
    resolve((id)kCFNull);
  }
}

RCT_EXPORT_METHOD(getScheduledLocalNotifications:(RCTResponseSenderBlock)callback)
{
  NSArray<UILocalNotification *> *scheduledLocalNotifications = RCTSharedApplication().scheduledLocalNotifications;
  NSMutableArray<NSDictionary *> *formattedScheduledLocalNotifications = [NSMutableArray new];
  for (UILocalNotification *notification in scheduledLocalNotifications) {
    [formattedScheduledLocalNotifications addObject:RCTFormatLocalNotification(notification)];
  }
  callback(@[formattedScheduledLocalNotifications]);
}

RCT_EXPORT_METHOD(removeAllDeliveredNotifications)
{
  if ([UNUserNotificationCenter class]) {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center removeAllDeliveredNotifications];
  }
}

RCT_EXPORT_METHOD(removeDeliveredNotifications:(NSArray<NSString *> *)identifiers)
{
  if ([UNUserNotificationCenter class]) {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center removeDeliveredNotificationsWithIdentifiers:identifiers];
  }
}

RCT_EXPORT_METHOD(getDeliveredNotifications:(RCTResponseSenderBlock)callback)
{
  if ([UNUserNotificationCenter class]) {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> *_Nonnull notifications) {
      NSMutableArray<NSDictionary *> *formattedNotifications = [NSMutableArray new];

      for (UNNotification *notification in notifications) {
        [formattedNotifications addObject:RCTFormatUNNotification(notification)];
      }
      callback(@[formattedNotifications]);
    }];
  }
}

/********************* 信鸽 *********************/

/**
 在didFinishLaunchingWithOptions中调用，用于推送反馈.(app没有运行时，点击推送启动时)
 
 @param launchOptions didFinishLaunchingWithOptions中的userinfo参数
 @param successCallback 成功回调
 @param errorCallback 失败回调
 */
+(void)handleLaunching:(nonnull NSDictionary *)launchOptions successCallback:(nullable void (^)(void)) successCallback errorCallback:(nullable void (^)(void)) errorCallback
{
    [XGPush handleLaunching:launchOptions successCallback:successCallback errorCallback:errorCallback];
}

/**
 * 在didReceiveRemoteNotification中调用，用于推送反馈。(app在运行时)
 */
+(void)handleReceiveNotification:(nonnull NSDictionary *)userInfo successCallback:(nullable void (^)(void)) successCallback errorCallback:(nullable void (^)(void)) errorCallback
{
    [XGPush handleReceiveNotification:userInfo successCallback:successCallback errorCallback:errorCallback];
}

/**
 * 打开 Debug 模式以后可以在终端看到详细的信鸽 Debug 信息.方便定位问题
 */
RCT_EXPORT_METHOD(enableDebug:(BOOL)isDebug)
{
    XGSetting *setting = [XGSetting getInstance];
    [setting enableDebug:isDebug];
}

/**
 * 查看debug开关是否打开
 */
RCT_EXPORT_METHOD(isEnableDebug:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    XGSetting *setting = [XGSetting getInstance];
    BOOL isDebug = [setting isEnableDebug];
    resolve(@(isDebug));
}

/**
 * 初始化信鸽
 * @param appId - 通过前台申请的accessId
 * @param appKey - 通过前台申请的accessKey
 * @return none
 */
RCT_EXPORT_METHOD(startApp:(uint64_t)accessId accessKey:(nonnull NSString *)accessKey)
{
    [XGPush startApp:accessId appKey:accessKey];
}

/**
 判断当前是否是已注销状态
 
 @return 是否已经注销推送
 */
RCT_EXPORT_METHOD(isUnRegisterStatus:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    BOOL isUnRegister = [XGPush isUnRegisterStatus];
    resolve(@(isUnRegister));
}

/**
 查询推送是否打开(以弹窗为准)
 
 @param result 查询回调.若推送打开,回调参数为 YES, 否则为 NO
 */
RCT_EXPORT_METHOD(isPushOn:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    [XGPush isPushOn:^(BOOL isOn) {
        NSLog(@"[XGPush] Push Is %@", isOn ? @"ON" : @"OFF");
        resolve(@(isOn));
    }];
}

/**
 注册设备并且设置账号
 
 @param deviceToken 通过app delegate的didRegisterForRemoteNotificationsWithDeviceToken回调的获取
 @param account 需要设置的账号,长度为2个字节以上，不要使用"test","123456"这种过于简单的字符串,
 若不想设置账号,请传入nil
 @param successCallback 成功回调
 @param errorCallback 失败回调
 @return  获取的 deviceToken 字符串
 */
RCT_EXPORT_METHOD(registerDevice:(nonnull NSString *) deviceToken account:(nullable NSString *)account resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    void (^successBlock)(void) = ^(void){
        resolve(@"信鸽推送注册成功！");
    };
    
    void (^errorBlock)(void) = ^(void){
        reject(@"XGPUSH_REGISTER_ERROR", @"信鸽推送注册失败.", nil);
    };
    
    //注册设备
    [XGPush registerDeviceStr:deviceToken account:account successCallback:successBlock errorCallback:errorBlock];
}

/**
 注销设备，设备不再进行推送
 
 @param successCallback 成功回调
 @param errorCallback 失败回调
 */
RCT_EXPORT_METHOD(unRegisterDevice:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    void (^successBlock)(void) = ^(void){
        resolve(@"注销设备成功！");
    };
    
    void (^errorBlock)(void) = ^(void){
        reject(@"XGPUSH_UNREGISTER_DEVICE_FAIL",@"注销设备失败!",nil);
    };
    
    [XGPush unRegisterDevice:successBlock errorCallback:errorBlock];
}

/**
 设置设备的帐号. 设置账号前需要调用一次registerDevice
 
 @param account 需要设置的账号,长度为2个字节以上，不要使用"test","123456"这种过于简单的字符串,
 若不想设置账号,请传入nil
 @param successCallback 成功回调
 @param errorCallback 失败回调
 */
RCT_EXPORT_METHOD(setAccount:(nonnull NSString *)account resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    void (^successBlock)(void) = ^(void){
        resolve(@"设置设备的帐号成功！");
    };
    
    void (^errorBlock)(void) = ^(void){
        reject(@"XGPUSH_SET_ACCOUNT_FAIL", @"设置设备的帐号失败.", nil);
    };
    
    [XGPush setAccount:account successCallback:successBlock errorCallback:errorBlock];
}


/**
 删除已经设置的账号
 
 @param successCallback 成功回调
 @param errorCallback 失败回调
 */
RCT_EXPORT_METHOD(delAccount:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    void (^successBlock)(void) = ^(void){
        resolve(@"删除已经设置的账号成功！");
    };
    
    void (^errorBlock)(void) = ^(void){
        reject(@"XGPUSH_DELETE_ACCOUNT_FAIL", @"删除已经设置的账号失败.", nil);
    };
    // 设置账号,要在注册设备之前完成
    [XGPush delAccount:successBlock errorCallback:errorBlock];
}

/**
 设置 tag
 
 @param tag 需要设置的 tag
 @param successCallback  成功回调
 @param errorCallback 失败回调
 */
RCT_EXPORT_METHOD(setTag:(NSString *)tagName resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    void (^successBlock)(void) = ^(void){
        resolve(@"设置Tag成功！");
    };
    
    void (^errorBlock)(void) = ^(void){
        reject(@"XGPUSH_SET_TAG_FAIL",@"设置Tag失败!",nil);
    };
    [XGPush setTag:tagName successCallback:successBlock errorCallback:errorBlock];
}

/**
 删除tag
 
 @param tag 需要删除的 tag
 @param successCallback  成功回调
 @param errorCallback 失败回调
 */
RCT_EXPORT_METHOD(delTag:(NSString *)tagName resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    void (^successBlock)(void) = ^(void){
        resolve(@"删除Tag成功！");
    };
    
    void (^errorBlock)(void) = ^(void){
        reject(@"XGPUSH_DELETE_TAG_FAIL",@"删除Tag失败!",nil);
    };
    
    [XGPush delTag:tagName successCallback:successBlock errorCallback:errorBlock];
}

#else //TARGET_OS_TV

- (NSArray<NSString *> *)supportedEvents
{
  return @[];
}

#endif //TARGET_OS_TV

@end
