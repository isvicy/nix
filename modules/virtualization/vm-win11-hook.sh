#!/run/current-system/sw/bin/bash
set -xe

readonly GUEST_NAME="$1"
readonly HOOK_NAME="$2"
readonly STATE="$3"

# Only act on our target VM
if [[ "$GUEST_NAME" != "win11" ]]; then exit 0; fi

# Skip GPU passthrough unless explicitly enabled
if [[ ! -f /var/lib/libvirt/win11-gpu-passthrough ]]; then exit 0; fi

GPU_DEVS=("0000:01:00.0" "0000:01:00.1")

start_hook() {
  echo "Stopping GUI and detaching GPU for passthrough..."

  # 1. Stop services that hold GPU devices open
  systemctl stop nvidia-container-toolkit-cdi-generator.service 2>/dev/null || true

  # 2. Switch to multi-user target (stops display manager)
  systemctl isolate multi-user.target
  sleep 2

  # 3. Kill all processes holding nvidia/DRI devices open
  fuser -k /dev/nvidia* /dev/dri/* 2>/dev/null || true
  sleep 2

  # 4. Unbind vtconsoles and EFI framebuffer
  for vtcon in /sys/class/vtconsole/vtcon*/bind; do
    echo 0 > "$vtcon" 2>/dev/null || true
  done
  echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind 2>/dev/null || true

  sleep 1

  # 5. Pause udev to prevent it from reloading nvidia modules during teardown
  #    Trap ensures udev is resumed even if the hook fails partway through.
  trap 'udevadm control --start-exec-queue 2>/dev/null' EXIT
  udevadm control --stop-exec-queue

  # 6. Unload nvidia submodules
  modprobe -r nvidia_drm
  modprobe -r nvidia_uvm
  modprobe -r nvidia_modeset

  # 7. Unload i2c_dev if loaded — holds refs on nvidia via I2C adapters
  fuser -k /dev/i2c-* 2>/dev/null || true
  modprobe -r i2c_dev 2>/dev/null || true

  # 8. Unload nvidia
  modprobe -r nvidia

  # 9. Load VFIO and bind GPU
  modprobe vfio_pci
  modprobe vfio_iommu_type1

  for dev in "${GPU_DEVS[@]}"; do
    # Unbind from current driver if any
    if [[ -e /sys/bus/pci/devices/$dev/driver ]]; then
      echo "$dev" > /sys/bus/pci/devices/$dev/driver/unbind 2>/dev/null || true
    fi
    echo "vfio-pci" > /sys/bus/pci/devices/$dev/driver_override
    echo "$dev" > /sys/bus/pci/drivers/vfio-pci/bind
  done

  # 10. Resume udev (also handled by EXIT trap as safety net)
  trap - EXIT
  udevadm control --start-exec-queue
}

revert_hook() {
  echo "Rebinding GPU to host and restarting GUI..."

  # 1. Unbind from vfio-pci and clear driver override
  for dev in "${GPU_DEVS[@]}"; do
    echo "$dev" > /sys/bus/pci/drivers/vfio-pci/unbind 2>/dev/null || true
    echo "" > /sys/bus/pci/devices/$dev/driver_override
  done

  # 2. Trigger driver re-probe for GPU devices
  for dev in "${GPU_DEVS[@]}"; do
    echo 1 > /sys/bus/pci/devices/$dev/remove 2>/dev/null || true
  done
  echo 1 > /sys/bus/pci/rescan
  sleep 1

  # 3. Reload nvidia modules (i2c_dev will auto-load as needed)
  modprobe nvidia
  modprobe nvidia_modeset
  modprobe nvidia_uvm
  modprobe nvidia_drm

  # 4. Rebind GPU audio to snd_hda_intel if not auto-bound
  if [[ ! -e /sys/bus/pci/devices/0000:01:00.1/driver ]]; then
    echo 0000:01:00.1 > /sys/bus/pci/drivers/snd_hda_intel/bind 2>/dev/null || true
  fi

  # 5. Re-bind vtconsoles and EFI framebuffer
  for vtcon in /sys/class/vtconsole/vtcon*/bind; do
    echo 1 > "$vtcon" 2>/dev/null || true
  done
  echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind 2>/dev/null || true

  # 6. Restart graphical session
  systemctl isolate graphical.target
}

if [[ "$HOOK_NAME" == "prepare" && "$STATE" == "begin" ]]; then
  start_hook
elif [[ "$HOOK_NAME" == "release" && "$STATE" == "end" ]]; then
  revert_hook
fi
