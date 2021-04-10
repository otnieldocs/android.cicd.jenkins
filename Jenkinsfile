class Constants {
    static final String MASTER_BRANCH = 'master'

    static final String QA_BUILD = 'Debug'
    static final String RELEASE_BUILD = 'Release'

    static final String INTERNAL_TRACK = 'internal'
    static final String RELEASE_TRACK = 'release'

    static final String ANDROID_VERSION = '30'
    static final String BUILD_VERSION = '30.0.3'
    static final String IMAGE_BUILD = '1'
    static final String IMAGE_NAME = 'android-build-env'
    static final String DOCKER_USERNAME = 'otnieldocs'
    static final String IMAGE_VERSION = DOCKER_USERNAME + '/' + IMAGE_NAME + ':' + ANDROID_VERSION + '_' + BUILD_VERSION + '_' + IMAGE_BUILD
}

def ANDROID_HOME='/usr/local/android-sdk'
def ADB="$ANDROID_HOME/platform-tools/adb"


def getBuildType() {
    switch(env.BRANCH_NAME) {
        case Constants.MASTER_BRANCH:
            return Constants.RELEASE_BUILD
        default:
            return Constants.QA_BUILD
    }
}

def getTrackType() {
    switch(env.BRANCH_NAME) {
        case Constants.MASTER_BRANCH:
            return Constants.RELEASE_TRACK
        default:
            return Constants.INTERNAL_TRACK
    }
}

def isDeployCandidate() {
    return ("${env.BRANCH_NAME}" =~ /(develop|master)/)
}

pipeline {
    agent {
        docker {
            image "${Constants.IMAGE_VERSION}"
        }
    }
    environment {
        appName = 'app-jenkins'

        KEY_PASSWORD = credentials('keyPassword')
        KEY_ALIAS = credentials('keyAlias')
        KEYSTORE = credentials('keystore')
        STORE_PASSWORD = credentials('storePassword')
    }
    stages {
        stage('Run Tests') {
            steps {
                echo 'Running Tests'
                script {
                    // todo: add some checking for specific build variant here, uncomment if you need this
                    // VARIANT = getBuildType()

                    COMMAND = "./gradlew test"

                    if (isUnix()) {
                        sh "${COMMAND}"
                    } else {
                        bat "${COMMAND}"
                    }

                }
            }
        }
        stage('Run Instrumentation Tests') {
            sh "$ADB start-server"
            def error
            parallel {
                launchEmulator {
                    sh "$ANDROID_HOME/tools/qemu/linux-x86_64/qemu-system-x86_64 -engine classic -prop persist.sys.language=en -prop persist.sys.country=US -avd test -no-snapshot-load -no-snapshot-save -no-window"
                }
                runAndroidTests: {
                    timeout(time: 20, unit: 'SECONDS') {
                      sh "$ADB wait-for-device"
                    }
                    try {
                        sh "./gradlew :MyKet:connectedAndroidTest"
                    } catch(e) {
                        error = e
                    }
                    sh script: '/var/lib/jenkins/kill-emu.sh'
                }
            }
            if (error != null) {
                throw error
            }
        }
        stage('Build Bundle') {
            when { expression { return isDeployCandidate() } }
            steps {
                echo 'Building'
                script {
                    VARIANT = getBuildType()

                    COMMAND = "./gradlew -PstorePass=${STORE_PASSWORD} -Pkeystore=${KEYSTORE} -Palias=$KEY_ALIAS -PkeyPass=${KEY_PASSWORD} bundle${VARIANT}"

                    if (isUnix()) {
                        sh "${COMMAND}"
                    } else {
                        bat "${COMMAND}"
                    }
                }
            }
        }
        stage('Deploy App to Store') {
            when { expression { return isDeployCandidate() } }
            steps {
                echo 'Deploying'
                script {
                    VARIANT = getBuildType()
                    TRACK = getTrackType()

                    if (TRACK == Constants.RELEASE_TRACK) {
                        timeout(time: 5, unit: 'MINUTES') {
                            input "Proceed with deployment to ${TRACK}?"
                        }
                    }

                    try {
                        CHANGELOG = readFile(file: 'CHANGELOG.txt')
                    } catch (err) {
                        echo "Issue reading CHANGELOG.txt file: ${err.localizedMessage}"
                        CHANGELOG = ''
                    }

                    androidApkUpload googleCredentialsId: 'play-store-credentials',
                            filesPattern: "**/outputs/bundle/${VARIANT.toLowerCase()}/*.aab",
                            trackName: TRACK,
                            recentChangeList: [[language: 'en-US', text: CHANGELOG]]
                }
            }
        }
    }
}