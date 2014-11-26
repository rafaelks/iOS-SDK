# Sharethrough iOS-SDK #

<div class="section-footer"></div>

<div id="toc"></div>
## Table of Contents ##
1. [Setting up the SDK][sect-setup]
2. [Adding a Sharethrough Native ad to your app][sect-firstAd]
	* [Basic, yet flexible API] [sect-firstAd-basic]
	* [UITableView API][sect-firstAd-table]
	* [UICollectionView API][sect-firstAd-collection]
3. [Viewing the Sample App][sect-sampleAppIntro]
4. [Documentation][sect-docs]
5. [SDK+DFP][sect-dfp]

<hr/>
<div id="setup"></div>
### 1. Setup the SDK ###
### 1.a Cocoapods ###
Add the following to your Podfile

    pod 'SharethroughSDK', '~> 1.3'

### 1.b Manually ###

1. Download the SDK. The latest version can be found [here][sdk].

1. Untar and add the SDK to your Xcode Project.

1. Drag the SharethroughSDK.framework into the Frameworks section of your Project Navigator.
![Navigator Screenshot][nav-screenshot]

1. Choose 'Create groups for any added folders' and select 'Copy items into destination group's folder (if needed)' to copy the SDK into your app.
![Add framework Screenshot][copy-screenshot]

1. In your application target, select "Build Settings". You'll be in "Basic" settings by default - select "All" settings instead, then add the `-ObjC` linker flag to other linker flags as in the following:
![Link to add linker flag screenshot][linker-flag-screenshot]
More information about this flag can be found [here][apple-technical-note-linker-flag]. This flag is not required if only using the basic API.

1. In your application target, select "Build Phases" and add a new library to link against.
![Link to new library screenshot][project_settings-screenshot]

The following list of frameworks are required:

- MediaPlayer.framework
- AdSupport.framework
- CoreGraphics.framework
- SharethroughSDK.framework
- UIKit.framework
- Foundation.framework

After adding the frameworks, your project's "Link Binary With Libraries" should look something like the following:
![Linked libraries][linked-libraries-screenshot]

</hr>

<div id="first-ad-intro"><a href="#toc">Back to top</a></div>

### 2. Adding a Sharethrough Native ad to your app ###
Sharethrough's API provides the following ways to integrate native ads into your app.

- The basic version is very flexible - you hand it a  `UIView`, and it places an ad in that view. You can use this view virtually anywhere in your app.
- The `UITableView` API allows you to place an ad in your `UITableView`, and then manages that ad for you so that your content's `NSIndexPaths` are unchanged
- The `UICollectionView` API allows you to place an ad in your `UICollectionView`, and then manages that ad for you so that your content's `NSIndexPaths` are unchanged.

In all cases, these ad views should be styled according to the rest of your app, giving it that customized native feel (fonts, colors, etc.)

Import the API as below:

```
#import <SharethroughSDK/SharethroughSDK.h>
```

<div id="first-ad-basic"></div>
#### Using the basic, yet flexible API ####

* The UIView in which you'd like to place an advertisement must conform to the `<STRAdView>` protocol. This can be a new subclass of `UIView`, or it can be a new subclass of your existing view. In either case, it must implement the following methods:

	```
	- (UILabel *)adTitle;
	- (UIImageView *)adThumbnail;
	- (UILabel *)adSponsoredBy;

	//optional
	- (UILabel *)adDescription;
	```

* Then, use the sdk to place an ad in the view, for example from the current controller:

	```
 	[[SharethroughSDK sharedInstance] placeAdInView:yourView placementKey:@"yourUniquePlacementKey" presentingViewController:self delegate:nil];
	[self.view addSubview:yourView];
	yourView.frame = CGRectMake(0, 0, 320, 100);
	```
* **Note** The subclass of `UIView` which conforms to `<STRAdView` protocol (in this example `yourView`) must already have been added to a parent view before calling `placeAdInView:placementKey:presentingViewController:delegate`.  The ad may display in the view, but no tracking will take place, i.e. you won't receive credit for showing the ad.

<div id="first-ad-table"></div>
#### Using the UITableView API ####
The `UITableView API` allows you to integrate ads directly into your stream without any extra work on your part. It keeps track of your view's delegate and datasource, and intelligently ensures that you change only your content, without inadvertently affecting any advertisements.

* In your `viewDidLoad` method, register a cell reuse identifier specifically for advertisement cells. This reuse identifier can register the same class as the rest of your content cells, or it can register a class that will only be used for ad cells. Whichever method you choose, the class must conform to the `<STRAdView>` protocol. For example, in our sample app, we have the following 2 lines of code:

   ```
    [self.tableView registerClass:[STSNewsFeedCell class] forCellReuseIdentifier:kCellIdentifier];
    [self.tableView registerClass:[STSAdNewsFeedCell class] forCellReuseIdentifier:kTableViewAdCellReuseIdentifier];
   ```


	`kCellIdentifier` and `kTableViewAdCellReuseIdentifier` are unique NSStrings defined at the beginning of our controller, but they can be defined wherever makes sense for your application. We chose to register 2 classes - the `STSAdNewsFeedCell` is just a subclass of `STSNewsFeedCell`, with additional accessors to make it compatible with the `<STRAdView>` protocol.

* Also in `viewDidLoad`, tell the SDK to place the ad in your view, like below:

	```
	[[SharethroughSDK sharedInstance] placeAdInTableView:self.tableView adCellReuseIdentifier:kTableViewAdCellReuseIdentifier placementKey:kPlacementKey presentingViewController:self adHeight:118.0 adInitialIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]];
	```

 - The `adHeight` can be the same as the rest of your rows, but doesn't have to be.
 - The `adInitialIndexPath` is the advertisement's initial position.
 - `kPlacementKey` is an `NSString` representing your Sharethrough placement key.

That's it! Your stream now has an elegantly embedded advertisement.

* **Important:** The SDK provides category methods on `UITableView` which replace `UITableView`'s default methods. These category methods are prefixed with `str_`, and can be used instead of the `UITableView` default methods. Some of the category methods are **required** to ensure that your content's behavior is not affected by the advertisement; other **optional** methods are convenient accessors that allow you to manipulate index paths without having to account for ads. The **required** category methods are below:
	
	```
	– str_insertRowsAtIndexPaths:withAnimation:
	– str_deleteRowsAtIndexPaths:withAnimation:
	– str_moveRowAtIndexPath:toIndexPath:
	– str_insertSections:withRowAnimation:
	– str_deleteSections:withRowAnimation:
	– str_moveSection:toSection:
	– str_reloadDataWithAdIndexPath:
	– str_reloadRowsAtIndexPaths:withRowAnimation:
	– str_reloadSections:withRowAnimation:

	– str_dataSource
	– str_setDataSource:
	– str_delegate
	– str_setDelegate:
	```
The complete list of category methods, required and optional, is in the [documentation][docs-tableview-category].



<div id="first-ad-collection"></div>
#### Using the UICollectionView API ####
The `UICollectionView API` also allows you to integrate ads directly into your stream without any extra work on your part. It keeps track of your view's delegate and dataSource, and intelligently ensures that you change only your content, without inadvertently affecting any advertisements.

* In your `viewDidLoad` method, register a cell reuse identifier specifically for advertisement cells. This reuse identifier can register the same class as the rest of your content cells, or it can register a class that will only be used for ad cells. Whichever method you choose, the class must conform to the `<STRAdView>` protocol. For example, in our sample app, we have the following lines of code:

   ```
   UINib *cellNib = [UINib nibWithNibName:NSStringFromClass([STSCardStyleCell class]) bundle:[NSBundle mainBundle]];

   [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:kCollectionViewCellReuseIdentifier];
   [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:kCollectionViewAdCellReuseIdentifier];
   ```


	`kCollectionViewCellReuseIdentifier` and `kCollectionViewAdCellReuseIdentifier` are unique NSStrings defined at the beginning of our controller, but they can be defined wherever makes sense for your application. We registered the same class loaded from a nib, `STSCardStyleCell`, to be used for both normal cells and advertisement cells. We made minimal changes to `STSCardStyleCell` to become compatible with the `<STRAdView>` protocol.

* Also in `viewDidLoad`, tell the SDK to place the ad in your collection view, like below:

	```
    [self.sdk placeAdInCollectionView:self.collectionView adCellReuseIdentifier:kCollectionViewAdCellReuseIdentifier placementKey:kPlacementKey presentingViewController:self adInitialIndexPath:[NSIndexPath indexPathForItem:2 inSection:0]];
	```

 - The `adInitialIndexPath` is the advertisement's initial position.
 - `kPlacementKey` is an `NSString` representing your Sharethrough placement key.

That's it! Your stream now has an elegantly embedded advertisement.

* **Important:** The SDK provides category methods on `UICollectionView` which replace `UICollectionView`'s default methods. These category methods are prefixed with `str_`, and can be used instead of the `UICollectionView` default methods. Some of the category methods are **required** to ensure that your content's behavior is not affected by the advertisement; other **optional** methods are convenient accessors that allow you to manipulate index paths without having to account for ads. The **required** category methods are below:

	```
	– str_dequeueReusableCellWithReuseIdentifier:forIndexPath:
	– str_insertItemsAtIndexPaths:
	– str_deleteItemsAtIndexPaths:
	– str_moveItemAtIndexPath:toIndexPath:
	– str_reloadDataWithAdIndexPath:
	– str_reloadSections:
	– str_reloadItemsAtIndexPaths:
	
	– str_dataSource
	– str_setDataSource:
	– str_delegate
	– str_setDelegate:
	```
The complete list of category methods, required and optional, is in the [documentation][docs-collectionview-category].

</hr>
<div id="viewing-the-sample-app"><a href="#toc">Back to top</a></div>
### 3. Viewing the sample app ###
The [sample app][sample-app] shows several ways of integrating the Sharethrough SDK to display ads. The sample app emulates a few different news reader styles, while including ads and test cases to help give suggestions of how the SDK can be unit tested within your application.

<div id="documentation"><a href="#toc">Back to top</a></div>
</hr>
### 4. Documentation ###
Documentation for the SDK can be viewed online [here][sdk-docs].

If you would like to install the docset in Xcode, you can download it [here][docset]. After downloading the docset and untaring, you can install these docs to Xcode by copying them over to the Shared Documentation folder:

```
cp -r ~/Downloads/com.sharethrough.SharethroughSDK.docset ~/Library/Developer/Shared/Documentation/DocSets/
```

and then restarting Xcode to pick up the new docset.

<div id="dfp"></div>
### 5. Integrating STR + DFP Framework ###
Follow the instructions for integrating the SharethroughSDK with the following changes.

####Linking
* Use the SharethroughSDK+DFP.framework instead of the SharethroughSDK.framework ![Frameworks]
* Link to the DFP third party library available from [Google DFP]

#### Header Files

* Import `#import <SharethroughSDK+DFP/SharethroughSDK+DFP.h>
` instead of `#import <SharethroughSDK/SharethroughSDK.h>
`

#### Call changes
* For the shared instance the call will be `[SharethroughSDKDFP sharedInstance]`
* The interface for `placeAdInView:placementKey:presentingViewController:delegate` has changed to `placeAdInView:placementKey:dfpPath:presentingViewController:delegate` 
  * The `dfpPath` parameter may be passed as nil or can be the **DFP Ad Unit ID** of the DFP Ad Unit.
  * If it is nil or blank, the Sharethrough SDK will make a call to the Sharethrough platform to retrieve the **DFP Ad Unit ID** that was set inside the platform

The SDK will handle all the work of calling out to DFP, retrieving the creative from DFP, using the parameter in the DFP creative to fetch the Sharethrough ad, and displaying the Sharethrough ad in the given `UIView` or `UITableView` or `UICollectionView`

## Known Issues ##
If you're running your iOS app on a physical iPad while connected to a computer and play a Youtube video from an ad, error messages will be displayed in the Xcode console. This is a known iPad on iOS7 issue, but do not affect your app's functionality. More information can be found [here][stack-overflow]


## Quick Links ##
* [Download SDK][sdk] The latest version of the SDK.
* [Sample App][sample-app] Sample iOS app which utilizes the SDK.
* [View SDK Documentation][sdk-docs]


[sdk]: http://s3.amazonaws.com/iOS-SDK/SharethroughSDK.framework.tar
[nav-screenshot]: documentation/getting_started/nav_screenshot.png
[copy-screenshot]: documentation/getting_started/copy_screenshot.png
[linked-libraries-screenshot]: documentation/getting_started/frameworks_screenshot.png
[linker-flag-screenshot]: documentation/getting_started/linker_flag_screenshot.png
[apple-technical-note-linker-flag]: https://developer.apple.com/library/mac/qa/qa1490/_index.html
[project_settings-screenshot]: documentation/getting_started/project_settings_screenshot.png
[docset]: http://s3.amazonaws.com/iOS-SDK/com.sharethrough.SharethroughSDK.docset.tar
[docs-tableview-category]: iOS/Categories/UITableView+STR.html
[docs-collectionview-category]: iOS/Categories/UICollectionView+STR.html
[stack-overflow]: http://stackoverflow.com/questions/19034954/ios7-uiwebview-youtube-video
[sample-app]: https://github.com/sharethrough/iOS-Sample-App
[sdk-docs]: iOS/index.html
[sect-setup]: #setup
[sect-firstAd]: #first-ad-intro
[sect-firstAd-basic]: #first-ad-basic
[sect-firstAd-table]: #first-ad-table
[sect-firstAd-collection]: #first-ad-collection
[sect-sampleAppIntro]: #viewing-the-sample-app
[sect-docs]: #documentation
[sect-dfp]: #dfp
[frameworks]: documentation/DFP/Frameworks.png
[Google DFP]:https://developers.google.com/mobile-ads-sdk/download#download