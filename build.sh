#!/bin/bash

rm -rf build

# u-boot
mkdir -p build/u-boot
tar xvf downloads/u-boot_lx2162a-bsp0.4.tgz -C build/u-boot
cp -r patches/u-boot/lx2162a-bsp0.4 build/u-boot/patches
cp build/u-boot/patches/series-lx2162au26z build/u-boot/patches/series
pushd build/u-boot && quilt push -a && popd
cp build/u-boot/patches/config-lx2162au26z build/u-boot/configs/lx2162a-lx2162au26z_custom_defconfig
ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- BOARD=lx2162au26z make -C build/u-boot lx2162a-lx2162au26z_custom_defconfig
ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- BOARD=lx2162au26z make -C build/u-boot -j 20

# mc
mkdir -p build/mc
tar xvf downloads/mc_lx2162a-bsp0.4.tgz -C build/mc

# mc-utils
mkdir -p build/mc-utils
tar xvf downloads/mc-utils_lx2162a-bsp0.4.tgz -C build/mc-utils
cp -r patches/mc-utils/lx2162a-bsp0.4 build/mc-utils/patches
cp build/mc-utils/patches/series-lx2162au26z build/mc-utils/patches/series
pushd build/mc-utils && quilt push -a && popd
SOURCEDIR=. make -C build/mc-utils/config

# rcw
mkdir -p build/rcw
tar xvf downloads/rcw_lx2162a-bsp0.4.tgz -C build/rcw
cp -r patches/rcw/lx2162a-bsp0.4 build/rcw/patches
cp build/rcw/patches/series-lx2162a build/rcw/patches/series
pushd build/rcw && quilt push -a && popd
make -C build/rcw -j 20

# ddr
mkdir -p build/ddr-phy-binary
tar xvf downloads/ddr_lx2162a-bsp0.4.tgz -C build/ddr-phy-binary

# atf
mkdir -p build/atf
tar xvf downloads/atf_lx2162a-bsp0.4.tgz -C build/atf
cp -r patches/atf/lx2162a-bsp0.4 build/atf/patches
cp build/atf/patches/series-lx2162a build/atf/patches/series
pushd build/atf && quilt push -a && popd
CROSS_COMPILE=aarch64-linux-gnu- make -C build/atf realclean
CROSS_COMPILE=aarch64-linux-gnu- make -C build/atf PLAT=lx2162au26z all \
	fip BOOT_MODE=flexspi_nor BL33=$PWD/build/u-boot/u-boot.bin \
	pbl RCW=$PWD/build/rcw/lx2162au26z/NNNN_NNNN_PPPP_PPPP_RR_0_2/rcw_2000_600_2900_0_2.bin

# 制作启动镜像
mkdir -p build/images
IMAGE=build/images/boot_xspi.img
rm -f $IMAGE

dd if=build/atf/build/lx2162au26z/release/bl2_flexspi_nor.pbl of=$IMAGE bs=1024 seek=0
dd if=build/atf/build/lx2162au26z/release/fip.bin of=$IMAGE bs=1024 seek=1024
dd if=build/ddr-phy-binary/lx2160a/fip_ddr.bin of=$IMAGE bs=1024 seek=2048

# kernel
mkdir -p build/kernel
tar xvf downloads/kernel_lx2162a-bsp0.4.tgz -C build/kernel
cp -r patches/kernel/lx2162a-bsp0.4 build/kernel/patches
cp build/kernel/patches/series-lx2162a build/kernel/patches/series
pushd build/kernel && quilt push -a && popd
cp build/kernel/patches/config-lx2162au26z build/kernel/arch/arm64/configs/lx2162au26z_defconfig
ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- BOARD=lx2162au26z LOCALVERSION=-destin make -C build/kernel lx2162au26z_defconfig
ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- BOARD=lx2162au26z LOCALVERSION=-destin make -C build/kernel -j 20

# buildroot
mkdir -p build/buildroot
tar xvf downloads/buildroot_2020.02.3.tgz -C build/buildroot
tar xvf downloads/buildroot-dl.tgz -C build/buildroot
cp -r patches/buildroot/2020.02.3 build/buildroot/patches
FORCE_UNSAFE_CONFIGURE=1 make -C build/buildroot defconfig BR2_DEFCONFIG=patches/config-lx2162a
FORCE_UNSAFE_CONFIGURE=1 make -C build/buildroot -j 20