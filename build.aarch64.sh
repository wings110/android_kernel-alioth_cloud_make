#!/bin/bash

#set -e
work_dir=/root
KERNEL_DEFCONFIG=vendor/alioth_defconfig
ANYKERNEL3_DIR=$PWD/AnyKernel3/
FINAL_KERNEL_ZIP=FlyCore_Alioth_Docker_v1.0.1.zip
export ARCH=arm64
PATH="$work_dir/kernel/prebuilts/clang+llvm-14.0.6-aarch64-linux-gnu/bin/:$PATH"
# Speed up build process
MAKE="./makeparallel"

BUILD_START=$(date +"%s")
blue='\033[1;34m'
yellow='\033[1;33m'
nocol='\033[0m'

# Always do clean build lol
echo -e "$yellow**** Cleaning ****$nocol"
mkdir -p out
make O=out clean

echo -e "$yellow**** Kernel defconfig is set to $KERNEL_DEFCONFIG ****$nocol"
echo -e "$blue***********************************************"
echo "          BUILDING KERNEL          "
echo -e "***********************************************$nocol"
make $KERNEL_DEFCONFIG O=out
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      CC=clang \
                      CLANG_TRIPLE=aarch64-linux-gnu- \
                      CROSS_COMPILE=aarch64-linux-gnu- \
                      CROSS_COMPILE_ARM32=arm-linux-gnueabi-

echo -e "$yellow**** Verify Image.gz-dtb & dtbo.img ****$nocol"
ls $PWD/out/arch/arm64/boot/Image.gz-dtb
ls $PWD/out/arch/arm64/boot/dtbo.img

echo -e "$yellow**** Verifying AnyKernel3 Directory ****$nocol"
ls $ANYKERNEL3_DIR
echo -e "$yellow**** Removing leftovers ****$nocol"
rm -rf $ANYKERNEL3_DIR/Image.gz-dtb
rm -rf $ANYKERNEL3_DIR/dtbo.img
rm -rf $ANYKERNEL3_DIR/$FINAL_KERNEL_ZIP

echo -e "$yellow**** Copying Image.gz-dtb & dtbo.img ****$nocol"
cp $PWD/out/arch/arm64/boot/Image.gz-dtb $ANYKERNEL3_DIR/
cp $PWD/out/arch/arm64/boot/dtbo.img $ANYKERNEL3_DIR/

echo -e "$yellow**** Time to zip up! ****$nocol"
cd $ANYKERNEL3_DIR/
zip -r9 $FINAL_KERNEL_ZIP * -x README $FINAL_KERNEL_ZIP
cp $ANYKERNEL3_DIR/$FINAL_KERNEL_ZIP $work_dir/kernel/$FINAL_KERNEL_ZIP

echo -e "$yellow**** Done, here is your checksum ****$nocol"
cd ..
rm -rf $ANYKERNEL3_DIR/$FINAL_KERNEL_ZIP
rm -rf $ANYKERNEL3_DIR/Image.gz-dtb
rm -rf $ANYKERNEL3_DIR/dtbo.img
rm -rf out/

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
sha1sum $work_dir/kernel/$FINAL_KERNEL_ZIP