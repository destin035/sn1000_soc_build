all: initramfs kernel-initramfs kernel-initramfs-itb

build/make_initramfs:
	@echo "cpio -i -d -H newc -F $(PWD)/build/buildroot/output/images/rootfs.cpio --no-absolute-filenames" > build/make_initramfs
	@echo "echo sfc >> etc/modules" >> build/make_initramfs
	@echo "cp $(PWD)/patches/initramfs/init init" >> build/make_initramfs
	@echo "chmod +x init" >> build/make_initramfs
	@echo "mkdir -p lib/modules/5.4.3-destin" >> build/make_initramfs
	@echo "cp $(PWD)/build/linux-modules/lib/modules/5.4.3-destin/modules.* lib/modules/5.4.3-destin" >> build/make_initramfs
	@echo "mkdir -p lib/modules/5.4.3-destin/kernel/drivers/net/ethernet/sfc" >> build/make_initramfs
	@echo "cp $(PWD)/build/linux-modules/lib/modules/5.4.3-destin/kernel/drivers/net/ethernet/sfc/*.ko lib/modules/5.4.3-destin/kernel/drivers/net/ethernet/sfc" >> build/make_initramfs
	@echo "/sbin/depmod -ae -b . -F $(PWD)/build/kernel/System.map 5.4.3-destin" >> build/make_initramfs
	@echo "chown -R root:root lib" >> build/make_initramfs
	@echo "find . | cpio -o -H newc | gzip > $(PWD)/build/images/initramfs.cpio.gz" >> build/make_initramfs
	@chmod +x build/make_initramfs

build/images/initramfs.cpio.gz: build/buildroot/output/images/rootfs.cpio build/make_initramfs
	@test -d build/initramfs && rm -rf build/initramfs
	@mkdir -p build/initramfs
	@cd build/initramfs && fakeroot ../make_initramfs

build/images/zImageInitramfs: build/images/initramfs.cpio.gz
	@ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- BOARD=lx2162au26z LOCALVERSION=-destin \
		make -C build/kernel \
		CONFIG_INITRAMFS_SOURCE=$(PWD)/build/images/initramfs.cpio.gz \
		CONFIG_INITRAMFS_COMPRESSION_GZIP=y Image Image.gz
	@cp build/kernel/arch/arm64/boot/Image.gz build/images/zImageInitramfs

build/kernel-initramfs.its:
	@cp patches/fit/kernel-initramfs.its build/kernel-initramfs.its.tmp
	@sed -i build/kernel-initramfs.its.tmp -e "s,ZIMAGE_INITRAMFS,$(PWD)/build/images/zImageInitramfs,g"
	@sed -i build/kernel-initramfs.its.tmp -e "s,DTB,$(PWD)/build/kernel/arch/arm64/boot/dts/freescale/fsl-lx2162a-u26z-m.dtb,g"
	@cp build/kernel-initramfs.its.tmp build/kernel-initramfs.its

build/images/kernel-initramfs.itb: build/kernel-initramfs.its build/images/zImageInitramfs
	@mkimage -f build/kernel-initramfs.its build/images/kernel-initramfs.itb

initramfs: build/images/initramfs.cpio.gz
.PHONY: initramfs

kernel-initramfs: build/images/zImageInitramfs
.PHONY: kernel-initramfs

kernel-initramfs-itb: build/images/kernel-initramfs.itb
.PHONY: kernel-initramfs-itb

clean:
	$(RM) build/make_initramfs
	$(RM) build/images/initramfs.cpio.gz
	$(RM) build/images/zImageInitramfs
	$(RM) build/images/zImageInitramfs
	$(RM) build/kernel-initramfs.its
	$(RM) build/images/kernel-initramfs.itb

.PHONY: clean
