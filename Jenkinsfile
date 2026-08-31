pipeline {
    agent any

    environment {
        IMAGE_NAME = "eightbyte-app"
        CONTAINER_NAME = "eightbyte-app"
        APP_PORT = "3000"
        HOST_PORT = "3000"
    }

    stages {

        stage('Test') {
            steps {
                dir('app') {
                    sh '''
                        set -e
                        echo "Node: $(node --version)"
                        echo "NPM: $(npm --version)"

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
                    docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} ./app
                    docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${IMAGE_NAME}:latest
                '''
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    set -e

                    docker rm -f ${CONTAINER_NAME} 2>/dev/null || true

                    docker run -d \
                      --name ${CONTAINER_NAME} \
                      -p ${HOST_PORT}:${APP_PORT} \
                      ${IMAGE_NAME}:latest

                    sleep 5

                    docker ps --filter "name=${CONTAINER_NAME}"
                '''
            }
        }

        stage('Verify') {
            steps {
                sh '''
                    set -e

                    echo "Checking application..."

                    curl --fail --silent \
                      http://localhost:${HOST_PORT}/health

                    echo ""
                    echo "Application is healthy!"
                '''
            }
        }
    }

    post {
        success {
            echo "8Byte deployment completed successfully!"
        }

        failure {
            echo "8Byte deployment failed!"
        }
    }
}