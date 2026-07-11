#!/usr/bin/env bash
# Declarative device spoofing table for Android RE emulator.
# Source this file after sourcing _helpers.sh.
#
# Format: SPOOF_PROPS entries are "prop|value" pairs applied via Magisk resetprop.
# SPOOF_HIDE_FILES are emulator-indicator device nodes moved aside.
# SPOOF_STOP_SERVICES are emulator-specific HAL services killed after spoof.

# Target device identity: real Google Pixel 7 (panther)
SPOOF_DEVICE_BRAND="google"
SPOOF_DEVICE_NAME="panther"
SPOOF_DEVICE_MODEL="Pixel 7"
SPOOF_DEVICE_MANUFACTURER="Google"
SPOOF_DEVICE_BOARD="gs101"
SPOOF_DEVICE_HARDWARE="pixel"
SPOOF_DEVICE_SOC="gs101"
SPOOF_DEVICE_FINGERPRINT="google/panther/panther:14/UQ1A.240205.002/12069354:user/release-keys"
SPOOF_DEVICE_SERIAL="PIXEL7_$(date +%s)"

# Build metadata — matches Pixel 7 UQ1A.240205.002 build
SPOOF_BUILD_DATE="Mon Feb 05 15:48:35 UTC 2024"
SPOOF_BUILD_DATE_UTC="1707145715"
SPOOF_BUILD_USER="android-build"
SPOOF_BUILD_HOST="abfarm-release-rbe-64-00075"

# Network operator — Verizon US (override per assessment if needed)
SPOOF_OPERATOR_ALPHA="Verizon"
SPOOF_OPERATOR_NUMERIC="311480"

# System properties to spoof: "property|value"
# shellcheck disable=SC2034
SPOOF_PROPS=(
	# Hardware identity
	"ro.hardware|${SPOOF_DEVICE_HARDWARE}"
	"ro.hardware.gralloc|${SPOOF_DEVICE_HARDWARE}"
	"ro.hardware.power|${SPOOF_DEVICE_HARDWARE}"
	"ro.hardware.vulkan|${SPOOF_DEVICE_HARDWARE}"
	"ro.hardware.audio.primary|${SPOOF_DEVICE_HARDWARE}"
	"ro.boot.hardware|${SPOOF_DEVICE_HARDWARE}"
	"ro.boot.hardware.vulkan|${SPOOF_DEVICE_HARDWARE}"
	"ro.boot.hardware.sku|${SPOOF_DEVICE_NAME}"
	"ro.soc.model|${SPOOF_DEVICE_SOC}"
	"ro.soc.manufacturer|${SPOOF_DEVICE_MANUFACTURER}"
	"ro.board.platform|${SPOOF_DEVICE_BOARD}"
	"ro.product.board|${SPOOF_DEVICE_BOARD}"

	# Device identity
	"ro.product.model|${SPOOF_DEVICE_MODEL}"
	"ro.product.name|${SPOOF_DEVICE_NAME}"
	"ro.product.device|${SPOOF_DEVICE_NAME}"
	"ro.product.brand|${SPOOF_DEVICE_BRAND}"
	"ro.product.manufacturer|${SPOOF_DEVICE_MANUFACTURER}"
	"ro.product.system.device|${SPOOF_DEVICE_NAME}"
	"ro.product.system.name|${SPOOF_DEVICE_NAME}"
	"ro.product.system.model|${SPOOF_DEVICE_MODEL}"
	"ro.product.vendor.device|${SPOOF_DEVICE_NAME}"
	"ro.product.vendor.model|${SPOOF_DEVICE_MODEL}"
	"ro.product.vendor.name|${SPOOF_DEVICE_NAME}"
	"ro.product.bootimage.model|${SPOOF_DEVICE_MODEL}"
	"ro.product.bootimage.name|${SPOOF_DEVICE_NAME}"
	"ro.product.odm.model|${SPOOF_DEVICE_MODEL}"
	"ro.product.odm.name|${SPOOF_DEVICE_NAME}"
	"ro.product.system_ext.model|${SPOOF_DEVICE_MODEL}"
	"ro.product.system_ext.name|${SPOOF_DEVICE_NAME}"
	"ro.product.system_dlkm.model|${SPOOF_DEVICE_MODEL}"
	"ro.product.system_dlkm.name|${SPOOF_DEVICE_NAME}"
	"ro.product.vendor_dlkm.model|${SPOOF_DEVICE_MODEL}"
	"ro.product.vendor_dlkm.name|${SPOOF_DEVICE_NAME}"

	# CPU ABI — emulator uses x86_64; real Pixel 7 is arm64-v8a
	# These are the most reliable emulator tells. Some apps read these directly
	# via Build.SUPPORTED_ABIS rather than getprop, so also patch via Frida.
	"ro.product.cpu.abi|arm64-v8a"
	"ro.product.cpu.abi2|armeabi-v7a"
	"ro.product.cpu.abilist|arm64-v8a,armeabi-v7a,armeabi"

	# Build version — must match the fingerprint's Android 14 / UQ1A.240205.002
	"ro.build.version.sdk|34"
	"ro.build.version.release|14"
	"ro.build.version.codename|REL"
	"ro.build.version.incremental|12069354"
	"ro.build.version.security_incremental|2024-02-05"
	"ro.build.id|UQ1A.240205.002"
	"ro.build.date|${SPOOF_BUILD_DATE}"
	"ro.build.date.utc|${SPOOF_BUILD_DATE_UTC}"
	"ro.build.user|${SPOOF_BUILD_USER}"
	"ro.build.host|${SPOOF_BUILD_HOST}"
	"ro.build.tags|release-keys"
	"ro.build.type|user"

	# Build fingerprint (covers most SDK/emulator detection)
	"ro.build.fingerprint|${SPOOF_DEVICE_FINGERPRINT}"
	"ro.build.display.id|${SPOOF_DEVICE_FINGERPRINT}"
	"ro.build.description|${SPOOF_DEVICE_NAME}-user 14 UQ1A.240205.002 12069354 release-keys"
	"ro.build.flavor|${SPOOF_DEVICE_NAME}-user"
	"ro.build.characteristics|nosdcard,phone"
	"ro.bootimage.build.fingerprint|${SPOOF_DEVICE_FINGERPRINT}"
	"ro.odm.build.fingerprint|${SPOOF_DEVICE_FINGERPRINT}"
	"ro.system.build.fingerprint|${SPOOF_DEVICE_FINGERPRINT}"
	"ro.system_ext.build.fingerprint|${SPOOF_DEVICE_FINGERPRINT}"
	"ro.vendor.build.fingerprint|${SPOOF_DEVICE_FINGERPRINT}"
	"ro.system_dlkm.build.fingerprint|${SPOOF_DEVICE_FINGERPRINT}"
	"ro.vendor_dlkm.build.fingerprint|${SPOOF_DEVICE_FINGERPRINT}"
	"ro.system.build.id|UQ1A.240205.002"
	"ro.vendor.build.id|UQ1A.240205.002"
	"ro.bootimage.build.id|UQ1A.240205.002"

	# Kill the most obvious QEMU/ranchu tells
	"ro.kernel.qemu|0"
	"ro.kernel.qemu.gles|0"
	"ro.boot.qemu|0"
	"ro.boot.qemu.gpu.mode|host"
	"ro.boot.serialno|${SPOOF_DEVICE_SERIAL}"
	"ro.serialno|${SPOOF_DEVICE_SERIAL}"
	"persist.adb.wifi.guid|adb-${SPOOF_DEVICE_SERIAL}"

	# Network operator — emulator has no SIM; real device should show a carrier
	# Using a common US carrier string. Override per assessment if needed.
	"gsm.operator.alpha|${SPOOF_OPERATOR_ALPHA}"
	"gsm.operator.numeric|${SPOOF_OPERATOR_NUMERIC}"
	"gsm.operator.iso|us"
	"gsm.sim.operator.alpha|${SPOOF_OPERATOR_ALPHA}"
	"gsm.sim.operator.numeric|${SPOOF_OPERATOR_NUMERIC}"
	"gsm.sim.operator.iso|us"
	"gsm.sim.state|READY"

	# Emulator-specific properties that leak QEMU/ranchu identity
	"init.svc.qemu-props|stopped"
	"init.svc.qemud|stopped"
	"init.svc.goldfish-logcat|stopped"
	"qemu.hw.mainkeys|0"
	"qemu.sf.fake_camera|none"
)

# Emulator-indicator files to hide (moved to .hidden suffix)
# shellcheck disable=SC2034
SPOOF_HIDE_FILES=(
	"/dev/goldfish_pipe"
	"/dev/qemu_pipe"
	"/dev/socket/genyd"
	"/dev/socket/genymotion"
	"/dev/socket/qemud"
	"/dev/qemu_trace"
	"/system/lib/libgoldfish-ril.so"
	"/system/lib64/libgoldfish-ril.so"
	"/system/lib/libgoldfish_icd.so"
	"/system/lib64/libgoldfish_icd.so"
	"/system/bin/qemu-props"
	"/system/bin/qemud"
	"/system/lib/libc_malloc_debug_qemu.so"
	"/system/lib64/libc_malloc_debug_qemu.so"
)

# Emulator services to stop (not critical for app execution)
# shellcheck disable=SC2034
SPOOF_STOP_SERVICES=(
	"goldfish-logcat"
	"qemu-adb-setup"
	"qemu-adb-keys"
	"qemu-device-state"
	"ranchu-setup"
	"ranchu-net"
	"qemu-props"
	"qemud"
	"goldfish-audio"
	"goldfish-light"
	"goldfish-sensor"
)
