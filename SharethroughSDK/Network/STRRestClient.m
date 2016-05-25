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
#import "STRLogging.h"


@interface STRRestClient ()

@property (nonatomic, copy) NSString *adServerHostName;
@property (nonatomic, copy) NSString *beaconServerHostName;
@property (nonatomic, copy) NSString *dfpPathUrlFormat;
@property (nonatomic, copy) NSString *asapServerHostName;
@property (nonatomic, strong) STRNetworkClient *networkClient;

@end

@implementation STRRestClient

- (id)initWithNetworkClient:(STRNetworkClient *)networkClient {
    self = [super init];
    if (self) {
        self.adServerHostName = @"https://btlr.sharethrough.com/v4";
        self.beaconServerHostName = @"https://b.sharethrough.com/butler";
        self.dfpPathUrlFormat = @"https://platform-cdn.sharethrough.com/placements/%@/sdk.json";
        self.asapServerHostName = @"https://asap-staging.sharethrough.com/v1";
        self.networkClient = networkClient;
    }
    return self;
}

- (STRPromise *)getAsapInfoWithParameters:(NSDictionary *)parameters {
    TLog(@"params:%@", parameters);
    STRDeferred *deferred = [STRDeferred defer];
    
    NSString *urlString = [self.asapServerHostName stringByAppendingString:[self encodedQueryParams:parameters]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
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

- (STRPromise *)getWithParameters:(NSDictionary *)parameters {
    TLog(@"params:%@",parameters);
    STRDeferred *deferred = [STRDeferred defer];

    NSString *urlString = [self.adServerHostName stringByAppendingString:[self encodedQueryParams:parameters]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];

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
    TLog(@"params:%@",parameters);
    NSString *urlString = [self.beaconServerHostName stringByAppendingString:[self encodedQueryParams:parameters]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];

    [self.networkClient get:request];
}

- (void)sendBeaconWithURL:(NSURL *)url{
    TLog(@"url:%@",url);
    [self.networkClient get:[NSURLRequest requestWithURL:url]];
}

- (NSString *)getUserAgent {
    TLog(@"");
    return [self.networkClient userAgent];
}

- (NSString*)encodedQueryParams:(NSDictionary *)params {
    TLog(@"");
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
