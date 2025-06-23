#!/bin/bash
# --------------------------------------------------------------------------#
# Description:
#   Creates a bootable .img disk image for Renesas RZ/V2H EVK board
#   Includes rootfs and bootloader flashing (BL2, FIP) into raw sectors.
# --------------------------------------------------------------------------#

create_wic() {
    # ---------------------- Remove Existing Output Files -----------------------
    MACHINE="rzv2h-evk-ver1"
    OUTPUT_IMG="ubuntu-image-${MACHINE}.img"
    OUTPUT_IMG_ZIP="ubuntu-image-${MACHINE}.zip"
    if [ -f "$OUTPUT_IMG" ]; then
        echo "[INFO] Removing existing image: $OUTPUT_IMG"
        rm -f "$OUTPUT_IMG"
    fi
    if [ -f "$OUTPUT_IMG_ZIP" ]; then
        echo "[INFO] Removing existing zip: $OUTPUT_IMG_ZIP"
        rm -f "$OUTPUT_IMG_ZIP"
    fi

    # ---------------------- Check Dependencies --------------------------------
    REQUIRED_CMDS=(dd parted dosfstools losetup kpartx zip)
    MISSING_CMDS=()
    for cmd in "${REQUIRED_CMDS[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            MISSING_CMDS+=("$cmd")
        fi
    done
    if [ ${#MISSING_CMDS[@]} -ne 0 ]; then
        echo "[INFO] Installing missing tools: ${MISSING_CMDS[*]}"
        apt-get update
        apt-get install -y "${MISSING_CMDS[@]}"
    fi

    # ---------------------- Configurable Parameters ----------------------------
    if [[ $# -ne 1 ]]; then
        ROOTFS_DIR="./rootfs" # Default root filesystem directory
    else
        ROOTFS_DIR=$1 # Extracted root filesystem directory
    fi

    # MACHINE, OUTPUT_IMG, OUTPUT_IMG_ZIP already set above
    BOOT_SIZE_MB=200
    ROOTFS_SPACE_MB=1024 # Extra space to avoid full disk
    BL2_BIN="bl2_bp_esd-${MACHINE}.bin"
    FIP_BIN="fip-${MACHINE}.bin"

    # ---------------------- Calculate Image Size ------------------------------

    ROOTFS_SIZE_MB=$(du -s -B 1M "$ROOTFS_DIR" | awk '{print $1}')
    TOTAL_SIZE_MB=$((4 + BOOT_SIZE_MB + ROOTFS_SIZE_MB + ROOTFS_SPACE_MB + 10)) # 4MB offset + buffer

    echo "[INFO] Creating blank image: ${OUTPUT_IMG} (${TOTAL_SIZE_MB}MB)..."
    dd if=/dev/zero of="$OUTPUT_IMG" bs=1M count="$TOTAL_SIZE_MB" status=progress
    sync

    # ---------------------- Create Partition Table ----------------------------

    LOOP_DEV=$(sudo losetup -f --show "$OUTPUT_IMG")
    echo "[INFO] Loop device: $LOOP_DEV"

    # Use a 4MB offset for first partition (8192 sectors)
    BOOT_START_MB=4
    ROOTFS_START_MB=$((BOOT_START_MB + BOOT_SIZE_MB))

    echo "[INFO] Creating partitions..."
    sudo parted "$LOOP_DEV" --script mklabel msdos
    sudo parted "$LOOP_DEV" --script mkpart primary fat32 ${BOOT_START_MB}MiB $((ROOTFS_START_MB))MiB
    sudo parted "$LOOP_DEV" --script mkpart primary ext4 ${ROOTFS_START_MB}MiB 100%
    sync
    sleep 1
    sudo losetup -d "$LOOP_DEV"

    # ---------------------- Map and Format Partitions -------------------------

    LOOP_DEV=$(sudo losetup -f --show -P "$OUTPUT_IMG")
    LOOP_NAME=$(basename "$LOOP_DEV")
    sudo kpartx -av "$LOOP_DEV"

    BOOT_PART="/dev/mapper/${LOOP_NAME}p1"
    ROOTFS_PART="/dev/mapper/${LOOP_NAME}p2"

    echo "[INFO] Formatting partitions..."
    sudo mkfs.vfat "$BOOT_PART" -n boot
    sudo mkfs.ext4 "$ROOTFS_PART" -L rootfs

    # ---------------------- Mount & Populate File Systems ---------------------

    MOUNT_BOOT=$(mktemp -d)
    MOUNT_ROOT=$(mktemp -d)

    echo "[INFO] Copying boot files..."
    sudo mount "$BOOT_PART" "$MOUNT_BOOT"
    sudo cp "$ROOTFS_DIR/boot/bl2_bp_spi-${MACHINE}.bin" "$MOUNT_BOOT/"
    sudo cp "$ROOTFS_DIR/boot/${FIP_BIN}" "$MOUNT_BOOT/"
    sudo cp "$ROOTFS_DIR/boot/Image"* "$MOUNT_BOOT/"
    sudo cp "$ROOTFS_DIR/boot/r9a09g057h4-evk-ver1"* "$MOUNT_BOOT/"
    sync
    sleep 1
    sudo umount "$MOUNT_BOOT"

    echo "[INFO] Copying root filesystem..."
    sudo mount "$ROOTFS_PART" "$MOUNT_ROOT"
    sudo cp -a "$ROOTFS_DIR/"* "$MOUNT_ROOT/"
    sudo umount "$MOUNT_ROOT"

    # ---------------------- Write Bootloaders to Raw Image ---------------------

    echo "[INFO] Writing bootloaders to image..."
    dd if="$ROOTFS_DIR/boot/${BL2_BIN}" of="$OUTPUT_IMG" bs=512 seek=1 conv=notrunc status=progress
    dd if="$ROOTFS_DIR/boot/${FIP_BIN}" of="$OUTPUT_IMG" bs=512 seek=768 conv=notrunc status=progress

    # ---------------------- Cleanup --------------------------------------------

    sync
    sudo kpartx -d "$LOOP_DEV"
    sudo losetup -d "$LOOP_DEV"
    rm -rf "$MOUNT_BOOT" "$MOUNT_ROOT"

    # Create zip file for the image
    zip $OUTPUT_IMG_ZIP $OUTPUT_IMG

    echo "[SUCCESS] Bootable .img file created: $OUTPUT_IMG"
    echo "[SUCCESS] Bootable .zip file created: $OUTPUT_IMG_ZIP"

    # Clean up the image file
    rm -f "$OUTPUT_IMG"
}
