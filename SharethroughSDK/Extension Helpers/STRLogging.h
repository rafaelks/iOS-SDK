//
//  STRLogging.h
//  SharethroughSDK
//
//  Created by Mark Meyer on 5/22/15.
//  Copyright (c) 2015 Sharethrough. All rights reserved.
//

#ifndef SharethroughSDK_STRLogging_h
#define SharethroughSDK_STRLogging_h

#ifdef TRACE
#   define TLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   define TLog(...)
#endif

#define ALog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)

#endif
