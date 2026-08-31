```groovy
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
                    docker build -t ${IMAGE_NAME}:latest ./app
                    docker images ${IMAGE_NAME}:latest
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

                    docker ps --filter "name=${CONTAINER_NAME}"
                    docker logs ${CONTAINER_NAME} --tail 20
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    set -e

                    echo "Checking application health..."

                    for i in 1 2 3 4 5; do
                        if curl -fsS ${APP_URL}; then
                            echo ""
                            echo "Application is healthy!"
                            exit 0
                        fi

                        echo "Health check failed. Retrying..."
                        sleep 3
                    done

                    echo "Application health check failed."
                    docker logs ${CONTAINER_NAME} --tail 50
                    exit 1
                '''
            }
        }
    }

    post {
        success {
            echo '8Byte CI/CD pipeline completed successfully!'
        }

        failure {
            echo '8Byte CI/CD pipeline failed!'
            sh 'docker logs ${CONTAINER_NAME} --tail 50 || true'
        }
    }
}
```
