//
//  STRYoutubeEmbedPage.m
//  SharethroughSDK
//
//  Created by sharethrough on 2/11/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRYouTubeEmbedPage.h"

@implementation STRYouTubeEmbedPage

+ (NSString *)htmlForYouTubeEmbed {
    return @"<!DOCTYPE html>\
    <html>\
    <body style='margin: 0; background-color: black;'>\
    <div id='player'></div>\
\
    <script>\
    var tag = document.createElement('script');\
\
    tag.src = 'https://www.youtube.com/iframe_api';\
    var firstScriptTag = document.getElementsByTagName('script')[0];\
    firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);\
\
    var player;\
    function onYouTubePlayerAPIReady() {\
        player = new YT.Player('player', {\
        playerVars: { 'autoplay': 0, 'modestbranding': 1, 'rel': 0, 'showinfo': 0, 'iv_load_policy': 3, 'controls': 1, 'playsinline':1 },\
        videoId: '%@',\
        height: '0',\
        width: '0',\
        events: {'onReady': onPlayerReady}\
        });\
    }\
\
    function onPlayerReady(event) {\
        player.playVideo();\
    }\
    </script>\
    </body>\
    </html>";
}

@end
