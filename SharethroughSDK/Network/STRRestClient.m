//
//  STRRestClient.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/17/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRRestClient.h"
#import "STRNetworkClient.h"
#import "STRDeferred.h"


@interface STRRestClient ()

@property (nonatomic, copy) NSString *adServerHostName;
@property (nonatomic, copy) NSString *beaconServerHostName;
@property (nonatomic, strong) STRNetworkClient *networkClient;

@end

@implementation STRRestClient

- (id)initWithStaging:(BOOL)isStaging networkClient:(STRNetworkClient *)networkClient {
    self = [super init];
    if (self) {
        self.adServerHostName = isStaging ? @"http://btlr-staging.sharethrough.com" : @"http://btlr.sharethrough.com";
        self.beaconServerHostName = isStaging ? @"http://b-staging.sharethrough.com" : @"http://b.sharethrough.com";
        self.networkClient = networkClient;
    }
    return self;
}


- (STRPromise *)getWithParameters:(NSDictionary *)parameters {
    STRDeferred *deferred = [STRDeferred defer];

    NSString *urlString = [self.adServerHostName stringByAppendingString:[self encodedQueryParams:parameters]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setValue:@"iPhone" forHTTPHeaderField:@"User-Agent"];

    [[self.networkClient get:request] then:^id(NSData *data) {
        NSError *jsonParseError;
        id parsedObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParseError];
        if (jsonParseError) {
            [deferred rejectWithError:jsonParseError];
        } else {
            [deferred resolveWithValue:parsedObj];
        }
        return data;
    } error:^id(NSError *error) {
        [deferred rejectWithError:error];
        return error;
    }];

    return deferred.promise;
}

- (void)sendBeaconWithParameters:(NSDictionary *)parameters {
    NSString *urlString = [self.beaconServerHostName stringByAppendingString:[self encodedQueryParams:parameters]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];

    [self.networkClient get:request];
}

- (NSString*)encodedQueryParams:(NSDictionary *)params {
    NSMutableArray *parts = [NSMutableArray array];
    for (id key in params) {
        id value = params[key];
        NSString *part = [NSString stringWithFormat: @"%@=%@", [self urlEncode:key], [self urlEncode:value]];
        [parts addObject: part];
    }
    
    return [NSString stringWithFormat:@"%@%@", params.count > 0 ? @"?" : @"", [parts componentsJoinedByString: @"&"]];
}

- (NSString*)urlEncode:(id)object {
    NSString *string = [NSString stringWithFormat: @"%@", object];
    return [string stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
}


@end
