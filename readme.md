# Sharethrough iOS-SDK #

## Getting started ##

1. Download the SDK. The latest version can be found [here][sdk].
1. Untar and add the SDK to your XCode Project

Drag the Sharethrough-SDK.framework into the Frameworks section of your Project Navigator.
![Navigator Screenshot][nav-screenshot]

Choose 'Create groups for any added folders' and select 'Copy items into destination group's folder (if needed)' to copy the SDK into your app.
![Add framework Screenshot][copy-screenshot]

## Display some ads! Make some money! ##
The docset can be downloaded from [here][docset].
After downloading the docset and untaring, you can install these docs to XCode by copying them over to the Shared Documentation folder:

```
cp -r ~/Downloads/com.sharethrough.Sharethrough-SDK.docset ~/Library/Developer/Shared/Documentation/DocSets/
```

and then restarting XCode to pick up the new docset.

[sdk]: http://s3.amazonaws.com/iOS-SDK/Sharethrough-SDK.framework.tar
[nav-screenshot]: documentation/getting_started/nav_screenshot.png
[copy-screenshot]: documentation/getting_started/copy_screenshot.png
[docset]: http://s3.amazonaws.com/iOS-SDK/com.sharethrough.Sharethrough-SDK.docset.tar
