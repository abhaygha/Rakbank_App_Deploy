pipeline {
    agent any

    environment {
        SONAR_HOST_URL = 'https://sonarcloud.io'
        AWS_REGION = 'us-east-1'
        ECR_REGISTRY = '891377120087.dkr.ecr.us-east-1.amazonaws.com'
        ECR_REPOSITORY = 'rakbank'
        JAVA_HOME = '/opt/hostedtoolcache/Java_Temurin-Hotspot_jdk/17.0.11-9/x64'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Secrets Scan') {
            steps {
                script {
                    // Checkout code again for Gitleaks scan
                    checkout scm
                    sh 'docker run --rm -v $(pwd):/path zricethezav/gitleaks:latest detect --source /path'
                }
            }
        }

        stage('Quality Check') {
            environment {
                SONAR_TOKEN = credentials('sonar-token')
            }
            steps {
                script {
                    checkout scm
                    sh """
                        echo 'Setting up JDK 17'
                        export JAVA_HOME=${tool name: 'JDK 17', type: 'hudson.model.JDK'}
                        export PATH=\$JAVA_HOME/bin:\$PATH
                        mvn clean verify
                        mvn sonar:sonar -Dsonar.projectKey=abhaygha_Rakbank_App_Deploy -Dsonar.organization=abhaygha -Dsonar.host.url=${SONAR_HOST_URL} -Dsonar.login=${SONAR_TOKEN}
                    """
                    def qualityGateStatus = sh(script: "curl -s -H \"Authorization: token ${SONAR_TOKEN}\" -X GET \"${SONAR_HOST_URL}/api/qualitygates/project_status?projectKey=abhaygha_Rakbank_App_Deploy\" | jq -r '.projectStatus.status'", returnStdout: true).trim()
                    def coverage = sh(script: "curl -s -H \"Authorization: token ${SONAR_TOKEN}\" -X GET \"${SONAR_HOST_URL}/api/measures/component?component=abhaygha_Rakbank_App_Deploy&metricKeys=coverage\" | jq -r '.component.measures[0].value' | sed 's/%//'", returnStdout: true).trim()
                    echo "Quality Gate Status: ${qualityGateStatus}"
                    echo "Coverage: ${coverage}"

                    if (qualityGateStatus != 'OK') {
                        error 'Quality Gate failed!'
                    }

                    if (coverage.toFloat() < 30) {
                        error 'Coverage below 30%!'
                    }
                }
            }
        }

        stage('Build') {
            steps {
                script {
                    checkout scm
                    sh """
                        echo 'Setting up JDK 17'
                        export JAVA_HOME=${tool name: 'JDK 17', type: 'hudson.model.JDK'}
                        export PATH=\$JAVA_HOME/bin:\$PATH
                        mvn clean package
                    """
                }
            }
        }

        stage('Push to ECR') {
            environment {
                AWS_CREDENTIALS = credentials('aws-credentials')
            }
            steps {
                script {
                    checkout scm
                    withAWS(role: 'arn:aws:iam::891377120087:role/github-action-role', region: "${AWS_REGION}") {
                        sh 'aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}'
                        def version = sh(script: "git describe --tags --always", returnStdout: true).trim()
                        echo "VERSION=${version}"
                        sh """
                            docker build --no-cache -t ${ECR_REGISTRY}/${ECR_REPOSITORY}:${version} .
                            docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${version}
                        """
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    checkout scm
                    sh """
                        chmod +x ./deploy.sh
                        export KUBECONFIG=$HOME/.kube/config
                        ./deploy.sh ${version}
                    """
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
