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
@property (nonatomic, copy) NSString *dfpPathUrlFormat;
@property (nonatomic, strong) STRNetworkClient *networkClient;

@end

@implementation STRRestClient

- (id)initWithNetworkClient:(STRNetworkClient *)networkClient {
    self = [super init];
    if (self) {
        self.adServerHostName = @"http://btlr.sharethrough.com/v3";
        self.beaconServerHostName = @"http://b.sharethrough.com/butler";
        self.dfpPathUrlFormat = @"https://platform-cdn.sharethrough.com/placements/%@/sdk.json";
        self.networkClient = networkClient;
    }
    return self;
}


- (STRPromise *)getWithParameters:(NSDictionary *)parameters {
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

- (STRPromise *)getDFPPathForPlacement:(NSString *)placementKey {
    STRDeferred *deferred = [STRDeferred defer];

    NSString *urlString = [NSString stringWithFormat:self.dfpPathUrlFormat, placementKey];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];

    [[self.networkClient get:request] then:^id(NSData *data) {
        NSError *jsonParseError;
        NSDictionary *parsedObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParseError];
        if (jsonParseError) {
            [deferred rejectWithError:jsonParseError];
        } else {
            NSString *dfpPath = [parsedObj valueForKey:@"dfp_path"];
            if (dfpPath && ![dfpPath isEqual:[NSNull null]]) {
                [deferred resolveWithValue:dfpPath];
            } else {
                [deferred rejectWithError:[NSError errorWithDomain:@"Emtpy DFP Path" code:1 userInfo:nil]];
            }
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

- (void)sendBeaconWithURL:(NSURL *)url{
    [self.networkClient get:[NSURLRequest requestWithURL:url]];
}
    
- (NSString *)getUserAgent {
    return [self.networkClient userAgent];
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
