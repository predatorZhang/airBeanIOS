//
//  ViewController.m
//  airBean
//
//  Created by predator on 17/5/5.
//  Copyright © 2017年 predator. All rights reserved.
//

#import "ViewController.h"
#import "MobClick.h"
#import <NYXImagesKit/NYXImagesKit.h>
#import "Masonry.h"
#import "AFNetworking.h"
#import "SVProgressHUD.h"
#import "UIImageView+WebCache.h"
#import <ShareSDK/ShareSDK.h>
#import <ShareSDKUI/ShareSDK+SSUI.h>

@interface ViewController (){
    NSMutableArray *peripheralDataArray;
    BabyBluetooth *baby;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"viewDidLoad");
    
    [self initUI];
    // Do any additional setup after loading the view, typically from a nib.
    baby = [BabyBluetooth shareBabyBluetooth];
    [self babyDelegate];
    //停止之前的连接
    [baby cancelAllPeripheralsConnection];
    //设置委托后直接可以使用，无需等待CBCentralManagerStatePoweredOn状态。
    baby.scanForPeripherals().connectToPeripherals().begin().stop(10);
    [SVProgressHUD show];

    self.locationManager = [[AMapLocationManager alloc] init];
       // 带逆地理信息的一次定位（返回坐标和地址信息）
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    //   定位超时时间，最低2s，此处设置为10s
    self.locationManager.locationTimeout =10;
    //   逆地理请求超时时间，最低2s，此处设置为10s
    self.locationManager.reGeocodeTimeout = 10;
    
    [self.locationManager requestLocationWithReGeocode:YES completionBlock:^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error) {
        
        if (error)
        {
            NSLog(@"locError:{%ld - %@};", (long)error.code, error.localizedDescription);
            
            if (error.code == AMapLocationErrorLocateFailed)
            {
                return;
            }
        }
        NSLog(@"所在城市:%@", regeocode.province);
        _curCity = regeocode.city==nil?regeocode.province:regeocode.city;
        
        [self getWeather:_curCity];
        
        if (regeocode)
        {
            NSLog(@"reGeocode:%@", regeocode);
        }
    }];
}


#pragma mark - 获取天气数据

-(void)getWeather:(NSString*) city{

    if(city==nil){
        return;
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager GET:heFengAPI
      parameters:@{@"city" : city,
                   @"key" : heFengKey}
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             
//             responseObject =  [responseObject dataUsingEncoding:NSUTF8StringEncoding];
             NSLog(@"JSON: %@", responseObject);

             NSArray* city0 =[responseObject valueForKeyPath:@"HeWeather5.basic.city"];
              NSLog(@"JSON: %@", city0[0]);
             
             NSArray* code =[responseObject valueForKeyPath:@"HeWeather5.now.cond.code"];
             NSLog(@"JSON: %@", code[0]);

             NSArray* pm25 =[responseObject valueForKeyPath:@"HeWeather5.aqi.city.pm25"];
             NSLog(@"JSON: %@", pm25[0]);

             NSArray* pm10 =[responseObject valueForKeyPath:@"HeWeather5.aqi.city.pm10"];
             NSLog(@"JSON: %@", pm10[0]);

             NSArray* tmp =[responseObject valueForKeyPath:@"HeWeather5.now.tmp"];
             NSLog(@"JSON: %@", tmp[0]);

             NSArray* hum =[responseObject valueForKeyPath:@"HeWeather5.now.hum"];
             NSLog(@"JSON: %@", hum[0]);

             NSArray* qlt =[responseObject valueForKeyPath:@"HeWeather5.aqi.city.qlty"];
             NSLog(@"JSON: %@", qlt[0]);

             NSArray* time =[responseObject valueForKeyPath:@"HeWeather5.basic.update.loc"];
             NSLog(@"JSON: %@", time[0]);

             
             SDWebImageManager   *manager   =   [SDWebImageManager   sharedManager];
             
             NSString* imagePathStr = [[imagePath2 stringByAppendingString:code[0]] stringByAppendingString:@".png"];

//             NSString* imagePathStr = [NSString initWithFormat:@"%@,%@", imagePath2,code[0]];
             NSURL *imagePath=[NSURL URLWithString:imagePathStr];
             [manager   downloadImageWithURL:imagePath   options:SDWebImageRetryFailed   progress:^(NSInteger   receivedSize,   NSInteger   expectedSize)   {
                 NSLog(@"显示当前进度");
             }   completed:^(UIImage   *image,   NSError   *error,   SDImageCacheType   cacheType,   BOOL   finished,   NSURL   *imageURL)   {
                 _weatherCircle.image=image;
                 _weatherCircle.hidden=NO;
                 NSLog(@"下载完成");
             }];
             
            _weatherLabel.text = [NSString stringWithFormat:@"%@ 空气质量:%@ 温度:%@\n湿度:%@%% PM2.5:%@ PM10:%@\n时间:%@",city0[0],qlt[0],tmp[0],hum[0],pm25[0],pm10[0],time[0]];
             _weatherLabel.hidden=NO;
             _curCity = city0[0];

      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
          NSLog(@"Error: %@", error);
      }];
}

#pragma mark - 初始化ui
-(void)scanDev:(id)tap{
    baby.scanForPeripherals().connectToPeripherals().begin().stop(10);
    [SVProgressHUD show];
}

-(void)share:(id)tap{
    
    //1、创建分享参数
    NSArray* imageArray = @[[UIImage imageNamed:@"bg_hch0.png"]];
    if (imageArray) {
        NSMutableDictionary *shareParams = [NSMutableDictionary dictionary];
        [shareParams SSDKSetupShareParamsByText:@"分享内容"
                                         images:imageArray
                                            url:[NSURL URLWithString:@"http://mob.com"]
                                          title:@"分享标题"
                                           type:SSDKContentTypeAuto];
        //2、分享（可以弹出我们的分享菜单和编辑界面）
        [ShareSDK showShareActionSheet:nil
                                 items:nil
                           shareParams:shareParams
                   onShareStateChanged:^(SSDKResponseState state, SSDKPlatformType platformType, NSDictionary *userData, SSDKContentEntity *contentEntity, NSError *error, BOOL end) {
                       switch (state) {
                           case SSDKResponseStateSuccess:
                           {
                               UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"分享成功"
                                                                                   message:nil
                                                                                  delegate:nil
                                                                         cancelButtonTitle:@"确定"
                                                                         otherButtonTitles:nil];
                               [alertView show];
                               break;
                           }
                           case SSDKResponseStateFail:
                           {
                               UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"分享失败"
                                                                               message:[NSString stringWithFormat:@"%@",error]
                                                                              delegate:nil
                                                                     cancelButtonTitle:@"OK"
                                                                     otherButtonTitles:nil, nil];
                               [alert show];
                               break;
                           }
                           default:
                               break;
                       }
                   }
         ];
    }
   }

-(void) initUI{
//    
//    UIBarButtonItem *myButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(scanDev:)];
//    self.navigationItem.rightBarButtonItem = myButton;

    _bgImageView = [[UIImageView alloc] initWithFrame:kScreen_Bounds];
    _bgImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:_bgImageView];

    //初始化背景图片
    UIImage *bgImage =  [UIImage imageNamed:@"bg_hch0"];
    CGSize bgImageSize = bgImage.size, bgViewSize = _bgImageView.frame.size;
    
    if (bgImageSize.width > bgViewSize.width && bgImageSize.height > bgViewSize.height) {
        bgImage = [bgImage scaleToSize:bgViewSize usingMode:NYXResizeModeAspectFill];
    }
    // bgImage = [bgImage applyLightEffectAtFrame:CGRectMake(0, 0, bgImage.size.width, bgImage.size.height)];
    _bgImageView.image = bgImage;

    //左侧圆环
    _leftCircle=[AMPAvatarView new];
    [_leftCircle setBorderWidth:kScreen_Width/25];
    [_leftCircle setBorderColor:[UIColor greenColor]];
    [_leftCircle setInnerBackgroundColor:[UIColor blackColor]];
    [_leftCircle setShadowColor:[UIColor colorWithRed:1/123 green:1/23 blue:1/233 alpha:1]];
    [self.view addSubview:_leftCircle];
    [_leftCircle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(kScreen_Width/3, kScreen_Width/3));
        make.centerY.equalTo(self.view.mas_centerY);
        }];
    
    //左侧圆环
    _rightCircle=[AMPAvatarView new];
    [_rightCircle setBorderWidth:kScreen_Width/25];
    [_rightCircle setBorderColor:[UIColor greenColor]];
    [_rightCircle setInnerBackgroundColor:[UIColor blackColor]];
    [_rightCircle setShadowColor:[UIColor colorWithRed:1/123 green:1/23 blue:1/233 alpha:1]];
    [self.view addSubview:_rightCircle];
    [_rightCircle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(kScreen_Width/3, kScreen_Width/3));
        make.centerY.equalTo(self.view.mas_centerY);
        make.right.equalTo(self.view.mas_right);
    }];
  
    //中间圆环
    _midCircle=[AMPAvatarView new];
    [_midCircle setBorderWidth:kScreen_Width/25];
    [_midCircle setBorderColor:[UIColor greenColor]];
    [_midCircle setInnerBackgroundColor:[UIColor blackColor]];
    [_midCircle setShadowColor:[UIColor colorWithRed:1/123 green:1/23 blue:1/233 alpha:1]];
    [self.view addSubview:_midCircle];
    [_midCircle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(kScreen_Width/2, kScreen_Width/2));
        make.centerX.equalTo(self.view.mas_centerX);
        make.centerY.mas_equalTo(_leftCircle.mas_top).offset(-30);
        //make.right.equalTo(self.view.mas_right);
    }];

  
    //PM10
    
    _pm10Label = [[UILabel alloc] init];
    _pm10Label.numberOfLines = 3;
    _pm10Label.backgroundColor = [UIColor clearColor];
    _pm10Label.font = [UIFont systemFontOfSize:12];
    _pm10Label.textColor = [UIColor whiteColor];
    _pm10Label.textAlignment = NSTextAlignmentCenter;
    _pm10Label.text = [NSString stringWithFormat:@"PM10\n --\n ug/m3"];
    [self.view addSubview:_pm10Label];

    [_pm10Label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_leftCircle.mas_centerX);
        make.centerY.equalTo(_leftCircle.mas_centerY);

    }];
    
    //CH2O
    _ch2oLabel = [[UILabel alloc] init];
    _ch2oLabel.numberOfLines = 3;
    _ch2oLabel.backgroundColor = [UIColor clearColor];
    _ch2oLabel.font = [UIFont systemFontOfSize:20];
    _ch2oLabel.textColor = [UIColor whiteColor];
    _ch2oLabel.textAlignment = NSTextAlignmentCenter;
    _ch2oLabel.text = [NSString stringWithFormat:@"甲醛\n --\n mg/m3"];
    [self.view addSubview:_ch2oLabel];
    [_ch2oLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_midCircle.mas_centerX);
        make.centerY.equalTo(_midCircle.mas_centerY);
    }];

    //PM2.5
    _pm25Label = [[UILabel alloc] init];
    _pm25Label.numberOfLines = 3;
    _pm25Label.backgroundColor = [UIColor clearColor];
    _pm25Label.font = [UIFont systemFontOfSize:12];
    _pm25Label.textColor = [UIColor whiteColor];
    _pm25Label.textAlignment = NSTextAlignmentCenter;
    _pm25Label.text = [NSString stringWithFormat:@"PM2.5\n --\n ug/m3"];
    [self.view addSubview:_pm25Label];
    [_pm25Label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_rightCircle.mas_centerX);
        make.centerY.equalTo(_rightCircle.mas_centerY);
        
    }];
    
    //share view
    _shareView = [[UIView alloc] initWithFrame:CGRectMake(20, 30, 30, 40)];
    [self.view addSubview:_shareView];
    _shareImageView=[UIImageView new];
    UIImage* shareImage=[UIImage imageNamed:@"share"];
    CGSize shareImageSize = shareImage.size,shareViewSize = _shareView.frame.size;
    if (shareImageSize.width > shareViewSize.width/2 && shareImageSize.height > shareViewSize.height) {
        CGSize size = CGSizeMake(shareViewSize.width/2, shareViewSize.height);
        shareImage = [shareImage scaleToSize:size usingMode:NYXResizeModeAspectFill];
    }
    _shareImageView.image = shareImage;
    [_shareView addSubview:_shareImageView];
    UITapGestureRecognizer* shareTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(share:)];
    [_shareView addGestureRecognizer:shareTap];
    [_shareImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_shareView.mas_centerX);
        make.centerY.equalTo(_shareView.mas_centerY);
    }];

    //电池电量
    _cellView = [[UIView alloc] initWithFrame:CGRectMake(kScreen_Width-50, 30, 30, 40)];
    [self.view addSubview:_cellView];

    _cellLabel = [[UILabel alloc] init];
    _cellLabel.numberOfLines = 0;
    _cellLabel.backgroundColor = [UIColor clearColor];
    _cellLabel.font = [UIFont systemFontOfSize:15];
    _cellLabel.textColor = [UIColor whiteColor];
    _cellLabel.textAlignment = NSTextAlignmentCenter;
    _cellLabel.text = [NSString stringWithFormat:@"%@%%",@"--"];
    [_cellView addSubview:_cellLabel];
    [_cellLabel mas_makeConstraints:^(MASConstraintMaker *make) {
       // make.right.equalTo(self.view.mas_right);
        make.top.mas_equalTo(_cellView.mas_top);
        make.right.equalTo(_cellView.mas_right);
    }];

    _cellImageView=[UIImageView new];
    UIImage* cellImage=[UIImage imageNamed:@"ic_battery_full"];
    CGSize cellImageSize = cellImage.size,cellViewSize = _cellView.frame.size;
    if (cellImageSize.width > cellViewSize.width/2 && cellImageSize.height > cellViewSize.height) {
        CGSize size = CGSizeMake(cellViewSize.width/2, cellViewSize.height);
        cellImage = [cellImage scaleToSize:size usingMode:NYXResizeModeAspectFill];
    }
    _cellImageView.image = cellImage;
    [_cellView addSubview:_cellImageView];
    [_cellImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        //make..equalTo(_midCircle.mas_centerY);
        make.right.equalTo(_cellLabel.mas_left);
        make.centerY.equalTo(_cellLabel.mas_centerY);
    }];
    [self.view addSubview:_cellView];

    //底部半透明区域
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, 2*(kScreen_Height/3),
                                                                  kScreen_Width, 1*(kScreen_Height/3))];
    bottomView.backgroundColor=[UIColor colorWithRed:1/123 green:1/23 blue:1/233 alpha:0.3];
    //[bottomView setBackgroundColor:[UIColor colorWithRed:0.0 green:1.0 blue:1.0 alpha:0.5]];
    [self.view addSubview:bottomView];
    
    _connImageView=[UIImageView new];
    _connImageView.userInteractionEnabled = YES;
    _connImageView.contentMode=UIViewContentModeScaleAspectFill;
    UIImage* connectImage=[UIImage imageNamed:@"dv_disconnected"];
    _connImageView.image = connectImage;
    [self.view addSubview:_connImageView];
    [_connImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(bottomView.mas_top).offset(-40);
            make.centerX.equalTo(self.view.mas_centerX);
            make.size.mas_equalTo(CGSizeMake(30, 30));
        }];
    UITapGestureRecognizer* singleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(scanDev:)];
    [_connImageView addGestureRecognizer:singleTap];
    
    //天气图片按钮
    _weatherCircle=[AMPAvatarView new];
    [_weatherCircle setBorderWidth:0];
    [_weatherCircle setInnerBackgroundColor:[UIColor clearColor]];
    [_weatherCircle setShadowColor:[UIColor colorWithRed:1/123 green:1/23 blue:1/233 alpha:1]];
    [bottomView addSubview:_weatherCircle];
    [_weatherCircle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(kScreen_Width/6, kScreen_Width/6));
        make.top.equalTo(bottomView.mas_top).offset(10);
        make.left.equalTo(bottomView.mas_left);
    }];
    UITapGestureRecognizer *tapGesturRecognizer=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(cityPickerAction:)];
    [_weatherCircle addGestureRecognizer:tapGesturRecognizer];
    _weatherCircle.hidden=YES;
    
    
    //天气详细描述
    _weatherLabel = [[UILabel alloc] init];
    _weatherLabel.numberOfLines = 3;
    _weatherLabel.backgroundColor = [UIColor clearColor];
    _weatherLabel.font = [UIFont systemFontOfSize:14];
    _weatherLabel.textColor = [UIColor whiteColor];
    _weatherLabel.textAlignment = NSTextAlignmentLeft;
    _weatherLabel.text = [NSString stringWithFormat:@"北京 空气质量：优 2017-05-07 15:51\n 温度30 湿度:14%% PM2.5:23 PM10:43"];
    [bottomView addSubview:_weatherLabel];
    [_weatherLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(bottomView.mas_top).offset(12);
        make.left.mas_equalTo(kScreen_Width/6+5);
    }];
    _weatherLabel.hidden=YES;

    
    //温度label
    _tempLabel = [[UILabel alloc] init];
    _tempLabel.numberOfLines = 2;
    _tempLabel.backgroundColor = [UIColor clearColor];
    _tempLabel.font = [UIFont systemFontOfSize:14];
    _tempLabel.textColor = [UIColor whiteColor];
    _tempLabel.textAlignment = NSTextAlignmentCenter;
    _tempLabel.text = [NSString stringWithFormat:@"温度: --˚C"];
    [bottomView addSubview:_tempLabel];
    [_tempLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(bottomView.mas_top).offset((kScreen_Height/3)*2/3);
        make.left.mas_equalTo(10);
      //  make.height.mas_equalTo(_tempLabel.font.pointSize);
    }];
    
    _tempImageView = [UIImageView new];
    [bottomView addSubview:_tempImageView];
    [_tempImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo((kScreen_Width/3)-10);
        make.centerY.mas_equalTo(bottomView.mas_top).offset((kScreen_Height/3)*2/3);
        make.size.mas_equalTo(CGSizeMake(15, 15));
    }];
    
    UIImageView *splitImageView0 = [UIImageView new];
    splitImageView0.backgroundColor=[UIColor whiteColor];
    [bottomView addSubview:splitImageView0];
    [splitImageView0 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo((kScreen_Width/3)+10);
        make.centerY.mas_equalTo(bottomView.mas_top).offset((kScreen_Height/3)*2/3);
        make.size.mas_equalTo(CGSizeMake(1, (kScreen_Height/3)*2/3-20));
    }];
    
    //PM1
    _pm1Label = [[UILabel alloc] init];
    _pm1Label.numberOfLines = 2;
    _pm1Label.backgroundColor = [UIColor clearColor];
    _pm1Label.font = [UIFont systemFontOfSize:14];
    _pm1Label.textColor = [UIColor whiteColor];
    _pm1Label.textAlignment = NSTextAlignmentCenter;
    _pm1Label.text = [NSString stringWithFormat:@"PM1: --"];
    [bottomView addSubview:_pm1Label];
    [_pm1Label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(bottomView.mas_top).offset((kScreen_Height/3)*2/3);
        make.left.mas_equalTo((kScreen_Width/3)+22);
    }];
    
    _pm1ImageView = [UIImageView new];
    [bottomView addSubview:_pm1ImageView];
    [_pm1ImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo((2*kScreen_Width/3)-10);
        make.centerY.mas_equalTo(bottomView.mas_top).offset((kScreen_Height/3)*2/3);
        make.size.mas_equalTo(CGSizeMake(15, 15));
    }];
    
    UIImageView *splitImageView1 = [UIImageView new];
    splitImageView1.backgroundColor=[UIColor whiteColor];
    [bottomView addSubview:splitImageView1];
    [splitImageView1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo((2*kScreen_Width/3)+10);
        make.centerY.mas_equalTo(bottomView.mas_top).offset((kScreen_Height/3)*2/3);
        make.size.mas_equalTo(CGSizeMake(1, (kScreen_Height/3)*2/3-20));
    }];
    
    //湿度
    _humiLabel = [[UILabel alloc] init];
    _humiLabel.numberOfLines = 2;
    _humiLabel.backgroundColor = [UIColor clearColor];
    _humiLabel.font = [UIFont systemFontOfSize:14];
    _humiLabel.textColor = [UIColor whiteColor];
    _humiLabel.textAlignment = NSTextAlignmentCenter;
    _humiLabel.text = [NSString stringWithFormat:@"湿度: --%%"];
    [bottomView addSubview:_humiLabel];
    [_humiLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(bottomView.mas_top).offset((kScreen_Height/3)*2/3);
        make.left.mas_equalTo((2*kScreen_Width/3)+20);
    }];
    
    _humiImageView = [UIImageView new];
    [bottomView addSubview:_humiImageView];
    [_humiImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo((kScreen_Width)-20);
        make.centerY.mas_equalTo(bottomView.mas_top).offset((kScreen_Height/3)*2/3);
        make.size.mas_equalTo(CGSizeMake(15, 15));
    }];
    
}
-(void)cityPickerAction:(id)tap
{
    CityPickerViewController *cityPickerVC = [[CityPickerViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:cityPickerVC];
    nav.navigationBar.translucent = NO;
    cityPickerVC.cityModels = [self cityModelsPrepare];
    cityPickerVC.delegate = self;
    cityPickerVC.title = @"城市选择";
    cityPickerVC.currentCity = _curCity;
    // 设置热门城市
    cityPickerVC.hotCities = @[@"成都", @"深圳", @"上海", @"长沙", @"杭州", @"南京", @"徐州", @"北京"];
    [self presentViewController:nav animated:YES completion:nil];
    
    NSLog(@"点击了城市选择器");
}

#pragma mark - CityPickerViewControllerDelegate
- (void)cityPickerViewController:(CityPickerViewController *)cityPickerViewController selectedCityModel:(CityModel *)selectedCityModel {
    NSLog(@"统一输出 cityModel id pid spell name :%ld %ld %@ %@", (long)selectedCityModel.cityId, (long)selectedCityModel.pid, selectedCityModel.spell, selectedCityModel.name);
    [self getWeather:selectedCityModel.name];
}

#pragma mark - private methods
- (NSMutableArray *)cityModelsPrepare {
    NSURL *plistUrl = [[NSBundle mainBundle] URLForResource:@"City" withExtension:@"plist"];
    NSArray *cityArray = [[NSArray alloc] initWithContentsOfURL:plistUrl];
    
    NSMutableArray *cityModels = [NSMutableArray array];
    for (NSDictionary *dict in cityArray) {
        CityModel *cityModel = [self parseWithDict:dict];
        
        [cityModels addObject:cityModel];
    }
    return cityModels;
}

- (CityModel *)parseWithDict:(NSDictionary *)dict {
    NSInteger cityId = [dict[@"id"] integerValue];
    NSInteger pid = [dict[@"id"] integerValue];
    NSString *name = dict[@"name"];
    NSString *spell = dict[@"spell"];
    
    CityModel *cityModel = [[CityModel alloc] initWithCityId:cityId pid:pid name:name spell:spell];
    NSArray *children = dict[@"children"];
    
    if (children.count != 0) {
        NSMutableArray *childrenArray = [[NSMutableArray alloc] init];
        for (NSDictionary *childDict in children) {
            CityModel *childCityModel = [self parseWithDict:childDict];
            
            [childrenArray addObject:childCityModel];
        }
        
        cityModel.children = childrenArray;
    }
    
    return cityModel;
}

-(float) convertToFloat:(Byte*) btDatas{
    NSData *data = [[NSData alloc] initWithBytes:btDatas length:24];
    int32_t bytes;
    [data getBytes:&bytes length:sizeof(bytes)];
    bytes = OSSwapBigToHostInt32(bytes);
    float number;
    memcpy(&number, &bytes, sizeof(bytes));
    return number;
}

-(void) changeBackgroundByHoho:(float)hcho by:(float)pm25{
    UIImage *bgImage =nil;
    if(hcho>0.5){
        bgImage =  [UIImage imageNamed:@"bg_hch0"];
        CGSize bgImageSize = bgImage.size, bgViewSize = _bgImageView.frame.size;
        if (bgImageSize.width > bgViewSize.width && bgImageSize.height > bgViewSize.height) {
            bgImage = [bgImage scaleToSize:bgViewSize usingMode:NYXResizeModeAspectFill];
        }
        
    }else if(pm25>115){
        bgImage =  [UIImage imageNamed:@"bg_pm25"];
        CGSize bgImageSize = bgImage.size, bgViewSize = _bgImageView.frame.size;
        if (bgImageSize.width > bgViewSize.width && bgImageSize.height > bgViewSize.height) {
            bgImage = [bgImage scaleToSize:bgViewSize usingMode:NYXResizeModeAspectFill];
        }
    }else{
        bgImage =  [UIImage imageNamed:@"bg_2"];
        CGSize bgImageSize = bgImage.size, bgViewSize = _bgImageView.frame.size;
        if (bgImageSize.width > bgViewSize.width && bgImageSize.height > bgViewSize.height) {
            bgImage = [bgImage scaleToSize:bgViewSize usingMode:NYXResizeModeAspectFill];
        }
    }
    _bgImageView.image = bgImage;
}
-(void) didReceiveNotifyData:(NSData*) data{
    //TODO LIST:解析data数据
    Byte *btData = (Byte *)[data bytes];
    
    for(int i=0;i<[data length];i++){
        NSLog(@"data[%d] = %d\n",i,btData[i]);
    }
    //温度数据
    Byte bytTemp[] = {btData[4],btData[3],btData[2],btData[1]};
    float ftTemp = [self convertToFloat:bytTemp];
    int temp = (int) ftTemp;
    NSString *strTemp = [NSString stringWithFormat:@"%d",temp];
    NSLog(@"温度为： %@", strTemp);

    //湿度
    int hum = (int)btData[5];
     NSLog(@"湿度为： %d", hum);
    if(hum<39){
        _humiLabel.text= [NSString stringWithFormat:@"湿度: %d%%\n干燥",hum];
    }else if(hum>=39&&hum<70){
        _humiLabel.text= [NSString stringWithFormat:@"湿度: %d%%\n湿润",hum];
    }else{
        _humiLabel.text= [NSString stringWithFormat:@"湿度: %d%%\n潮湿",hum];
    }

    //pm10
    int hipm10 = (int)btData[10];
    int lowpm10 = (int)btData[11];
    int pm10 = hipm10*256+lowpm10;
    NSLog(@"pm10为： %d", pm10);
    
    if(pm10<150){//优
         [_leftCircle setBorderColor:[UIColor greenColor]];
          _pm10Label.text= [NSString stringWithFormat:@"PM10: %d\n ug/m3",pm10];
        }else{//良
         [_leftCircle setBorderColor:[UIColor colorWithRed:255.0f/255.0f green:0 blue:0 alpha:0.5]];
          _pm10Label.text= [NSString stringWithFormat:@"PM10: %d\n ug/m3",pm10];
    }
    
    //pm2.5
    int hipm25 = (int)btData[8];
    int lowpm25 = (int)btData[9];
    int pm25 = hipm25*256+lowpm25;
    if(pm25<35){
        //优
        [_rightCircle setBorderColor:[UIColor greenColor]];
        _pm25Label.text= [NSString stringWithFormat:@"PM2.5: %d\n优",pm25];
    }else if(pm25>=35 &&pm25<75){
        //良
        [_rightCircle setBorderColor:[UIColor blueColor]];
        _pm25Label.text= [NSString stringWithFormat:@"PM2.5: %d\n良",pm25];
    }else if(pm25>=75 &&pm25<115){
        //轻度污染
        [_rightCircle setBorderColor:[UIColor colorWithRed:50.0f/255.0f green:0 blue:0 alpha:0.5]];
        _pm25Label.text= [NSString stringWithFormat:@"PM2.5: %d\n轻度污染",pm25];
    }else if(pm25>=115 && pm25<150){
        //中度污染
        [_rightCircle setBorderColor:[UIColor colorWithRed:100.0f/255.0f green:0 blue:0 alpha:0.5]];
        _pm25Label.text= [NSString stringWithFormat:@"PM2.5: %d\n中度污染",pm25];
    }else if(pm25>=150 && pm25<250){
        //重度污染
        [_rightCircle setBorderColor:[UIColor colorWithRed:255.0f/255.0f green:0 blue:0 alpha:0.5]];
        _pm25Label.text= [NSString stringWithFormat:@"PM2.5: %d\n重度污染",pm25];
    }else{
        //严重污染
        [_rightCircle setBorderColor:[UIColor colorWithRed:255.0f/255.0f green:0 blue:0 alpha:0.5]];
        _pm25Label.text= [NSString stringWithFormat:@"PM2.5: %d\n严重污染",pm25];
    }
        
    NSLog(@"pm25为： %d", pm25);

    //pm1
    int hipm1 = (int)btData[10];
    int lowpm1 = (int)btData[11];
    int pm1 = hipm1*256+lowpm1;
    NSLog(@"pm1为： %d", pm1);

    //hcho
    int hiHCHO = (int)btData[12];
    int lowHCHO = (int)btData[13];
    float tmp = (float)((hiHCHO*256+lowHCHO)/1000.0);
    NSString *strHCHO = [NSString stringWithFormat:@"%.3f",tmp];
    NSLog(@"hcho为： %@", strHCHO);
    if(tmp<0.1){
        //正常
        [_midCircle setBorderColor:[UIColor greenColor]];
        _ch2oLabel.text= [NSString stringWithFormat:@" 甲醛\n %@\n 正常",strHCHO];
    }else if(tmp>=0.1&&tmp<0.5){
        //轻度污染
        [_midCircle setBorderColor:[UIColor colorWithRed:50.0f/255.0f green:0 blue:0 alpha:0.5]];
        _ch2oLabel.text= [NSString stringWithFormat:@" 甲醛\n %@\n 轻度污染",strHCHO];
    }else if(tmp>=0.5&&tmp<0.6){
        //污染
        [_midCircle setBorderColor:[UIColor colorWithRed:100.0f/255.0f green:0 blue:0 alpha:0.5]];
        _ch2oLabel.text= [NSString stringWithFormat:@" 甲醛\n %@\n 污染",strHCHO];
    }else {
        //重度污染
        [_midCircle setBorderColor:[UIColor colorWithRed:255.0f/255.0f green:0 blue:0 alpha:0.5]];
        _ch2oLabel.text= [NSString stringWithFormat:@" 甲醛\n %@\n 重度污染",strHCHO];
    }

    //电量
    int cell = (int)btData[14];
    NSLog(@"电量为： %d", cell);
    UIImage* cellImage=nil;
    _cellImageView.contentMode=UIViewContentModeScaleAspectFit;
    if(cell>75&&cell<=100){
        cellImage=[UIImage imageNamed:@"ic_battery_full"];
        
    }else if(cell<=75 && cell>60){
        cellImage=[UIImage imageNamed:@"ic_battery_34"];
        
    }else if(cell<=60 && cell>50){
        cellImage=[UIImage imageNamed:@"ic_battery_half"];
        
    }else if(cell<=50 && cell>20){
        cellImage=[UIImage imageNamed:@"ic_battery_14"];
    }else if(cell<=20){
        cellImage=[UIImage imageNamed:@"ic_battery_low"];
    }
    if(cellImage!=nil){
        CGSize cellImageSize = cellImage.size,cellViewSize = _cellView.frame.size;
        if (cellImageSize.width > cellViewSize.width/2 && cellImageSize.height > cellViewSize.height) {
            CGSize size = CGSizeMake(cellViewSize.width/2, cellViewSize.height);
            cellImage = [cellImage scaleToSize:size usingMode:NYXResizeModeAspectFill];
        }
        _cellImageView.image = cellImage;
    }
    
    _tempLabel.text= [NSString stringWithFormat:@"温度: %@˚C",strTemp];
  //  _humiLabel.text= [NSString stringWithFormat:@"湿度: %d%%",hum];
//    _pm1Label.text= [NSString stringWithFormat:@"PM1: %d",pm1];
//    _pm25Label.text= [NSString stringWithFormat:@"PM2.5\n %d\n ug/m3",pm25];
    _pm1Label.text= [NSString stringWithFormat:@" PM1:%d\n ug/m3",pm1];
//    _ch2oLabel.text= [NSString stringWithFormat:@" 甲醛\n %@\n mg/m3",strHCHO];
    if(cell<=100){
        _cellLabel.text= [NSString stringWithFormat:@"%d%%",cell];
    }
    [self changeBackgroundByHoho:tmp by:pm25];
}

-(void)viewDidAppear:(BOOL)animated{
    NSLog(@"viewDidAppear");
    [MobClick beginLogPageView:[NSString stringWithUTF8String:object_getClassName(self)]];
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [MobClick endLogPageView:[NSString stringWithUTF8String:object_getClassName(self)]];
    NSLog(@"viewWillDisappear");
}

//蓝牙初始化代理
-(void)babyDelegate{
    
    __weak typeof(self) weakSelf = self;
    __weak typeof(baby) weakBaby = baby;

    //设备打开成功回调
    [baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        if (central.state == CBCentralManagerStatePoweredOn) {
            NSLog(@"设备打开成功，开始扫描设备");
        }
    }];
    
    //搜索到设备回调
    [baby setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        NSLog(@"搜索到了设备:%@",peripheral.name);
        [MobClick event:kUmeng_Event_Connect_Device label:@"成功连接设备"];
    }];
    
    
    //设置发现设service的Characteristics的委托
    [baby setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        NSLog(@"===DiscoverCharacteristics:service name:%@",service.UUID);
        for (CBCharacteristic *c in service.characteristics) {
            NSLog(@"charateristic name is :%@",c.UUID);
            
            //ennable humi sensor by write to characteristic
//            if([service.UUID.UUIDString isEqualToString:serviceUUID] &&
//               [c.UUID.UUIDString isEqualToString:characteristicEnableUUID]){
//            Byte b = 0X01;
//            NSData *data = [NSData dataWithBytes:&b length:sizeof(b)];
//            [weakSelf.currPeripheral writeValue:data forCharacteristic:c type:CBCharacteristicWriteWithResponse];
//           }
            
            //notify
            if([service.UUID.UUIDString isEqualToString:serviceUUID] &&
               [c.UUID.UUIDString isEqualToString:characteristicUUID]){
                
                [weakBaby notify:weakSelf.currPeripheral characteristic:c
                       block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
                           //接收到值会进入这个方法
                           NSLog(@"new value %@",characteristics.value);
                           [weakSelf didReceiveNotifyData:characteristics.value];
                       }];
            }
        }
    }];
    
    //设置读取characteristics的委托
    [baby setBlockOnReadValueForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
        NSLog(@"OnReadValueForCharacteristic:characteristic name:%@ value is:%@",characteristics.UUID,characteristics.value);
    }];
    
    //设置读取Descriptor的委托
    [baby setBlockOnReadValueForDescriptors:^(CBPeripheral *peripheral, CBDescriptor *descriptor, NSError *error) {
        NSLog(@"Descriptor name:%@ value is:%@",descriptor.characteristic.UUID, descriptor.value);
    }];
    
    //断开连接
    [baby setBlockOnCancelAllPeripheralsConnectionBlock:^(CBCentralManager *centralManager) {
        NSLog(@"断开连接：setBlockOnCancelAllPeripheralsConnectionBlock");
        UIImage* connectImage=[UIImage imageNamed:@"dv_disconnected"];
        weakSelf.connImageView.image = connectImage;
        [weakBaby AutoReconnect:weakSelf.currPeripheral];
        NSLog(@"设备重连");
    }];
    
    //取消扫描
    [baby setBlockOnCancelScanBlock:^(CBCentralManager *centralManager) {
        //[SVProgressHUD dismiss];
        [SVProgressHUD showInfoWithStatus:@"未搜索到设备"];
        NSLog(@"setBlockOnCancelScanBlock");
    }];
    
    //设置设备连接成功的委托,同一个baby对象，使用不同的channel切换委托回调
    [baby setBlockOnConnected :^(CBCentralManager *central, CBPeripheral *peripheral) {
    
        //停止扫描
        [SVProgressHUD showInfoWithStatus:@"连接成功"];
        UIImage* connectImage=[UIImage imageNamed:@"dv_connected"];
        weakSelf.connImageView.image = connectImage;
        NSLog(@"设备：%@--连接成功",peripheral.name);
        if(weakSelf.currPeripheral!=nil){
            return;
        };
        [weakBaby cancelScan];
        
        weakSelf.currPeripheral = peripheral;
        weakBaby.having(weakSelf.currPeripheral).and.connectToPeripherals().discoverServices().discoverCharacteristics().begin();
           }
     ];
    
    //设置设备连接失败的委托
    [baby setBlockOnFailToConnect :^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"设备：%@--连接失败",peripheral.name);
        [SVProgressHUD showInfoWithStatus:@"连接失败"];

    }];
    
    //设置设备断开连接的委托
    [baby setBlockOnDisconnect :^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"设备：%@--断开连接",peripheral.name);
        [SVProgressHUD showInfoWithStatus:@"连接断开"];
    }];
    
    //设置发现设备的Services的委托
    [baby setBlockOnDiscoverServices :^(CBPeripheral *peripheral, NSError *error) {
        for (CBService *s in peripheral.services) {
            NSLog(@"DiscoverServices:service name：%@",s.UUID);
        }
        
    }];
   
    //设置读取characteristics的委托
    [baby setBlockOnReadValueForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
        NSLog(@"characteristic name:%@ value is:%@",characteristics.UUID,characteristics.value);
    }];
    //设置发现characteristics的descriptors的委托
    [baby setBlockOnDiscoverDescriptorsForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        NSLog(@"===characteristic name:%@",characteristic.service.UUID);
        for (CBDescriptor *d in characteristic.descriptors) {
            NSLog(@"CBDescriptor name is :%@",d.UUID);
        }
    }];
    //设置读取Descriptor的委托
    [baby setBlockOnReadValueForDescriptors:^(CBPeripheral *peripheral, CBDescriptor *descriptor, NSError *error) {
        NSLog(@"Descriptor name:%@ value is:%@",descriptor.characteristic.UUID, descriptor.value);
    }];
    
    //读取rssi的委托
    [baby setBlockOnDidReadRSSI:^(NSNumber *RSSI, NSError *error) {
        NSLog(@"setBlockOnDidReadRSSI:RSSI:%@",RSSI);
    }];

  
    NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@NO};
    //设置连接设备的过滤器
    [baby setFilterOnConnectToPeripherals:^BOOL(NSString *peripheralName,
                                                NSDictionary *advertisementData, NSNumber *RSSI) {
        //这里的规则是：连接第一个AAA打头的设备
        if([peripheralName hasPrefix:BLE_NAME]){
            return YES;
        }
        return NO;
    }];
    
    //设置查找设备的过滤器
    [baby setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        if ([peripheralName hasPrefix:BLE_NAME] ) {
            return YES;
        }
        return NO;
    }];
    
    [baby setBabyOptionsWithScanForPeripheralsWithOptions:scanForPeripheralsWithOptions connectPeripheralWithOptions:nil scanForPeripheralsWithServices:nil discoverWithServices:nil discoverWithCharacteristics:nil];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
