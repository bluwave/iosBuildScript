iosBuildScript
==============

ios build scripts to automate ios builds from command line

i usually have a directory structure like this with my ios projects


	--
	|
	|-projectName (src files usually here)
 	|
 	|-projectName.xcodeproj
 	|
 	|-buildScripts
         	|
         	|-build.sh
         	|
         	|-provisions
                 	|
                 	|-provisionFile
 				
 				


I usually change into the buildScripts directory and execute the following command to build and deploy the app:

	buildScripts$ ./build.sh
	
You may need to first give the script permissions to run


There are a few variables in the header of the [build script](https://github.com/bluwave/iosBuildScript/blob/master/buildScripts/build.sh "build script")  you'll need to change for your project

	PROJECT_NAME="<AppNameHere>"
	TARGET_NAME="<TargetNameHere>"
	PROVISION_DEVELOPER_NAME="iPhone Distribution: <provision name here>"
	PROVISION_PROFILE="provisions/<provisionFileHere>"
	TESTFLIGHT_API_TOKEN="<testflight api token>"
	TESTFLIGHT_TEAM_TOKEN="<testflight team token here>"
	
