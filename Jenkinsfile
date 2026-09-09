pipeline {
    agent any

    tools {
        jdk 'jdk17'
        nodejs 'node20'   // Node.js 20 LTS
    }

    environment {
        SCANNER_HOME = tool 'SonarQubeServer'
        DOCKER_IMAGE = 'Clone/swiggy'
        DOCKER_TAG   = 'latest'
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout from Git') {
            steps {
                git branch: 'main', 
                    url: 'https://github.com/knb2807/Swiggy-clone'
            }
        }

        stage('SonarQube Code Analysis') {
            steps {
                withSonarQubeEnv('SonarQubeServer') {
                    sh """
                        $SCANNER_HOME/bin/SonarQubeServer \
                          -Dsonar.projectKey=Swiggy \
                          -Dsonar.projectName=Swiggy \
                          -Dsonar.sources=.
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    timeout(time: 2, unit: 'MINUTES') {
                        waitForQualityGate abortPipeline: true
                    }
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh "npm install"
            }
        }

        stage('Trivy Filesystem Security Scan') {
            steps {
                sh "trivy fs . --exit-code 0 --severity HIGH,CRITICAL -f table -o trivy-fs-report.txt"
                archiveArtifacts artifacts: 'trivy-fs-report.txt', allowEmptyArchive: true
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker-hub-credentials') {
                        sh """
                            docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                        """
                    }
                }
            }
        }

        stage('Trivy Image Vulnerability Scan') {
            steps {
                sh "trivy image ${DOCKER_IMAGE}:${DOCKER_TAG} --exit-code 0 --severity HIGH,CRITICAL -f table -o trivy-image-report.txt"
                archiveArtifacts artifacts: 'trivy-image-report.txt', allowEmptyArchive: true
            }
        }

        stage('Deploy to Container') {
            steps {
                sh """
                    docker rm -f swiggy || true
                    docker run -d --name swiggy -p 3000:3000 ${DOCKER_IMAGE}:${DOCKER_TAG}
                """
            }
        }
    }

    post {
        always {
            echo "Pipeline execution finished."
        }
        success {
            echo "🎉 Swiggy Application deployed successfully to production container!"
        }
        failure {
            echo "❌ Pipeline failed! Please review stage logs and security reports."
        }
    }
}
