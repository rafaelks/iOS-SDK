#Cocoapod Update Instructions

Starting from the root of the repository, the Podspec lives under the directory `Podspec/` 

1. Update the version number in the Podspec to the latest git tag which can be found by doing a `git describe` 
2. Do a build of the frameworks through xcode which will correctly version all of the code and copy the Podspec into `built-framework/`
3. `cd built-framework/` 
4. Run the command `pod trunk push SharethroughSDK.podspec`

This is all that's required to push an updated version of the podfile to Cocoapods

Note: Since the source of the podfile comes from s3, in order to actuall serve new code all that's necessary is to update which file is named SharethroughSDK.framework.zip in the iOS-SDK bucket, but it's good to keep the versions in sync