# Raspberry Pi OS Lite image with Ansible

This repository builds a Raspberry Pi OS Lite image for 64-bit Raspberry Pi devices. The image includes Ansible. The repository uses pi-gen, the official Raspberry Pi OS image builder.

## Contents

- `pi-gen/` — the pi-gen git submodule (arm64 branch)
- `stage-custom/` — the custom stage
- `config` — the build configuration
- `build.sh` — the build script
- `.github/workflows/build.yml` — the GitHub Actions workflow

## How the build works

pi-gen builds the OS in stages. Stage 0 installs the base Debian system. Stage 1 makes the system bootable. Stage 2 produces Raspberry Pi OS Lite. The custom stage `stage-custom` runs after stage 2. This stage installs the `ansible` package. This stage also removes the `rpi-connect-lite` package (Raspberry Pi Connect). The image then has no Connect service.

The `STAGE_LIST` value in `config` selects the stages for the build. The stages 3, 4, and 5 produce the desktop images. This build does not use these stages.

Stage 2 also exports a stock Lite image. The file `SKIP_IMAGES` stops this export. The script `build.sh` creates this file before each build. As a result, the build exports only the Ansible image.

## Requirements

The host machine needs:

- Docker
- git
- 15 GB of free disk space

arm64 hosts build natively. These hosts need no QEMU. Apple silicon Macs are arm64 hosts.

Linux x86_64 hosts build with emulation. These hosts need:

- qemu-user-static and qemu-user (Ubuntu), or qemu-user-static-binfmt and qemu-user (Arch)
- a 64-bit kernel with binfmt_misc support

The static QEMU package registers the QEMU interpreter with the kernel at boot time. pi-gen does a check that the dynamic `qemu-user` package is present. No manual setup is necessary.

Emulated builds on x86_64 hosts can fail. Use an arm64 host when you can.

### Ubuntu

1. Install the packages:

   ```
   sudo apt install -y docker.io docker-compose-v2 qemu-user-static qemu-user git
   ```

2. Add your user to the docker group:

   ```
   sudo usermod -aG docker "$USER"
   ```

3. Log out and log in again.
4. Start the Docker service:

   ```
   sudo systemctl enable --now docker
   ```

5. Make sure that Docker works:

   ```
   docker run --rm hello-world
   ```

### Arch

1. Install the packages:

   ```
   sudo pacman -S docker git qemu-user-static-binfmt qemu-user
   ```

2. Add your user to the docker group:

   ```
   sudo usermod -aG docker "$USER"
   ```

3. Log out and log in again.
4. Start the Docker service:

   ```
   sudo systemctl enable --now docker
   ```

5. Make sure that Docker works:

   ```
   docker run --rm hello-world
   ```

If `/proc/sys/fs/binfmt_misc` is empty, load the kernel module:

```
sudo modprobe binfmt_misc
```

### macOS (Apple silicon)

You can build this image on a Mac with an M-series chip. Docker Desktop runs arm64 Linux natively on these Macs. The build needs no QEMU on macOS.

1. Install Docker Desktop. Then start it.
2. Increase the resources of the VM. Open Settings, then Resources. Set at least 4 CPUs, 4 GB of memory, and 40 GB of disk.
3. Keep the repository in a path without spaces. pi-gen cannot build from a path with spaces.
4. Make sure that Docker works:

   ```
   docker run --rm hello-world
   ```

5. Build the image:

   ```
   ./build.sh
   ```

The first build takes 1 to 2.5 hours on a Mac. The build is slower on a Mac than on Linux.

If the build fails at the image export step with a loop device error, update Docker Desktop. Loop device support needs a recent Docker Desktop version.

CI builds run on Linux only. The macOS steps have no CI coverage.

## Build

Run this command in the repository root:

```
./build.sh
```

The first build takes 30 to 90 minutes. The script runs the build in a Docker container. The script creates the container and removes it after the build.

If the build fails, read the log in `pi-gen/deploy/build-docker.log`.

The image is in this location:

```
pi-gen/deploy/<date>-raspios-lite-ansible-ansible.img.xz
```

The `<date>` value is the build date.

## Flash the image

1. Open Raspberry Pi Imager.
2. Choose your device.
3. Choose "Use custom" under Operating System. Then select the `.img.xz` file.
4. Open the OS customization settings (gear icon). Set SSH, the user name, Wi-Fi, and the host name.
5. Write the image to the SD card.

The Pi Imager settings apply at first boot. These settings override the baked values, for example the host name.

## Check the image without hardware

1. Decompress the image:

   ```
   xz -dk pi-gen/deploy/<date>-raspios-lite-ansible-ansible.img.xz
   ```

2. Attach the image to a loop device:

   ```
   sudo losetup -fP pi-gen/deploy/<date>-raspios-lite-ansible-ansible.img
   ```

3. Find the loop device name:

   ```
   lsblk
   ```

4. Mount the second partition (the root filesystem):

   ```
   sudo mount /dev/loopNp2 /mnt
   ```

   Replace `loopN` with the name from step 3.

5. Make sure that Ansible is present:

   ```
   ls /mnt/usr/bin/ansible-playbook
   ```

6. Clean up:

   ```
   sudo umount /mnt
   sudo losetup -d /dev/loopN
   ```

You can also boot the image on a Raspberry Pi. Then run `ansible --version`.

## Update pi-gen

```
git submodule update --remote
./build.sh
```

The custom stage and the config live outside pi-gen. An update of pi-gen does not touch these files.

## Configuration

The `config` file sets these values:

- `IMG_NAME` — the image name (raspios-lite-ansible)
- `RELEASE` — the Debian release (trixie)
- `DEPLOY_COMPRESSION` — the archive format (xz)
- `TIMEZONE_DEFAULT` — the default time zone (Australia/Melbourne)
- `TARGET_HOSTNAME` — a placeholder host name (raspberrypi). You can set a host name in Pi Imager. Then Pi Imager overrides this value.
- `ENABLE_SSH` — 0. SSH stays off in the image. You can turn SSH on in Pi Imager for each flash.

## CI builds

The GitHub Actions workflow builds the image each week on a native arm64 runner (`ubuntu-24.04-arm`). The build needs no emulation there. You can start a build manually on the Actions tab of the repository. The workflow uploads the image as an artifact. Artifacts expire after 14 days.

Arm64 runners are free for public repositories. For private repositories, these runners use more credits than x64 runners.
