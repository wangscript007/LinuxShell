#!/bin/sh
# tcpdump build script for android
# Author:	Max.Chiu
# Description: asm

# Config version
VERSION=4.8.1

# Configure enviroment
export ANDROID_NDK_ROOT="/Applications/Android/android-ndk"
export TOOLCHAIN=$(pwd)/toolchain
export SYSROOT=$TOOLCHAIN/sysroot
#export ANDROID_API=android-21
#export TOOLCHAIN_VERSION=4.9

function configure_toolchain {
	if [ -d $TOOLCHAIN ]; then
		rm -rf $TOOLCHAIN
	fi
	$ANDROID_NDK_ROOT/build/tools/make-standalone-toolchain.sh \
	    --toolchain=$ANDROID_EABI \
	    --platform=$ANDROID_API --install-dir=$TOOLCHAIN 
}

function configure_prefix {
	export PREFIX=$(pwd)/out.android/$ARCH_ABI

	export PKG_CONFIG_LIBDIR=$PREFIX/lib/pkgconfig
	export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig

	export EXTRA_CFLAGS="-I$PREFIX/include -pie -fPIE" 
	export EXTRA_LDFLAGS="-L$PREFIX/lib"
}

function configure_arm {
	export ANDROID_API=android-9
	export TOOLCHAIN_VERSION=4.9
	
	export ARCH_ABI=armeabi
	export ARCH=arm
	export ANDROID_ARCH=arch-arm
	export ANDROID_EABI="arm-linux-androideabi-$TOOLCHAIN_VERSION"
	export CROSS_COMPILE="arm-linux-androideabi-"
	export CROSS_COMPILE_PREFIX=$TOOLCHAIN/bin/$CROSS_COMPILE
		
	export CONFIG_PARAM=""

	export OPTIMIZE_CFLAGS="-marm -march=armv5"

	configure_prefix
}

function configure_armv7a {
	export ANDROID_API=android-9
	export TOOLCHAIN_VERSION=4.9
	
	export ARCH_ABI=armeabi-v7a
	export ARCH=arm
	export ANDROID_ARCH=arch-arm
	export ANDROID_EABI="arm-linux-androideabi-$TOOLCHAIN_VERSION"
	export CROSS_COMPILE="arm-linux-androideabi-"
	export CROSS_COMPILE_PREFIX=$TOOLCHAIN/bin/$CROSS_COMPILE
	export EXTRA_CFLAGS="$EXTRA_CFLAGS -mfloat-abi=softfp -mfpu=vfpv3-d16 -marm -march=armv7-a "
	
	export CONFIG_PARAM=""

	export OPTIMIZE_CFLAGS="-mfloat-abi=softfp -mfpu=vfpv3-d16 -marm -march=armv7-a"

	configure_prefix
}

function configure_arm64 {
	export ANDROID_API=android-21
	export TOOLCHAIN_VERSION=4.9
	
	export ARCH_ABI=arm64-v8a
	export ARCH=aarch64
	export ANDROID_ARCH=arch-arm64
	export ANDROID_EABI="aarch64-linux-android-$TOOLCHAIN_VERSION"
	export CROSS_COMPILE="aarch64-linux-android-"
	export CROSS_COMPILE_PREFIX=$TOOLCHAIN/bin/$CROSS_COMPILE
	
	export CONFIG_PARAM=""
	
	export OPTIMIZE_CFLAGS=""
	
	configure_prefix
}

function configure_x86 {
	export ANDROID_API=android-9
	export TOOLCHAIN_VERSION=4.9
	
	export ARCH_ABI=x86
	export ARCH=x86
	export ANDROID_ARCH=arch-x86
	export ANDROID_EABI="x86-$TOOLCHAIN_VERSION"
	export CROSS_COMPILE="i686-linux-android-"
	export CROSS_COMPILE_PREFIX=$TOOLCHAIN/bin/$CROSS_COMPILE

	export CONFIG_PARAM="--disable-asm"

	export OPTIMIZE_CFLAGS="-m32"

	configure_prefix
}

function show_enviroment {
	echo "####################### $ANDROID_ARCH ###############################"
	echo "ANDROID_NDK_ROOT : $ANDROID_NDK_ROOT"
	echo "TOOLCHAIN : $TOOLCHAIN"
	echo "TOOLCHAIN_VERSION : $TOOLCHAIN_VERSION"
	echo "ANDROID_API : $ANDROID_API"
	echo "ANDROID_ARCH : $ANDROID_ARCH"
	echo "ANDROID_EABI : $ANDROID_EABI"
	echo "SYSROOT : $SYSROOT"
	echo "CROSS_COMPILE : $CROSS_COMPILE"
	echo "CROSS_COMPILE_PREFIX : $CROSS_COMPILE_PREFIX"
	echo "CONFIG_PARAM : $CONFIG_PARAM"
	echo "PREFIX : $PREFIX"
	echo "PKG_CONFIG_LIBDIR : $PKG_CONFIG_LIBDIR"
	echo "PKG_CONFIG_PATH : $PKG_CONFIG_PATH"
	echo "####################### $ANDROID_ARCH enviroment ok ###############################"
}

function build_tcpdump {
	echo "# Start building tcpdump for $ARCH_ABI"
	TCPDUMP="tcpdump-$VERSION"
	cd $TCPDUMP
	
	# build
	./configure \
						--prefix=$PREFIX \
						--extra-cflags=$EXTRA_CFLAGS \
						--extra-ldflags=$EXTRA_LDFLAGS \
						--target-os=linux \
						--enable-cross-compile \
						--sysroot=$SYSROOT \
    				--cross-prefix=$CROSS_COMPILE_PREFIX \
    				--arch=$ARCH \
						--disable-shared \
						--enable-static \
						--enable-gpl \
						--enable-libx264 \
						--enable-nonfree \
    				--enable-libfdk-aac \
				    --disable-doc \
				    --enable-version3 \
    				--disable-vda \
   					--disable-iconv \
    				--disable-outdevs \
    				--disable-ffprobe \
    				--disable-ffplay \
    				--disable-ffserver \
    				--disable-asm \
						--disable-encoders \
				    --enable-encoder=libx264 \
				    --enable-encoder=libfdk_aac \
				    --disable-decoders \
				    --enable-decoder=libx264 \
				    --enable-decoder=libfdk_aac \
    				--disable-demuxers \
    				--enable-demuxer=h264 \
    				--disable-parsers \
    				--enable-parser=h264 \
    				$CONFIG_PARAM \
    				|| exit 1
    				#--enable-small \
    				#--disable-ffmpeg \
    				#--disable-debug \
						#--enable-runtime-cpudetect \
    				
						
	make clean || exit 1
	make || exit
	make install || exit 1

	cd ..
	echo "# Build ffmpeg finish for $ARCH_ABI"
}

function build_ffmpeg_so {
	${CROSS_COMPILE_PREFIX}ld -rpath-link=$SYSROOT/usr/lib -L$SYSROOT/usr/lib -L$PREFIX/lib -soname libffmpeg.so -shared -nostdlib -Bsymbolic --whole-archive --no-undefined -o $PREFIX/libffmpeg.so \
    $PREFIX/lib/libx264.a \
    $PREFIX/lib/libavcodec.a \
    $PREFIX/lib/libavfilter.a \
    $PREFIX/lib/libswresample.a \
    $PREFIX/lib/libavformat.a \
    $PREFIX/lib/libavutil.a \
    $PREFIX/lib/libswscale.a \
    $PREFIX/lib/libpostproc.a \
    $PREFIX/lib/libavdevice.a \
    -lc -lm -lz -ldl -llog
}

# Start Build
BUILD_ARCH=(arm armv7a x86 arm64)
#BUILD_ARCH=(arm64)

echo "# Starting building..."

for var in ${BUILD_ARCH[@]};do
	configure_$var
	show_enviroment
	configure_toolchain
	echo "# Starting building for $ARCH_ABI..."
	build_fdk_aac || exit 1
	build_x264 || exit 1
	build_ffmpeg || exit 1
	echo "# Starting building for $ARCH_ABI finish..."
done

echo "# Build finish" 