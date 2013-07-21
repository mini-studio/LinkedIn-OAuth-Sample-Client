cd ..
project=OAuthStarterKit
product_name=LinkedInFramework
sdk=$2
echo $1
if ( [ "$1" = "-c" ] ) ; then
xcodebuild clean -target LinkedInFramework -configuration Debug  -sdk iphoneos${sdk}
xcodebuild clean -target LinkedInFramework  -configuration Debug  -sdk iphonesimulator${sdk}
xcodebuild clean -target LinkedInFramework  -configuration Release  -sdk iphoneos${sdk}
xcodebuild clean -target LinkedInFramework  -configuration Release  -sdk iphonesimulator${sdk}
fi

xcodebuild -target LinkedInFramework  -configuration Debug  -sdk iphoneos${sdk}
xcodebuild -target LinkedInFramework  -configuration Debug  -sdk iphonesimulator${sdk}
xcodebuild -target LinkedInFramework  -configuration Release  -sdk iphoneos${sdk}
xcodebuild -target LinkedInFramework  -configuration Release  -sdk iphonesimulator${sdk}

debug_iphoneos_lib=Build/Debug-iphoneos/lib${product_name}.a
debug_iphonesimulator_lib=Build/Debug-iphonesimulator/lib${product_name}.a
release_iphoneos_lib=Build/Release-iphoneos/lib${product_name}_release.a
release_iphonesimulator_lib=Build/Release-iphonesimulator/lib${product_name}_release.a
linkedDebugLib=Build/lib${product_name}.a
linkedReleaseLib=Build/lib${product_name}_release.a
lipo -create "$debug_iphoneos_lib" "$debug_iphonesimulator_lib" -output "$linkedDebugLib"
lipo -create "$release_iphoneos_lib" "$release_iphonesimulator_lib" -output "$linkedReleaseLib"

rm -fr Build/Headers
mkdir Build/Headers
src_dir=${project}/Classes/
dist_dir=Build/Headers/${product_name}
rm -fr $dist_dir
mkdir -p $dist_dir
echo $src_dir
echo $dist_dir
cp -fr $src_dir $dist_dir
find $dist_dir/ -name "*.svn" |xargs rm -rf
find $dist_dir/ -name "*.*"|grep -v '\.h$' |xargs rm -rf

rm -fr Build/Debug-*
rm -fr Build/Release-*
rm -fr Build/*.build
