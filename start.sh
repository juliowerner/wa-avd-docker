#!/bin/bash
set -e
echo "***** Entry Point ***"
export AVD_NAME="WappAVD"
export ANDROID_VERSION="23"
mkdir -p ~/.android/avd
# Create the kvm node (required --privileged)
if [ ! -e /dev/kvm ]; then
    echo "KVM not found, trying to create"
    mknod /dev/kvm c 10 $(grep '\<kvm\>' /proc/misc | cut -f 1 -d' ')
fi
echo "Nice, there is KVM"

# Install Platforms and SystemImages
${ANDROID_HOME}/tools/bin/sdkmanager "platforms;android-${ANDROID_VERSION}" "system-images;android-${ANDROID_VERSION};default;x86_64" --sdk_root=${ANDROID_HOME}

# Create WappAVD, if it doesn't already exist
AVD_NAME="WappAVD"
echo "Searching ${AVD_NAME}..."
search() {
  ${ANDROID_HOME}/tools/bin/avdmanager list avd | grep ${AVD_NAME} | wc -l
}
FOUND=$(search)
if [ $FOUND -eq "0" ]; then
    echo "Creating ${AVD_NAME}..."
    echo "no" | ${ANDROID_HOME}/tools/bin/avdmanager create avd -n ${AVD_NAME} -k "system-images;android-${ANDROID_VERSION};default;x86_64" -c 1000M
    echo 'hw.keyboard=yes' >> /home/avd/.android/avd/${AVD_NAME}.avd/config.ini # enable hardware keyboard input
    echo 'hw.camera.back=webcam0' >> /home/avd/.android/avd/${AVD_NAME}.avd/config.ini # enable webcam
    echo 'vm.heapSize=48' >> /home/avd/.android/avd/${AVD_NAME}.avd/config.ini
else
    echo "${AVD_NAME} already exists"
fi

# Remove locks
rm -f /home/avd/.android/avd/${AVD_NAME}.avd/hardware-qemu.ini.lock

# Start Android emulator and install WhatsApp
/home/avd/install-wapp.sh & DISPLAY=:0 ${ANDROID_HOME}/tools/emulator -avd ${AVD_NAME}  -gpu off -no-audio -netfast
