FROM openjdk:8-jdk

WORKDIR /

# Install required tools
RUN apt update && apt install -y tar unzip libglu1 libpulse-dev libasound2 libc6  libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxi6  libxtst6 libnss3 wget

# Install Build Essentials
RUN apt-get update \
    && apt-get install build-essential -y

# Set Environment Variables
ENV SDK_URL="https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip" \
    ANDROID_HOME="/usr/local/android-sdk" \
    ANDROID_VERSION=30

# Download Android SDK
RUN wget "$SDK_URL" -P /tmp \
    && unzip -d "$ANDROID_HOME" /tmp/sdk-tools-linux-4333796.zip \
    && export PATH=$PATH:$ANDROID_HOME/tools/bin \
    && mkdir /root/.android/ \
    && touch /root/.android/repositories.cfg \
    && yes | sdkmanager --licenses \
    && sdkmanager "build-tools;30.0.3" \
       "platforms;android-${ANDROID_VERSION}" \
       "platform-tools"

CMD ["/bin/bash"]