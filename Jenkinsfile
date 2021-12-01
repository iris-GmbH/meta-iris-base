// SPDX-License-Identifier: MIT
// Copyright (C) 2021 iris-GmbH infrared & intelligent sensors

pipeline {
    agent any
    options {
        disableConcurrentBuilds()
    }
    environment {
        // S3 bucket for saving release artifacts
        S3_BUCKET = 'iris-devops-artifacts-693612562064'

        // S3 bucket for temporary artifacts
        S3_TEMP_BUCKET = 'iris-devops-tempartifacts-693612562064'
    }
    stages {
        stage('Preparation Stage') {
            steps {
                // clean workspace
                cleanWs disableDeferredWipeout: true, deleteDirs: true
                // checkout iris-kas repo
                checkout([$class: 'GitSCM',
                    branches: [[name: '*/develop']],
                    extensions: [[$class: 'CloneOption',
                    noTags: false,
                    reference: '',
                    shallow: false]],
                    userRemoteConfigs: [[url: 'https://github.com/iris-GmbH/iris-kas.git']]])

                // if this is a PR branch, the env variable "CHANGE_BRANCH" will contain the real branch name, which we need for checkout later on
                script {
                    if (env.CHANGE_BRANCH) {
                        env.REAL_GIT_BRANCH = env.CHANGE_BRANCH
                    }
                    else {
                        env.REAL_GIT_BRANCH = env.GIT_BRANCH
                    }
                }
                // try to checkout identical named branch in iris-kas, do not checkout master or PR branch
                sh """if [ \"\$(basename ${REAL_GIT_BRANCH})\" != \"master\" ] && \$(echo \"${REAL_GIT_BRANCH}\" | grep -vqE '^release/.*'); then
                        git checkout \"${REAL_GIT_BRANCH}\" || true;
                    fi"""
                // manually upload kas sources to S3, as to prevent upload conflicts in parallel steps
                zip dir: '', zipFile: 'iris-kas-sources.zip'
                s3Upload acl: 'Private',
                    bucket: "${S3_BUCKET}",
                    file: 'iris-kas-sources.zip',
                    path: "${JOB_NAME}/${GIT_COMMIT}/iris-kas-sources.zip",
                    payloadSigningEnabled: true,
                    sseAlgorithm: 'AES256'
                sh 'printenv | sort'
            }
        }

        stage('Build Firmware Artifacts') {
            matrix {
                axes {
                    axis {
                        name 'MULTI_CONF'
                        values 'sc573-gen6', 'imx8mp-evk', 'qemux86-64-r1', 'qemux86-64-r2'
                    }
                    axis {
                        name 'IMAGES'
                        values 'irma6-deploy irma6-maintenance irma6-dev', 'irma6-test'
                    }
                    axis {
                        name 'SDK_IMAGE'
                        values 'irma6-maintenance', 'irma6-test'
                    }
                }
                excludes {
                    exclude {
                        axis {
                            name 'MULTI_CONF'
                            values 'sc573-gen6', 'imx8mp-evk'
                        }
                        axis {
                            name 'IMAGES'
                            values 'irma6-test'
                        }
                        axis {
                            name 'SDK_IMAGE'
                            values 'irma6-maintenance', 'irma6-test'
                        }
                    }
                    exclude {
                        axis {
                            name 'MULTI_CONF'
                            values 'sc573-gen6', 'imx8mp-evk'
                        }
                        axis {
                            name 'IMAGES'
                            values 'irma6-deploy irma6-maintenance irma6-dev'
                        }
                        axis {
                            name 'SDK_IMAGE'
                            values 'irma6-test'
                        }
                    }
                    exclude {
                        axis {
                            name 'MULTI_CONF'
                            values 'qemux86-64-r1', 'qemux86-64-r2'
                        }
                        axis {
                            name 'IMAGES'
                            values 'irma6-deploy irma6-maintenance irma6-dev', 'irma6-test'
                        }
                        axis {
                            name 'SDK_IMAGE'
                            values 'irma6-maintenance'
                        }
                    }
                    exclude {
                        axis {
                            name 'MULTI_CONF'
                            values 'qemux86-64-r1', 'qemux86-64-r2'
                        }
                        axis {
                            name 'IMAGES'
                            values 'irma6-deploy irma6-maintenance irma6-dev'
                        }
                        axis {
                            name 'SDK_IMAGE'
                            values 'irma6-test'
                        }
                    }
                }
                stages {
                    stage('Build Firmware Artifacts') {
                        steps {
                            awsCodeBuild buildSpecFile: 'buildspecs/build_firmware_images_develop.yml',
                                projectName: 'iris-devops-kas-large-amd-codebuild',
                                credentialsType: 'keys',
                                downloadArtifacts: 'false',
                                region: 'eu-central-1',
                                sourceControlType: 'project',
                                sourceTypeOverride: 'S3',
                                sourceLocationOverride: "${S3_BUCKET}/${JOB_NAME}/${GIT_COMMIT}/iris-kas-sources.zip",
                                artifactTypeOverride: 'S3',
                                artifactLocationOverride: "${S3_TEMP_BUCKET}",
                                artifactPathOverride: "${JOB_NAME}/${GIT_COMMIT}",
                                artifactNamespaceOverride: 'NONE',
                                artifactNameOverride: "${MULTI_CONF}-deploy.zip",
                                artifactPackagingOverride: 'ZIP',
                                secondaryArtifactsOverride: """[
                                    {
                                        "artifactIdentifier": "sources",
                                        "type": "S3",
                                        "location": "${S3_TEMP_BUCKET}",
                                        "path": "${JOB_NAME}/${GIT_COMMIT}",
                                        "namespaceType": "NONE",
                                        "name": "${MULTI_CONF}-sources.zip",
                                        "overrideArtifactName": "true",
                                        "packaging": "ZIP"
                                    }
                                ]""",
                                envVariables: """[
                                    { MULTI_CONF, $MULTI_CONF },
                                    { IMAGES, $IMAGES },
                                    { JOB_NAME, $JOB_NAME },
                                    { GIT_BRANCH, $REAL_GIT_BRANCH },
                                    { SDK_IMAGE, $SDK_IMAGE }
                                ]"""
                        }
                        post {
                            success {
                                // temporary archive build within Jenkins after successful build
                                s3Download bucket: "${S3_TEMP_BUCKET}",
                                    path: "${JOB_NAME}/${GIT_COMMIT}/${MULTI_CONF}-deploy.zip",
                                    file: "${MULTI_CONF}-deploy.zip",
                                    payloadSigningEnabled: true
                                unzip zipFile: "${MULTI_CONF}-deploy.zip", dir: "${MULTI_CONF}-deploy"
                                archiveArtifacts artifacts: "${MULTI_CONF}-deploy/**/${MULTI_CONF}-deploy.tar", fingerprint: true
                            }
                        }
                    }
                }
            }
        }

        stage('Run QEMU Tests') {
            matrix {
                axes {
                    axis {
                        name 'MULTI_CONF'
                        values 'qemux86-64-r1', 'qemux86-64-r2'
                    }
                }
                stages {
                    stage('Run QEMU Tests') {
                        steps {
                            awsCodeBuild buildSpecFile: 'buildspecs/qemu_tests.yml',
                                projectName: 'iris-devops-kas-large-amd-qemu-codebuild',
                                credentialsType: 'keys',
                                region: 'eu-central-1',
                                sourceControlType: 'project',
                                sourceTypeOverride: 'S3',
                                sourceLocationOverride: "${S3_BUCKET}/${JOB_NAME}/${GIT_COMMIT}/iris-kas-sources.zip",
                                secondarySourcesOverride: """[
                                    {
                                        "type": "S3",
                                        "location": "${S3_TEMP_BUCKET}/${JOB_NAME}/${GIT_COMMIT}/${MULTI_CONF}-deploy.zip",
                                        "sourceIdentifier": "deploy"
                                    }
                                ]""",
                                artifactTypeOverride: 'S3',
                                artifactLocationOverride: "${S3_TEMP_BUCKET}",
                                artifactPathOverride: "${JOB_NAME}/${GIT_COMMIT}",
                                artifactNamespaceOverride: 'NONE',
                                artifactNameOverride: "${MULTI_CONF}-reports.zip",
                                artifactPackagingOverride: 'ZIP',
                                downloadArtifacts: 'true',
                                envVariables: """[
                                    { MULTI_CONF, $MULTI_CONF }
                                ]"""
                        }
                        post {
                            always {
                                // add test reports to pipeline run
                                unzip zipFile: "${JOB_NAME}/${GIT_COMMIT}/${MULTI_CONF}-reports.zip", dir: "${MULTI_CONF}-reports"
                                junit testResults: "${MULTI_CONF}-reports/**/*.xml", skipPublishingChecks: true
                            }
                        }
                    }
                }
            }
        }
    }
}
