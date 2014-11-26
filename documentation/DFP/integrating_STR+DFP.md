## Integrating STR + DFP Framework
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




[frameworks]:Frameworks.png
[Google DFP]:https://developers.google.com/mobile-ads-sdk/download#download