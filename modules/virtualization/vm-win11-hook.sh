#!/run/current-system/sw/bin/bash
set -xe

readonly GUEST_NAME="$1"
readonly HOOK_NAME="$2"
readonly STATE="$3"

# Only act on our target VM
if [[ "$GUEST_NAME" != "win11" ]]; then exit 0; fi

start_hook() {
  echo "Stopping Niri/GUI and unbinding GPU from host..."
  systemctl stop display-manager.service

  mapfile -t GPU_PIDS < <(
    { /run/current-system/sw/bin/nvidia-smi --query-compute-apps=pid --format=csv,noheader;
      /run/current-system/sw/bin/nvidia-smi pmon -c 1 | tail -n +2 | /run/current-system/sw/bin/awk '{print $2}';
    } | sort -u | grep -E '^[0-9]+$'
  )
  
  for pid in "${GPU_PIDS[@]}"; do
    # if the PID disappears between the query and the signal, just continue
    kill -SIGKILL "$pid" 2>/dev/null || true
  done
  
  echo "Killed GPU PIDs: ${GPU_PIDS[*]}"

  sleep 2

  # Unload Nvidia drivers
  modprobe -r nvidia_drm 
  modprobe -r nvidia_uvm 
  modprobe -r nvidia_modeset 
  modprobe -r nvidia

  # Unbind virtual consoles and EFI framebuffer
  echo 0 > /sys/class/vtconsole/vtcon0/bind  || true
  echo 0 > /sys/class/vtconsole/vtcon1/bind  || true
  echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind  || true

  sleep 2

  # Detach GPU devices from host
  virsh nodedev-detach pci_0000_01_00_0 || true
  virsh nodedev-detach pci_0000_01_00_1 || true

  modprobe vfio
  modprobe vfio_pci
  modprobe vfio_iommu_type1
}

revert_hook() {
  echo "Rebinding GPU to host and restarting GUI..."

  virsh nodedev-reattach pci_0000_01_00_0 || true
  virsh nodedev-reattach pci_0000_01_00_1 || true

  # Load Nvidia drivers back
  modprobe nvidia 
  modprobe nvidia_modeset 
  modprobe nvidia_uvm 
  modprobe nvidia_drm

  # Re-bind EFI framebuffer and vtconsoles (so text console works again)
  echo 1 > /sys/class/vtconsole/vtcon0/bind || true
  echo 1 > /sys/class/vtconsole/vtcon1/bind || true

  echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind || true

  # Restart graphical session (Niri)
  systemctl start display-manager.service
}

if [[ "$HOOK_NAME" == "prepare" && "$STATE" == "begin" ]]; then
  start_hook
elif [[ "$HOOK_NAME" == "release" && "$STATE" == "end" ]]; then
  revert_hook
fi
