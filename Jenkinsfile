pipeline {
agent any

options {
    skipDefaultCheckout(true)
    disableConcurrentBuilds()
    timeout(time: 15, unit: 'MINUTES')
}

environment {
    APP_NAME = 'eightbyte-app'
    IMAGE_NAME = 'eightbyte-app'
    CONTAINER_NAME = 'eightbyte-app'
    APP_PORT = '3000'
    HOST_PORT = '3000'
}

stages {

    stage('Checkout') {
        steps {
            checkout scm
        }
    }

    stage('Test') {
        steps {
            dir('app') {
                sh '''
                    set -e

                    echo "================================="
                    echo "Node: $(node --version)"
                    echo "NPM:  $(npm --version)"
                    echo "================================="

                    echo "Installing dependencies..."

                    NODE_OPTIONS="--max-old-space-size=256" \
                    npm ci --no-audit --no-fund --prefer-offline

                    echo "Running tests..."

                    NODE_OPTIONS="--max-old-space-size=256" \
                    npm test --if-present

                    echo "Tests completed successfully."
                '''
            }
        }
    }

    stage('Docker Build') {
        steps {
            sh '''
                set -e

                echo "Building Docker image..."

                docker build \
                    -t ${IMAGE_NAME}:${BUILD_NUMBER} \
                    -t ${IMAGE_NAME}:latest \
                    ./app

                echo "Docker image built successfully."

                docker images | grep ${IMAGE_NAME}
            '''
        }
    }

    stage('Deploy') {
        steps {
            sh '''
                set -e

                echo "Stopping existing container if present..."

                docker rm -f ${CONTAINER_NAME} 2>/dev/null || true

                echo "Starting new container..."

                docker run -d \
                    --name ${CONTAINER_NAME} \
                    -p ${HOST_PORT}:${APP_PORT} \
                    --restart unless-stopped \
                    ${IMAGE_NAME}:latest

                echo "Container started."

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

                for i in 1 2 3 4 5; do
                    if curl -fsS http://localhost:${HOST_PORT}/; then
                        echo ""
                        echo "================================="
                        echo "Application is UP!"
                        echo "================================="
                        exit 0
                    fi

                    echo "Application not ready yet. Retrying..."
                    sleep 3
                done

                echo "Application health check failed."
                docker logs ${CONTAINER_NAME} || true
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
        sh '''
            echo "========== Docker Containers =========="
            docker ps -a || true

            echo "========== Application Logs =========="
            docker logs ${CONTAINER_NAME} 2>/dev/null || true
        '''
    }

    always {
        sh '''
            echo "========== Memory =========="
            free -h || true

            echo "========== Disk =========="
            df -h || true
        '''
    }
}
```

}
