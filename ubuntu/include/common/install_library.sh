#!/bin/bash
# --------------------------------------------------------------------------#
# Description:
# The script will install the libraries and headers for mmngr, drpai, and u-dma-buf
# --------------------------------------------------------------------------#

install_drpai() {
    # Headers
    sudo cp ${wic_rootfs}/usr/include/linux/drpai.h ${rootfs}/usr/include/linux/
}

install_mmngr() {
    # Automatically load the library
    sudo cp ${wic_rootfs}/lib/modules-load.d/mmngr.conf ${rootfs}/etc/modules-load.d/
    sudo cp ${wic_rootfs}/lib/modules-load.d/mmngrbuf.conf ${rootfs}/etc/modules-load.d/

    # Headers
    sudo cp ${wic_rootfs}/usr/local/include/mmngr_public_cmn.h ${rootfs}/usr/include/renesas/
    sudo cp ${wic_rootfs}/usr/local/include/mmngr_private_cmn.h ${rootfs}/usr/include/renesas/
    sudo cp ${wic_rootfs}/usr/local/include/mmngr_buf_private_cmn.h ${rootfs}/usr/include/renesas/
    sudo cp ${wic_rootfs}/usr/local/include/mmngr_user_public.h ${rootfs}/usr/include/renesas/
    sudo cp ${wic_rootfs}/usr/local/include/mmngr_user_private.h ${rootfs}/usr/include/renesas/
    sudo cp ${wic_rootfs}/usr/local/include/mmngr_buf_user_private.h ${rootfs}/usr/include/renesas/
    sudo cp ${wic_rootfs}/usr/local/include/mmngr_buf_user_public.h ${rootfs}/usr/include/renesas/

    # Libraries
    sudo rsync -avl ${wic_rootfs}/usr/lib/libmmngrbuf.so* ${rootfs}/usr/lib/aarch64-linux-gnu/renesas/
    sudo rsync -avl ${wic_rootfs}/usr/lib/libmmngr.so* ${rootfs}/usr/lib/aarch64-linux-gnu/renesas/
}

install_opecva() {
    # Headers
    sudo cp -dr ${wic_rootfs}/usr/include/opencv4 ${rootfs}/usr/include/renesas/

    # Libraries
    sudo rsync -avl ${wic_rootfs}/usr/lib/libglog.so* ${rootfs}/usr/lib/aarch64-linux-gnu/renesas/
    sudo rsync -avl ${wic_rootfs}/usr/lib/libjpeg.so* ${rootfs}/usr/lib/aarch64-linux-gnu/renesas/
    sudo rsync -avl ${wic_rootfs}/usr/lib/libtbb.so* ${rootfs}/usr/lib/aarch64-linux-gnu/renesas/
    sudo rsync -avl ${wic_rootfs}/usr/lib/libtiff.so* ${rootfs}/usr/lib/aarch64-linux-gnu/renesas/
    sudo rsync -avl ${wic_rootfs}/usr/lib/libopencv* ${rootfs}/usr/lib/aarch64-linux-gnu/renesas/
}

instal_udmabuf() {
    # Automatically load the library
    sudo cp ${wic_rootfs}/lib/modules-load.d/u-dma-buf.conf ${rootfs}/etc/modules-load.d/
}

install_library() {
    if [ -n "$1" ]; then
		if [ ! -e "$1" ]; then
			echo "ubuntu rootfs doesn't exist"
			return 1
		fi
		rootfs=$1
		work_dir=$1
	else
		rootfs='rootfs'
		work_dir='rootfs'
	fi

	if [ -n "$2" ]; then
		if [ ! -e "$2" ]; then
			echo "qt rootfs source doesn't exist"
			return 1
		fi
		wic_rootfs=$2
	else
		wic_rootfs='qt_rootfs_source'
	fi

	#install dependencies
	sudo mount -t proc /proc "$work_dir/proc"
	sudo mount -t sysfs /sys "$work_dir/sys"
	sudo mount -o bind /dev "$work_dir/dev"
	sudo mount -o bind /dev/pts "$work_dir/dev/pts"

# Create essential directories and setup rules for mmngr, drpai, and u-dma-buf
# Export the ld config path for Renesas libraries
sudo chroot $work_dir /bin/bash <<'EOF'
	set -x

    mkdir -p usr/include/renesas
    mkdir -p usr/lib/aarch64-linux-gnu/renesas
    mkdir -p etc/modules-load.d
    mkdir -p etc/udev/rules.d

    touch etc/udev/rules.d/99-mmngrbuf.rules
    printf 'KERNEL=="rgnmmbuf", MODE="0666"\n' | tee etc/udev/rules.d/99-mmngrbuf.rules > /dev/null
    
    touch etc/udev/rules.d/99-mmngr.rules
    printf 'KERNEL=="rgnmm", MODE="0666"\n' | tee etc/udev/rules.d/99-mmngr.rules > /dev/null

    touch etc/udev/rules.d/99-drpai.rules
    printf 'KERNEL=="drpai0", MODE="0666"\n' | tee etc/udev/rules.d/99-drpai.rules > /dev/null

    touch /etc/ld.so.conf.d/library-renesas.conf
    printf "/usr/lib/aarch64-linux-gnu/renesas" | tee /etc/ld.so.conf.d/library-renesas.conf > dev/null

	set +x

	exit
EOF

	sudo umount "$work_dir/proc"
	sudo umount "$work_dir/sys"
	sudo umount "$work_dir/dev/pts"
	sudo umount "$work_dir/dev"

    # Porting mmngr
    install_mmngr

    # Porting drpai
    install_drpai

    # Porting opecva
    install_opecva

    # Porting u-dma-buf
    instal_udmabuf
}