FROM openjdk:8-jdk

WORKDIR /

# Install Build Essentials
RUN apt-get update \
    && apt-get install build-essential -y

# Set Environment Variables
ENV SDK_URL="https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip" \
    ANDROID_HOME="/usr/local/android-sdk" \
    ANDROID_VERSION=29

# Download Android SDK
RUN wget "$SDK_URL" -P /tmp \
    && unzip -d "$ANDROID_HOME" /tmp/sdk-tools-linux-4333796.zip \
    && export PATH=$PATH:$ANDROID_HOME/tools/bin \
    && mkdir /root/.android/ \
    && touch /root/.android/repositories.cfg \
    && echo y | sdkmanager --licenses

# Install Android Build Tool and Libraries
RUN $ANDROID_HOME/tools/bin/sdkmanager --update
RUN $ANDROID_HOME/tools/bin/sdkmanager "build-tools;29.0.2" \
    "platforms;android-${ANDROID_VERSION}" \
    "platform-tools"

CMD ["/bin/bash"]