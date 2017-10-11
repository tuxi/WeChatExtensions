//
//  XYMapViewController.m
//  WeChatExtensions
//
//  Created by Swae on 2017/10/11.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "XYMapViewController.h"
#import <MapKit/MapKit.h>
#import "XYLocationManager.h"
#import "XYExtensionConfig.h"
#import "LocationConverter.h"
#import "UIView+Helpers.h"

@interface XYMyAnotation : NSObject <MKAnnotation>
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *icon;

+ (UIImage *)circularDoubleCircleWithDiamter:(NSUInteger)diameter;
@end


@interface XYMapViewController () <MKMapViewDelegate>

@property (strong, nonatomic) MKMapView *mapView;
@property (strong, nonatomic) LocationConverter *locManager;

@end

@implementation XYMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"地图";
    _mapView = [[MKMapView alloc]initWithFrame:self.view.bounds];
    [self.view addSubview:_mapView];
    
    _backBGView = [UIView new];
    _backBGView.backgroundColor = UIColorHexFromRGBAlpha(0xffffff, 0.7);
    [self.view addSubview:_backBGView];
    
    
    _addressLabel = [UILabel new];
    _addressLabel.textColor = [UIColor blackColor];
    _addressLabel.font = [UIFont systemFontOfSize:12];
    [_backBGView addSubview:_addressLabel];
    
    _longitudeLabel = [UILabel new];
    _longitudeLabel.textColor = [UIColor blackColor];
    _longitudeLabel.font = [UIFont systemFontOfSize:12];
    [_backBGView addSubview:_longitudeLabel];
    
    _latitudeLabel = [UILabel new];
    _latitudeLabel.textColor = [UIColor blackColor];
    _latitudeLabel.font = [UIFont systemFontOfSize:12];
    [_backBGView addSubview:_latitudeLabel];
    
    
    _currentLocationBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _currentLocationBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [_currentLocationBtn setTitle:@"定位" forState:UIControlStateNormal];
    [_currentLocationBtn addTarget:self action:@selector(currentLocationBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    _currentLocationBtn.frameSize = CGSizeMake(40, 40);
    [self.view addSubview:_currentLocationBtn];
    
    
    
    XYLocationManager *loc = [XYLocationManager sharedManager];
    [loc getAuthorization];//授权
    [loc startLocation];//开始定位
    
    //跟踪用户位置
    self.mapView.userTrackingMode = MKUserTrackingModeFollow;
    //地图类型
    //    self.mapView.mapType = MKMapTypeSatellite;
    self.mapView.delegate = self;
    
    
    
    XYMyAnotation *anno = [[XYMyAnotation alloc] init];
    anno.coordinate = CLLocationCoordinate2DMake([XYExtensionConfig sharedInstance].latitude, [XYExtensionConfig sharedInstance].longitude);
    anno.title = [NSString stringWithFormat:@"经度：%f",[XYExtensionConfig sharedInstance].longitude];
    anno.subtitle = [NSString stringWithFormat:@"纬度：%f",[XYExtensionConfig sharedInstance].latitude];
    
    self.longitudeLabel.text = [NSString stringWithFormat:@"经度：%f",[XYExtensionConfig sharedInstance].longitude];
    self.latitudeLabel.text = [NSString stringWithFormat:@"纬度：%f",[XYExtensionConfig sharedInstance].latitude];
    //反地理编码
    _locManager = [[LocationConverter alloc] init];
    [_locManager reverseGeocodeWithlatitude:[XYExtensionConfig sharedInstance].latitude longitude:[XYExtensionConfig sharedInstance].longitude success:^(NSString *address) {
        self.addressLabel.text = [NSString stringWithFormat:@"%@",address];
    } failure:^{
        
    }];
    
    [self.mapView addAnnotation:anno];
    
    
    [self.mapView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)]];
}


- (void)currentLocationBtnAction:(id)sender {
    [self.mapView setCenterCoordinate:self.mapView.userLocation.coordinate animated:YES];
}


- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    _backBGView.frameSize = CGSizeMake(self.view.frameSizeWidth, 80);
    [_backBGView bottomAlignForSuperView];
    
    _addressLabel.frameSize = CGSizeMake(_backBGView.frameSizeWidth, 13);
    [_addressLabel topAlignForSuperViewOffset:8];
    
    _longitudeLabel.frameSize = CGSizeMake(_backBGView.frameSizeWidth, 13);
    [_longitudeLabel setFrameOriginYBelowView:_addressLabel offset:8];
    
    _latitudeLabel.frameSize = CGSizeMake(_backBGView.frameSizeWidth, 13);
    [_latitudeLabel  setFrameOriginYBelowView:_longitudeLabel offset:8];
    
    [_currentLocationBtn setFrameOriginYAboveView:_backBGView offset:8];
    
    
}

/**
 * 当用户位置更新，就会调用
 *
 * userLocation 表示地图上面那可蓝色的大头针的数据
 */
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    CLLocationCoordinate2D center = userLocation.location.coordinate;
    userLocation.title = [NSString stringWithFormat:@"经度：%f",center.longitude];
    userLocation.subtitle = [NSString stringWithFormat:@"纬度：%f",center.latitude];
    
    NSLog(@"定位：%f %f --- %i",center.latitude,center.longitude,mapView.showsUserLocation);
    
    
    
    
    //设置地图的中心点，（以用户所在的位置为中心点）
    //    [mapView setCenterCoordinate:userLocation.location.coordinate animated:YES];
    
    //设置地图的显示范围
    //    MKCoordinateSpan span = MKCoordinateSpanMake(0.023666, 0.016093);
    //    MKCoordinateRegion region = MKCoordinateRegionMake(center, span);
    //    [mapView setRegion:region animated:YES];
    
}

//- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
//{
//    //获取跨度
//    NSLog(@"%f  %f",mapView.region.span.latitudeDelta,mapView.region.span.longitudeDelta);
//}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    //如果是定位的大头针就不用自定义
    if (![annotation isKindOfClass:[XYMyAnotation class]]) {
        return nil;
    }
    
    static NSString *ID = @"anno";
    MKAnnotationView *annoView = [mapView dequeueReusableAnnotationViewWithIdentifier:ID];
    if (annoView == nil) {
        annoView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:ID];
    }
    
    XYMyAnotation *anno = annotation;
    UIImage *img = [XYMyAnotation circularDoubleCircleWithDiamter:20];
    annoView.image = img;
    annoView.annotation = anno;
    
    return annoView;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    NSLog(@"didSelectAnnotationView--%@",view);
}


- (void)tap:(UITapGestureRecognizer *)tap
{
    CGPoint touchPoint = [tap locationInView:tap.view];
    CLLocationCoordinate2D coordinate = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    [XYExtensionConfig sharedInstance].latitude = coordinate.latitude;
    [XYExtensionConfig sharedInstance].longitude = coordinate.longitude;
    
    NSLog(@"%@",self.mapView.annotations);
    NSMutableArray *array = [NSMutableArray array];
    NSUInteger count = self.mapView.annotations.count;
    if (count > 1) {
        for (id obj in self.mapView.annotations) {
            if (![obj isKindOfClass:[MKUserLocation class]]) {
                [array addObject:obj];
            }
        }
        [self.mapView removeAnnotations:array];
    }
    
    XYMyAnotation *anno = [[XYMyAnotation alloc] init];
    
    anno.coordinate = coordinate;
    anno.title = [NSString stringWithFormat:@"经度：%f",coordinate.longitude];
    anno.subtitle = [NSString stringWithFormat:@"纬度：%f",coordinate.latitude];
    
    self.longitudeLabel.text = [NSString stringWithFormat:@"经度：%f",coordinate.longitude];
    self.latitudeLabel.text = [NSString stringWithFormat:@"纬度：%f",coordinate.latitude];
    //反地理编码
    [_locManager reverseGeocodeWithlatitude:coordinate.latitude longitude:coordinate.longitude success:^(NSString *address) {
        self.addressLabel.text = [NSString stringWithFormat:@"%@",address];
    } failure:^{
        
    }];
    
    
    
    [self.mapView addAnnotation:anno];
    [self.mapView setCenterCoordinate:coordinate animated:YES];
}


@end


@implementation XYMyAnotation
+ (UIImage *)circularDoubleCircleWithDiamter:(NSUInteger)diameter {
    
    NSParameterAssert(diameter > 0);
    CGRect frame = CGRectMake(0.0f, 0.0f, diameter + diameter/4, diameter);
    
    UIScreen *screen = [UIScreen mainScreen];
    CGFloat scale = screen.scale;
    
    UIGraphicsBeginImageContextWithOptions(frame.size, NO, scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    CGRect frameBlue = CGRectMake(diameter/4, 0, diameter, diameter);
    CGRect frameRed = CGRectMake(0, 0, diameter, diameter);
    
    
    //蓝色的渐变圆
    CGContextSaveGState(context);
    UIBezierPath *imgPath = [UIBezierPath bezierPathWithOvalInRect:frameBlue];
    [imgPath addClip];
    [self drawLinearGradient:context colorBottom:UIColorHexFromRGBAlpha(0x0874e8,0.95) topColor:UIColorHexFromRGBAlpha(0x028fe8,0.95) frame:frameBlue];
    CGContextRestoreGState(context);
    
    //红色圆的边框
    CGContextSaveGState(context);
    CGFloat lineWidth = 0.5;
    CGContextSetLineWidth(context, lineWidth);
    UIBezierPath *outlinePath = [UIBezierPath bezierPathWithOvalInRect:frameRed];
    UIColor *colorWhite = UIColorHexFromRGBAlpha(0xf5f3f0, 1.0);
    CGContextSetStrokeColorWithColor(context, colorWhite.CGColor);
    CGContextAddPath(context, outlinePath.CGPath);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
    
    
    //红色的渐变圆
    CGRect framered2 = CGRectInset(frameRed, 0.25, 0.25);
    CGContextSaveGState(context);
    UIBezierPath *imgPath2 = [UIBezierPath bezierPathWithOvalInRect:framered2];
    [imgPath2 addClip];
    [self drawLinearGradient:context colorBottom:UIColorHexFromRGBAlpha(0xf34f18,0.95) topColor:UIColorHexFromRGBAlpha(0xfb6701,0.95) frame:framered2];
    CGContextRestoreGState(context);
    
    
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    CGContextRestoreGState(context);
    UIGraphicsEndImageContext();
    return newImage;
}

+ (void)drawLinearGradient:(CGContextRef)context colorBottom:(UIColor *)colorBottom topColor:(UIColor *)topColor frame:(CGRect)frame{
    //使用rgb颜色空间
    CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceRGB();
    
    //创建起点颜色
    CGColorRef
    beginColor = colorBottom.CGColor;
    
    //创建终点颜色
    CGColorRef
    endColor = topColor.CGColor;
    
    //创建颜色数组
    CFArrayRef
    colorArray = CFArrayCreate(kCFAllocatorDefault, (const void*[]){beginColor,
        endColor}, 2, nil);
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef)colorArray, NULL);
    
    
    /*绘制线性渐变
     context:图形上下文
     gradient:渐变色
     startPoint:起始位置
     endPoint:终止位置
     options:绘制方式,kCGGradientDrawsBeforeStartLocation 开始位置之前就进行绘制，到结束位置之后不再绘制，
     kCGGradientDrawsAfterEndLocation开始位置之前不进行绘制，到结束点之后继续填充
     */
    CGContextDrawLinearGradient(context, gradient, CGPointZero, CGPointMake(frame.size.width, frame.size.height), kCGGradientDrawsAfterEndLocation);
    CFRelease(gradient);
    //释放颜色空间
    CFRelease(colorArray);
    CGColorSpaceRelease(colorSpace);
}

@end
