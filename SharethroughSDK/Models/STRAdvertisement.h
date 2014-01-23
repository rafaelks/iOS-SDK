//
//  STRAdvertisement.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/20/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STRAdvertisement : NSObject

@property (nonatomic, copy) NSString *advertiser;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *adDescription;
@property (nonatomic, copy) NSURL *mediaUrl;
@property (nonatomic, strong) UIImage *thumbnailImage;

- (NSString *)sponsoredBy;
- (NSString *)youtubeVideoId;

@end
