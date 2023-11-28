#!/bin/bash
#
# Script For Building Android arm64 Kernel
#
# Copyright (C) 2021-2023 itsshashanksp <9945shashank@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Setup colour for the script
yellow='\033[0;33m'
white='\033[0m'
red='\033[0;31m'
green='\e[0;32m'

# Deleting out "kernel complied" and zip "anykernel" from an old compilation
echo -e "$green << cleanup >> \n $white"

rm -rf out
rm -rf zip
rm -rf error.log

# Now u can chose which things need to be modified
#
# DEVICE = your device codename
# KERNEL_NAME = the name of ur kranul
#
# DEFCONFIG = defconfig that will be used to compile the kernel
#
# AnyKernel = the url of your modified anykernel script
# AnyKernelbranch = the branch of your modified anykernel script
#
# HOSST = build host
# USEER = build user
#

# Set main directory of kernel source.
MAIN_DIR="$(pwd)"

# Devices
if [ "$DEVICE_TYPE" == courbet  ];
then
DEVICE="XIAOMI 11 LITE (OSS)"
KERNEL_NAME="PERF+_KERNEL-OSS"
CODENAME="COURBET"

DEFCONFIG="vendor/courbet_perf_defconfig"

AnyKernel="https://github.com/itsshashanksp/AnyKernel3.git"
AnyKernelbranch="courbet"
fi

if [ "$DEVICE_TYPE" == davinci  ];
then
DEVICE="REDMI K20 (OSS)"
KERNEL_NAME="PERF+_KERNEL-OSS"
CODENAME="DAVINCI"

DEFCONFIG="vendor/davinci_perf_defconfig"

AnyKernel="https://github.com/itsshashanksp/AnyKernel3.git"
AnyKernelbranch="davinci"
fi

if [ "$DEVICE_TYPE" == phoenix  ];
then
DEVICE="REDMI K30 & POCO X2 (OSS)"
KERNEL_NAME="PERF+_KERNEL-OSS"
CODENAME="PHOENIX"

DEFCONFIG="vendor/phoenix_perf_defconfig"

AnyKernel="https://github.com/itsshashanksp/AnyKernel3.git"
AnyKernelbranch="phoenix"
fi

if [ "$DEVICE_TYPE" == sweet  ];
then
DEVICE="REDMI NOTE 10 PRO (OSS)"
KERNEL_NAME="PERF+_KERNEL-OSS"
CODENAME="SWEET"

DEFCONFIG="vendor/sweet_perf_defconfig"

AnyKernel="https://github.com/itsshashanksp/AnyKernel3.git"
AnyKernelbranch="master"
fi

if [ "$DEVICE_TYPE" == markw  ];
then
DEVICE="REDMI 4 PRIME"
KERNEL_NAME="PROTOTYPE-4.9.337"
CODENAME="MARKW"

DEFCONFIG="markw_defconfig"

AnyKernel="https://github.com/mozzaru/anykernel.git"
AnyKernelbranch="master"
fi

# Kernel build release tag
KRNL_REL_TAG="$KERNEL_TAG"

HOSST="mozzaru"
USEER="86"

# setup telegram env
export BOT_MSG_URL="https://api.telegram.org/bot$API_BOT/sendMessage"
export BOT_BUILD_URL="https://api.telegram.org/bot$API_BOT/sendDocument"

tg_post_msg() {
        curl -s -X POST "$BOT_MSG_URL" -d chat_id="$2" \
        -d "parse_mode=html" \
        -d text="$1"
}

tg_post_build() {
        #Post MD5Checksum alongwith for easeness
        MD5CHECK=$(md5sum "$1" | cut -d' ' -f1)

        #Show the Checksum alongwith caption
        curl --progress-bar -F document=@"$1" "$BOT_BUILD_URL" \
        -F chat_id="$2" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="$3 build finished in $(($Diff / 60)) minutes and $(($Diff % 60)) seconds | <b>MD5 Checksum : </b><code>$MD5CHECK</code>"
}

tg_error() {
        curl --progress-bar -F document=@"$1" "$BOT_BUILD_URL" \
        -F chat_id="$2" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="$3Failed to build , check <code>error.log</code>"
}

# clang stuff
		echo -e "$green << cloning clang >> \n $white"
		wget https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/main/clang-r498229b.tar.gz -O "aosp-clang.tar.gz"
        mkdir "$MAIN_DIR"/clang-llvm && tar -xf aosp-clang.tar.gz -C "$MAIN_DIR"/clang-llvm && rm -rf aosp-clang.tar.gz 
        mkdir gcc64
        mkdir gcc32
        git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 -b lineage-19.1  gcc64
        git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 -b lineage-19.1  gcc32
          
	    export PATH="$MAIN_DIR/clang-llvm/bin:$MAIN_DIR/gcc64/bin:$MAIN_DIR/gcc32/bin:$PATH"
        export LD_LIBRARY_PATH="$MAIN_DIR/clang-llvm/lib:$LD_LIBRARY_PATH"
        export KBUILD_COMPILER_STRING=$("$MAIN_DIR"/clang-llvm/bin/clang --version | head -n 1)
            COMPILER=$KBUILD_COMPILER_STRING
        export TZ ARCH DEVICE_DEFCONFIG \
              PATH KBUILD_COMPILER_STRING
	
##------------------------------------------------------##

# Targets | Makefile
make O=out ARCH=arm64 markw_defconfig

##------------------------------------------------------##

# Setup build process

build_kernel() {
Start=$(date +"%s")

	make -j$(nproc --all) O=out \
                              ARCH=arm64 \
                              LLVM=1 \
                              LLVM_IAS=1 \
                              AR=llvm-ar \
                              NM=llvm-nm \
                              LD=ld.lld \
                              OBJCOPY=llvm-objcopy \
                              OBJDUMP=llvm-objdump \
                              STRIP=llvm-strip \
                              CC=clang \
                              CLANG_TRIPLE=aarch64-linux-gnu- \
                              CROSS_COMPILE=aarch64-linux-android- \
                              CROSS_COMPILE_ARM32=arm-linux-androideabi-  2>&1 | tee error.log

End=$(date +"%s")
Diff=$(($End - $Start))
}

# Let's start
echo -e "$green << doing pre-compilation process >> \n $white"
export ARCH=arm64
export SUBARCH=arm64
export HEADER_ARCH=arm64

export KBUILD_BUILD_HOST="$HOSST"
export KBUILD_BUILD_USER="$USEER"

mkdir -p out

make clean && make mrproper
make "$DEFCONFIG" O=out

echo -e "$yellow << compiling the kernel >> \n $white"
tg_post_msg "Successful triggered Compiling kernel for $DEVICE $CODENAME" "$CHATID"

build_kernel || error=true

DATE=$(date +"%Y%m%d-%H%M%S")
KERVER=$(make kernelversion)

export IMG="$PWD"/out/arch/arm64/boot/Image.gz
# export dtbo="$PWD"/out/arch/arm64/boot/dtbo.img
# export dtb="$PWD"/out/arch/arm64/boot/dtb.img

        if [ -f "$IMG" ]; then
                echo -e "$green << Build completed in $(($Diff / 60)) minutes and $(($Diff % 60)) seconds >> \n $white"
        else
                echo -e "$red << Failed to compile the kernel , Check up to find the error >>$white"
                tg_post_msg "Kernel failed to compile uploading error log"
                tg_error "error.log" "$CHATID"
                tg_post_msg "done" "$CHATID"
                rm -rf out
                rm -rf testing.log
                rm -rf error.log
                rm -rf zipsigner-3.0.jar
                exit 1
        fi

        if [ -f "$IMG" ]; then
                echo -e "$green << cloning AnyKernel from your repo >> \n $white"
                git clone --depth=1 "$AnyKernel" --single-branch -b "$AnyKernelbranch" zip
                echo -e "$yellow << making kernel zip >> \n $white"
                cp -r "$IMG" zip/
                # cp -r "$dtbo" zip/
                # cp -r "$dtb" zip/
                cd zip
                export ZIP="$KERNEL_NAME"-"$KRNL_REL_TAG"-"$CODENAME"
                zip -r9 "$ZIP" * -x .git README.md LICENSE *placeholder
                curl -sLo zipsigner-3.0.jar https://raw.githubusercontent.com/mozzaru/anykernel/master/zipsigner-3.0.jar
                java -jar zipsigner-3.0.jar "$ZIP".zip "$ZIP"-signed.zip
                tg_post_msg "Kernel successfully compiled uploading ZIP" "$CHATID"
                tg_post_build "$ZIP"-signed.zip "$CHATID"
                tg_post_msg "done" "$CHATID"
                cd ..
                rm -rf error.log
                rm -rf out
                rm -rf zip
                rm -rf testing.log
                rm -rf zipsigner-3.0.jar
                exit
        fi
