```groovy
pipeline {
    agent any

    options {
        timeout(time: 15, unit: 'MINUTES')
        disableConcurrentBuilds()
        timestamps()
    }

    environment {
        IMAGE_NAME = 'eightbyte-app'
        CONTAINER_NAME = 'eightbyte-app'
        APP_PORT = '3000'
    }

    stages {

        stage('Test') {
            steps {
                dir('app') {
                    sh '''
                        set -e

                        echo "Node:"
                        node --version

                        echo "NPM:"
                        npm --version

                        echo "Installing dependencies..."
                        npm ci --no-audit --no-fund

                        echo "Running tests..."
                        npm test -- --runInBand
                    '''
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    set -e

                    echo "Building Docker image..."
                    docker build --pull -t ${IMAGE_NAME}:latest ./app

                    echo "Docker image created:"
                    docker images ${IMAGE_NAME}
                '''
            }
        }

        stage('Deploy to EC2') {
            steps {
                sh '''
                    set -e

                    echo "Stopping old container if present..."
                    docker rm -f ${CONTAINER_NAME} 2>/dev/null || true

                    echo "Starting new container..."
                    docker run -d \
                      --name ${CONTAINER_NAME} \
                      -p ${APP_PORT}:${APP_PORT} \
                      --restart unless-stopped \
                      ${IMAGE_NAME}:latest

                    echo "Waiting for application..."
                    sleep 5

                    echo "Container status:"
                    docker ps --filter name=${CONTAINER_NAME}

                    echo "Container logs:"
                    docker logs ${CONTAINER_NAME} --tail 30
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    set -e

                    echo "Checking application health..."

                    for i in 1 2 3 4 5; do
                        if curl -fsS http://localhost:${APP_PORT}/health; then
                            echo ""
                            echo "Health check PASSED"
                            exit 0
                        fi

                        echo "Health check failed. Retrying..."
                        sleep 3
                    done

                    echo "Health check FAILED"
                    docker logs ${CONTAINER_NAME}
                    exit 1
                '''
            }
        }
    }

    post {
        success {
            echo '8Byte deployment completed successfully!'
        }

        failure {
            echo '8Byte deployment failed!'
            sh 'docker ps -a --filter name=eightbyte-app || true'
        }
    }
}
```
