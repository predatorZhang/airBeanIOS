//
//  ViewController.h
//  airBean
//
//  Created by predator on 17/5/5.
//  Copyright © 2017年 predator. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BabyBluetooth.h"
#import "AMPAvatarView.h"
#import "CityPickerViewController.h"
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapLocationKit/AMapLocationKit.h>


@interface ViewController : UIViewController<CityPickerViewControllerDelegate>

@property(strong,nonatomic)CBPeripheral *currPeripheral;
@property (strong, nonatomic) UIImageView *bgImageView;
@property (strong, nonatomic) UIImageView *cellImageView;
@property (strong, nonatomic) UIImageView *tempImageView;
@property (strong, nonatomic) UIImageView *pm1ImageView;
@property (strong, nonatomic) UIImageView *humiImageView;
@property (strong, nonatomic) UIImageView *connImageView;
@property (strong, nonatomic) UIImageView *shareImageView;


@property (strong, nonatomic)  AMPAvatarView *leftCircle;
@property (strong, nonatomic)  AMPAvatarView *midCircle;
@property (strong, nonatomic)  AMPAvatarView *rightCircle;
@property (strong, nonatomic)  AMPAvatarView *weatherCircle;


@property (strong, nonatomic)  UIView *cellView;
@property (strong, nonatomic)  UIView *shareView;


@property (strong, nonatomic)  UILabel *pm10Label;
@property (strong, nonatomic)  UILabel *ch2oLabel;
@property (strong, nonatomic)  UILabel *pm25Label;
@property (strong, nonatomic)  UILabel *cellLabel;
@property (strong, nonatomic)  UILabel *weatherLabel;
@property (strong, nonatomic)  UILabel *tempLabel;
@property (strong, nonatomic)  UILabel *pm1Label;
@property (strong, nonatomic)  UILabel *humiLabel;

@property (strong, nonatomic)  AMapLocationManager *locationManager;

@property (strong, nonatomic)  NSString *curCity;



-(void) didReceiveNotifyData:(NSData*) data;
-(float) convertToFloat:(Byte*) btDatas;
@end

