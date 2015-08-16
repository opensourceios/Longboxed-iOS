if [ ${CONFIGURATION} == "AppStore" ]; then
buildNumber=$(git rev-list HEAD | wc -l | tr -d ' ')
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${PROJECT_DIR}/Longboxed-iOS/Longboxed-iOS-Info.plist"
fi;

if [ ${CONFIGURATION} == "Release" ]; then
buildNumber=$(git rev-list HEAD | wc -l | tr -d ' ')
L/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${PROJECT_DIR}/Longboxed-iOS/Longboxed-iOS-Info.plist"
fi;

if [ ${CONFIGURATION} == "Debug" ]; then
buildNumber="Dev"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${PROJECT_DIR}/Longboxed-iOS/Longboxed-iOS-Info.plist"
fi;