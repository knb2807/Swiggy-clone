pipeline {
    agent any

    tools {
        jdk 'jdk17'
        nodejs 'node20'   // Node.js 20 LTS
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        DOCKER_IMAGE = 'mrknb/cloneswiggy'
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
                withSonarQubeEnv('sonar-scanner') {
                    sh """
                        \$SCANNER_HOME/bin/sonar-scanner \\
                          -Dsonar.projectKey=Swiggy \\
                          -Dsonar.projectName=Swiggy \\
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
                    // This safely binds your Jenkins credentials to environment variables
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh """
                            # Log into DockerHub securely without using the Docker tool plugin
                            echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                            
                            # Build and push your Swiggy Clone image
                            docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                            
                            # Always logout at the end to keep the build agent clean
                            docker logout
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
                    docker rm -f cloneswiggy || true
                    docker run -d --name cloneswiggy -p 3000:3000 ${DOCKER_IMAGE}:${DOCKER_TAG}
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

