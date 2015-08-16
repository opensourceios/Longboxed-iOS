buildNumber=$(git rev-list HEAD | wc -l | tr -d ' ')
/usr/libexec/PlistBuddy -c "Set CFBundleVersion $buildNumber" "../Longboxed-iOS/Longboxed-iOS-Info.plist"