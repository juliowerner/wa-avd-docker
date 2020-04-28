FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
	&& apt-get install -y --no-install-recommends locales\
	curl unzip openjdk-8-jdk \
  xvfb x11vnc xterm supervisor \
  novnc net-tools python3-numpy \
  qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virt-manager \
  && apt autoclean -y \
  && apt autoremove -y \
  && rm -rf /var/lib/apt/lists/*

RUN useradd -G kvm,libvirt,libvirt-qemu -ms /bin/bash avd

# Configure timezone
RUN ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && dpkg-reconfigure --frontend noninteractive tzdata

# Locale
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
RUN touch /etc/locale.gen && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen && update-locale

# Create directory volumes
RUN mkdir -p /home/avd/.android /home/avd/android-sdk/platforms  /home/avd/android-sdk/system-images
RUN chown avd:avd /home/avd/.android /home/avd/android-sdk /home/avd/android-sdk/platforms  /home/avd/android-sdk/system-images

USER avd
WORKDIR /home/avd

ENV ANDROID_HOME /home/avd/android-sdk
ENV ANDROID_SDK_ROOT ${ANDROID_HOME}
ENV PATH $PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator
ENV LD_LIBRARY_PATH ${ANDROID_HOME}/emulator/lib64:${ANDROID_HOME}/emulator/lib64/qt/lib

# Installing Android SDK Commandline tools
ARG CMD_TOOLS_VERSION="6200805"
RUN curl "https://dl.google.com/android/repository/commandlinetools-linux-${CMD_TOOLS_VERSION}_latest.zip" --output commandlinetools.zip && \
    unzip commandlinetools.zip -d $ANDROID_HOME && rm commandlinetools.zip

# Accept license and install required android SDK packages
RUN yes | ${ANDROID_HOME}/tools/bin/sdkmanager "tools" "platform-tools" --sdk_root=${ANDROID_HOME}

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ADD whatsapp.apk .
ADD start.sh .
ADD install-wapp.sh .

EXPOSE 6080
EXPOSE 5900

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
