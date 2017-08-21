//
//  AppDelegate.m
//  airBean
//
//  Created by predator on 17/5/5.
//  Copyright © 2017年 predator. All rights reserved.
//

#import "AppDelegate.h"
#import "AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"
#import <UMengSocial/UMSocial.h>
#import <UMengSocial/UMSocialWechatHandler.h>
#import <UMengSocial/UMSocialQQHandler.h>
#import "AFNetworking.h"
#import "MobClick.h"
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapLocationKit/AMapLocationKit.h>
#import "SVProgressHUD.h"
#import "UIImageView+WebCache.h"
#import "ViewController.h"
#import <ShareSDK/ShareSDK.h>
#import <ShareSDKConnector/ShareSDKConnector.h>
//腾讯开放平台（对应QQ和QQ空间）SDK头文件
#import <TencentOpenAPI/TencentOAuth.h>
#import <TencentOpenAPI/QQApiInterface.h>
#import "WXApi.h"
#import "WeiboSDK.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //网络
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    //sd加载的数据类型
    [[[SDWebImageManager sharedManager] imageDownloader] setValue:@"text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" forHTTPHeaderField:@"Accept"];
    
    
    [MobClick startWithAppkey:kUmeng_AppKey reportPolicy:BATCH channelId:nil];
    [[AMapServices sharedServices] setEnableHTTPS:YES];
    [AMapServices sharedServices].apiKey =mapServiceKey;
    
    //初始化share sdk分享
    
    [ShareSDK registerActivePlatforms:@[
                                        @(SSDKPlatformTypeSinaWeibo),
                                        @(SSDKPlatformTypeWechat),
                                        @(SSDKPlatformTypeQQ),
                                        ]
        onImport:^(SSDKPlatformType platformType){
         switch (platformType){
             case SSDKPlatformTypeWechat:
                 [ShareSDKConnector connectWeChat:[WXApi class]];
                 break;
             case SSDKPlatformTypeQQ:
                 [ShareSDKConnector connectQQ:[QQApiInterface class] tencentOAuthClass:[TencentOAuth class]];
                 break;
             case SSDKPlatformTypeSinaWeibo:
                 [ShareSDKConnector connectWeibo:[WeiboSDK class]];
                 break;
             default:
                 break;
         }
     }
        onConfiguration:^(SSDKPlatformType platformType, NSMutableDictionary *appInfo)
     {
         switch (platformType)
         {
             case SSDKPlatformTypeSinaWeibo:
                 //设置新浪微博应用信息,其中authType设置为使用SSO＋Web形式授权
                 [appInfo SSDKSetupSinaWeiboByAppKey:@"3238753656"
                                           appSecret:@"13710a6dddfe2a63b646fc23bf1b8829"
                                         redirectUri:@"http://www.hainiutech.com"
                                            authType:SSDKAuthTypeBoth];
                 break;
             case SSDKPlatformTypeWechat:
                 [appInfo SSDKSetupWeChatByAppId:@"wx4ac80c79e77d7f5b"
                                       appSecret:@"8b6c14ae810c4a69530fa271de057088"];
                 break;
             case SSDKPlatformTypeQQ:
                 [appInfo SSDKSetupQQByAppId:@"1106285627"
                                      appKey:@"rZOjdyErkT1gR2Ov"
                                    authType:SSDKAuthTypeBoth];
                 break;
            default:
                   break;
        }
    }];
//    ViewController *vc = [[ViewController alloc]init];
//    UINavigationController *navi = [[UINavigationController alloc]initWithRootViewController:vc];
//   
//    //设置NavigationBar背景颜色
////     [[UINavigationBar appearance] setBarTintColor:[UIColor blueColor]];
////    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
//    self.window.rootViewController = navi;
//    [self.window makeKeyAndVisible];
    return YES;
}


- (void)completionStartAnimationWithOptions:(NSDictionary *)launchOptions{
   
    //    UMENG 统计
    [MobClick startWithAppkey:kUmeng_AppKey reportPolicy:BATCH channelId:nil];
    
    
    
    }


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
