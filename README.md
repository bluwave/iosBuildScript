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
 				
 				


I usually change into the buildScripts directory and execute the following command

	buildScripts$ ./build.sh
	
You may need to first give the script permissions to run