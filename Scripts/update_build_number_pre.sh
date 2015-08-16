if [ ${CONFIGURATION} == "AppStore" ] || [ ${CONFIGURATION} == "Beta" ] || [ ${CONFIGURATION} == "Release" ]; then
buildNumber=$(git rev-list HEAD | wc -l | tr -d ' ')
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${PROJECT_DIR}/Longboxed-iOS/Longboxed-iOS-Info.plist"
fi;

if [ ${CONFIGURATION} == "Debug" ] || [ ${CONFIGURATION} == "Test" ]; then
buildNumber="Dev"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${PROJECT_DIR}/Longboxed-iOS/Longboxed-iOS-Info.plist"
fi;