pipeline {
    agent any

    environment {
        IMAGE_NAME = "eightbyte-app"
        CONTAINER_NAME = "eightbyte-app"
        APP_PORT = "3000"
        APP_URL = "http://localhost:3000/health"
    }

    stages {

        stage('Test') {
            steps {
                dir('app') {
                    sh '''
                        set -e
                        node --version
                        npm --version
                        npm ci --no-audit --no-fund
                        npm test -- --runInBand
                    '''
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    set -e
                    docker build -t ${IMAGE_NAME}:latest ./app
                '''
            }
        }

        stage('Deploy to EC2') {
            steps {
                sh '''
                    set -e

                    docker rm -f ${CONTAINER_NAME} 2>/dev/null || true

                    docker run -d \
                      --name ${CONTAINER_NAME} \
                      -p ${APP_PORT}:${APP_PORT} \
                      ${IMAGE_NAME}:latest

                    sleep 5

                    docker ps --filter name=${CONTAINER_NAME}
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    set -e

                    curl -f ${APP_URL}

                    echo ""
                    echo "Application is healthy!"
                '''
            }
        }
    }

    post {
        success {
            echo '8Byte CI/CD pipeline completed successfully!'
        }

        failure {
            echo '8Byte deployment failed!'
        }
    }
}