SCRIPT_VERSION="0.1"
TARGET_SDK="iphoneos5.1"
PROJDIR=".."	# project dir with the xcodeproj in relation to where this buildscript is
PROJECT_NAME="<AppNameHere>"
TARGET_NAME="<TargetNameHere>"

PROVISION_DEVELOPER_NAME="iPhone Distribution: <provision name here>"
PROVISION_PROFILE="provisions/<provisionFileHere>"

BUILD_DIR="builds"


TESTFLIGHT_NOTES_FILE="notes.txt"
TESTFLIGHT_API_TOKEN="<testflight api token>"
TESTFLIGHT_TEAM_TOKEN="<testflight team token here>"

# the variables below need to be global but are edited from this default value
BUILD_TYPE="NOTSET"
PROJECT_BUILDDIR="${PROJDIR}/build/${BUILD_TYPE}-iphoneos"
BUILDNUMBER=0
VERSION=1
BUILD_FILE="NOTSET"




function echoMessage
(
	MSG=$1
	echo "#########################################################################################"
	echo "#				${MSG}						#"
	echo "#########################################################################################"
)


function clean
(
	echoMessage "CLEAN"
	pushd ${PROJDIR}
	xcodebuild clean -configuration ${BUILD_TYPE}
	checkResultCode $? $"CLEAN BUILD"
	

	popd
)

function build
(
	echoMessage "BUILD"
	pushd ${PROJDIR}
	xcodebuild -target "${TARGET_NAME}" -sdk "${TARGET_SDK}" -configuration ${BUILD_TYPE}
	checkResultCode $? $"BUILD"
	popd
)

function signBuild
(
	echoMessage "SIGNING APP"
	createBuildDir ${BUILD_DIR}
	/usr/bin/xcrun -sdk iphoneos PackageApplication -v "${PROJECT_BUILDDIR}/${PROJECT_NAME}.app" -o "/tmp/${BUILD_FILE}.ipa" --sign "${PROVISION_DEVELOPER_NAME}" --embed "${PROVISION_PROFILE}"
	checkResultCode $? $"SIGNING APP"
	mv /tmp/${BUILD_FILE}.ipa ${BUILD_DIR}
	checkResultCode $? "MOVING SIGNED APP"

)

function incrementBuildNumber
(
	VERSION=$(getVersion)
	BUILDNUMBER=$(getBuildNumber)
	BUILDNUMBER=`echo "scale=1 ; $BUILDNUMBER + 1" | bc`
	/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILDNUMBER" ${PROJDIR}/${PROJECT_NAME}/${TARGET_NAME}-Info.plist
	echoMessage "VERSION ${VERSION}.${BUILDNUMBER}"
)

function getVersion
(
	VERSION=`/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" ${PROJDIR}/${PROJECT_NAME}/${TARGET_NAME}-Info.plist` 
	echo $VERSION
)

function getBuildNumber
(
	BUILDNUMBER=`/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" ${PROJDIR}/${PROJECT_NAME}/${TARGET_NAME}-Info.plist`
	echo $BUILDNUMBER
)

function createBuildDir
(
	DIR=$1
	#check directory exists, if not create it
	if [[ ! -e ${DIR} ]] 
	then
	  	mkdir ${DIR}
	fi
)

function checkResultCode
(
	MSG=$2
	# check to see if there was an error
	# if [ $? != 0 ]
	if [ $1 != 0 ]
	then
	  	echoMessage "${MSG} FAILED"
		exit 1
	fi
)

function zipDsymFiles
(
	echoMessage "ZIPPING dSYM files"
	zip -vr ./${BUILD_DIR}/${BUILD_FILE}.dSYM.zip "${PROJECT_BUILDDIR}/${PROJECT_NAME}.app.dSYM" 
	checkResultCode $? $"ZIPPING dSYM's"
)

function uploadToTestFlight
(

	echoMessage "TESTFLIGHT UPLOAD"

	# collect any testflight notes to upload with build
	NOTES=`cat ${TESTFLIGHT_NOTES_FILE}`
	TESTFLIGHT_NOTES_EDITED="- ${BUILD_TYPE} build \n${NOTES}"

	# you may need to install ruby gem to get json parsing to work and send output to browser.  to do this execute this command `sudo gem install json`
	curl http://testflightapp.com/api/builds.json -F file=@${BUILD_DIR}/${BUILD_FILE}.ipa -F api_token="${TESTFLIGHT_API_TOKEN}" -F team_token="${TESTFLIGHT_TEAM_TOKEN}" -F notes="${TESTFLIGHT_NOTES_EDITED}" -F notify=False \
	| ruby -e "require 'rubygems'; require 'json'; puts JSON[STDIN.read]['config_url'];" | xargs open

	checkResultCode $? "TESTFLIGHT UPLOAD"
)



USAGE="Usage: `basename $0` [-hv] -b [ build type Release | Debug ]"
# Parse command line options.
while getopts hvb: OPT; do  #hvo
    case "$OPT" in
        h)
            echo $USAGE
            exit 0;;
        v)
            echo "`basename $0` version ${SCRIPT_VERSION}"
            exit 0;;
        b)
            BUILD_TYPE=$OPTARG
			PROJECT_BUILDDIR="${PROJDIR}/build/${BUILD_TYPE}-iphoneos"
			;;
        \?)
            # getopts issues an error message
            echo $USAGE >&2
            exit 1
            ;;
    esac
done

# Remove the switches we parsed above.
shift `expr $OPTIND - 1`

if [ "${BUILD_TYPE}" == "NOTSET" ]; then
	echoMessage " BUILD TYPE NOT SET [Release or Debug] "
	echo ""
	echo ${USAGE}
	exit 1	
fi


incrementBuildNumber

# init some variables before doing tasks
VERSION=$(getVersion)
BUILDNUMBER=$(getBuildNumber)
BUILD_FILE=${TARGET_NAME}.${BUILDNUMBER}.${BUILD_TYPE}

clean
build
signBuild
# zipDsymFiles
uploadToTestFlight
