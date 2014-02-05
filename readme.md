# Sharethrough iOS-SDK #
## Getting Started ##
* [Download SDK][sdk] The latest version of the SDK.
* [Sample App][sample-app] Sample iOS app which utilizes the SDK.
* [View SDK Documentation][sdk-docs]

## Setup the SDK ##

1. Download the SDK. The latest version can be found [here][sdk].

1. Untar and add the SDK to your Xcode Project.

1. Drag the Sharethrough-SDK.framework into the Frameworks section of your Project Navigator.
![Navigator Screenshot][nav-screenshot]

1. Choose 'Create groups for any added folders' and select 'Copy items into destination group's folder (if needed)' to copy the SDK into your app.
![Add framework Screenshot][copy-screenshot]

1. In your application target, select Build Phases and add a new library to link against.
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

## Known Issues ##
If you're running your iOS app on a physical iPad while connected to a computer and play a Youtube video from an ad, error messages will be displayed in the Xcode console. This is a known iPad on iOS7 issue, but do not affect your app's functionality. More information can be found [here][stack-overflow]

## Display some ads! Make some money! ##
The docset can be downloaded from [here][docset].
After downloading the docset and untaring, you can install these docs to Xcode by copying them over to the Shared Documentation folder:

```
cp -r ~/Downloads/com.sharethrough.Sharethrough-SDK.docset ~/Library/Developer/Shared/Documentation/DocSets/
```

and then restarting Xcode to pick up the new docset.

[sdk]: http://s3.amazonaws.com/iOS-SDK/Sharethrough-SDK.framework.tar
[nav-screenshot]: documentation/getting_started/nav_screenshot.png
[copy-screenshot]: documentation/getting_started/copy_screenshot.png
[linked-libraries-screenshot]: documentation/getting_started/frameworks_screenshot.png
[project_settings-screenshot]: documentation/getting_started/project_settings_screenshot.png
[docset]: http://s3.amazonaws.com/iOS-SDK/com.sharethrough.Sharethrough-SDK.docset.tar
[stack-overflow]: http://stackoverflow.com/questions/19034954/ios7-uiwebview-youtube-video
[sample-app]: https://github.com/sharethrough/iOS-Sample-App
[sdk-docs]: iOS/index.html