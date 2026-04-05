#!/run/current-system/sw/bin/bash
set -xe

# libvirtd sets its own PATH for hook subprocesses which doesn't include
# system packages. Add /run/current-system/sw/bin for fuser (psmisc), etc.
export PATH="/run/current-system/sw/bin:$PATH"

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

  # 2. Unbind vtconsoles BEFORE switching targets — prevents fbcon from grabbing
  #    nvidia's fbdev during the target transition (nvidia-drm.fbdev=1 creates
  #    a kernel fbdev that fbcon latches onto for console output).
  for vtcon in /sys/class/vtconsole/vtcon*/bind; do
    echo 0 > "$vtcon" 2>/dev/null || true
  done
  echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind 2>/dev/null || true

  # 3. Switch to multi-user target (stops display manager and compositor)
  systemctl isolate multi-user.target
  sleep 2

  # 4. Kill all processes holding nvidia/DRI/fb devices open
  fuser -k /dev/nvidia* /dev/dri/card* /dev/dri/renderD* /dev/fb* 2>/dev/null || true
  sleep 1

  # 5. Release logind's DRM master — logind survives multi-user.target and holds
  #    a DRM master fd for seat management, preventing nvidia_drm unload.
  loginctl terminate-seat seat0 2>/dev/null || true
  sleep 1

  # 6. Pause udev to prevent it from reloading nvidia modules during teardown.
  #    Trap ensures udev is resumed even if the hook fails partway through.
  trap 'udevadm control --start-exec-queue 2>/dev/null' EXIT
  udevadm control --stop-exec-queue

  # 7. Unload nvidia_drm — retry if refs haven't drained yet.
  for attempt in 1 2 3 4 5; do
    if modprobe -r nvidia_drm 2>/dev/null; then break; fi
    echo "nvidia_drm still in use (attempt $attempt, refcnt=$(cat /sys/module/nvidia_drm/refcnt 2>/dev/null))"
    fuser -k /dev/dri/card* /dev/dri/renderD* /dev/fb* 2>/dev/null || true
    sleep 2
  done
  modprobe -r nvidia_drm

  modprobe -r nvidia_uvm
  modprobe -r nvidia_modeset

  # 8. Unload i2c_dev if loaded — holds refs on nvidia via I2C adapters
  fuser -k /dev/i2c-* 2>/dev/null || true
  modprobe -r i2c_dev 2>/dev/null || true

  # 9. Unload nvidia
  modprobe -r nvidia

  # 10. Load VFIO and bind GPU
  modprobe vfio_pci
  modprobe vfio_iommu_type1

  for dev in "${GPU_DEVS[@]}"; do
    if [[ -e /sys/bus/pci/devices/$dev/driver ]]; then
      echo "$dev" > /sys/bus/pci/devices/$dev/driver/unbind 2>/dev/null || true
    fi
    echo "vfio-pci" > /sys/bus/pci/devices/$dev/driver_override
    echo "$dev" > /sys/bus/pci/drivers/vfio-pci/bind
  done

  # 11. Resume udev (also handled by EXIT trap as safety net)
  trap - EXIT
  udevadm control --start-exec-queue
}

revert_hook() {
  echo "Rebinding GPU to host and restarting GUI..."

  # 1. Only touch PCI state if devices are actually on vfio-pci.
  #    When called after a failed prepare hook, devices may still be on nvidia —
  #    writing to driver_override on a bound device blocks on the device mutex.
  for dev in "${GPU_DEVS[@]}"; do
    local current_driver=""
    if [[ -e /sys/bus/pci/devices/$dev/driver ]]; then
      current_driver=$(basename "$(readlink /sys/bus/pci/devices/$dev/driver)")
    fi
    if [[ "$current_driver" == "vfio-pci" ]]; then
      echo "$dev" > /sys/bus/pci/drivers/vfio-pci/unbind 2>/dev/null || true
      echo "" > /sys/bus/pci/devices/$dev/driver_override
    fi
  done

  # 2. Trigger driver re-probe via PCI remove + rescan
  for dev in "${GPU_DEVS[@]}"; do
    if [[ -e /sys/bus/pci/devices/$dev ]] && [[ ! -e /sys/bus/pci/devices/$dev/driver ]]; then
      echo 1 > /sys/bus/pci/devices/$dev/remove 2>/dev/null || true
    fi
  done
  echo 1 > /sys/bus/pci/rescan
  sleep 1

  # 3. Reload nvidia modules if not already loaded
  modprobe nvidia 2>/dev/null || true
  modprobe nvidia_modeset 2>/dev/null || true
  modprobe nvidia_uvm 2>/dev/null || true
  modprobe nvidia_drm 2>/dev/null || true

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
