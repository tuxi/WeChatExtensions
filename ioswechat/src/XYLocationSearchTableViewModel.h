//
//  XYLocationSearchTableViewModel.h
//  WeChatExtensions
//
//  Created by Swae on 2017/10/28.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class XYLocationSearchTableViewModel;

@protocol XYLocationSearchTableViewModelDelegate <NSObject>

@optional
- (void)locationSearchTableViewModel:(XYLocationSearchTableViewModel *)viewModel searchResultChange:(NSArray<MKMapItem *> *)searchResult;

@end

@interface XYLocationSearchTableViewModel : NSObject
#if ! __has_feature(objc_arc)
@property (nonatomic, assign) id<XYLocationSearchTableViewModelDelegate> delegate;
#else
@property (nonatomic, weak) id<XYLocationSearchTableViewModelDelegate> delegate;
#endif
/// 搜索关键字
@property (strong, nonatomic) NSString *searchText;
/// 当前地址
@property (nonatomic, strong) NSString *currentAddress;
/// 当前名称
@property (nonatomic, strong) NSString *currentName;
/// 是否正在解析搜索的地址
@property (nonatomic, assign) BOOL reversing;

+ (NSArray *)stringsForItem:(MKMapItem *)item;
- (void)searchFromServer;
- (void)cleanSearch;
/// 根据经纬度检索附近poi
- (void)fetchNearbyInfoWithCoordinate:(CLLocationCoordinate2D)coordinate
                    completionHandler:(void (^)(NSArray<MKMapItem *> *searchResult))completionHandle;
- (void)fetchNearbyInfoCompletionHandler:(void (^)(NSArray<MKMapItem *> *searchResult))completionHandle;

@end
