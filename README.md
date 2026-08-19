# Raspberry Pi OS Lite image with Ansible

This repository builds a Raspberry Pi OS Lite image for 64-bit Raspberry Pi devices. The image includes Ansible. The repository uses pi-gen, the official Raspberry Pi OS image builder.

## Contents

- `pi-gen/` — the pi-gen git submodule (arm64 branch)
- `stage-ansible/` — the custom stage that installs Ansible
- `config` — the build configuration
- `build.sh` — the build script
- `.github/workflows/build.yml` — the GitHub Actions workflow

## How the build works

pi-gen builds the OS in stages. Stage 0 installs the base Debian system. Stage 1 makes the system bootable. Stage 2 produces Raspberry Pi OS Lite. The custom stage `stage-ansible` runs after stage 2. It installs the `ansible` package with apt.

The `STAGE_LIST` value in `config` selects the stages for the build. The stages 3, 4, and 5 produce the desktop images. This build does not use them.

By default, stage 2 also exports a stock Lite image. The file `SKIP_IMAGES` stops this export. The script `build.sh` creates this file before each build. As a result, the build exports only the Ansible image.

## Requirements

The host machine needs:

- Docker
- qemu-user-static (Ubuntu 24.04 or newer; older Ubuntu also needs qemu-user-binfmt) or qemu-user-static and qemu-user-static-binfmt (Arch)
- git
- 15 GB of free disk space
- a 64-bit kernel with binfmt_misc support

The build emulates arm64. It needs a static QEMU interpreter for that. `setup-host.sh` registers one. This registration is not persistent. Run `sudo ./setup-host.sh` again after each reboot.

### Ubuntu

1. Install the packages:

   ```
   sudo apt install -y docker.io docker-compose-v2 qemu-user-static git
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

6. Register the static QEMU interpreter:

   ```
   sudo ./setup-host.sh
   ```

### Arch

The QEMU packages are in the official `extra` repository. You do not need the AUR.

1. Install the packages:

   ```
   sudo pacman -S docker git qemu-user-static qemu-user-static-binfmt
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

6. Register the static QEMU interpreter:

   ```
   sudo ./setup-host.sh
   ```

If `/proc/sys/fs/binfmt_misc` is empty, load the kernel module:

```
sudo modprobe binfmt_misc
```

## Build

Run this command in the repository root:

```
./build.sh
```

The first build takes 30 to 90 minutes. The script runs the build in a Docker container. It creates the container and removes it after the build.

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

The Pi Imager settings apply at first boot. They override the baked values, such as the host name.

## Verify the image without hardware

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

The custom stage and the config live outside pi-gen. An update of pi-gen does not touch them.

## Configuration

The `config` file sets these values:

- `IMG_NAME` — the image name (raspios-lite-ansible)
- `RELEASE` — the Debian release (trixie)
- `DEPLOY_COMPRESSION` — the archive format (xz)
- `TIMEZONE_DEFAULT` — the default time zone (Australia/Melbourne)
- `TARGET_HOSTNAME` — a placeholder host name (raspberrypi). Pi Imager overrides it if you set a host name there.
- `ENABLE_SSH` — 0. SSH stays off in the image. Pi Imager turns it on per flash if you set it there.

## CI builds

The GitHub Actions workflow builds the image each week. You can also start a build by hand on the Actions tab of the repository. The workflow uploads the image as an artifact. Artifacts expire after 14 days.
