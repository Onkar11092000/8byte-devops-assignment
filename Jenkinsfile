pipeline {
agent any

options {
    timeout(time: 20, unit: 'MINUTES')
    timestamps()
    disableConcurrentBuilds()
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
            deleteDir()

            checkout([
                $class: 'GitSCM',
                branches: [[name: '*/main']],
                userRemoteConfigs: [[
                    url: 'https://github.com/Onkar11092000/8byte-devops-assignment.git'
                ]]
            ])
        }
    }

    stage('System Check') {
        steps {
            sh '''
                set -e

                echo "===== SYSTEM CHECK ====="

                echo "Node:"
                node --version

                echo "NPM:"
                npm --version

                echo "Docker:"
                docker --version

                echo "Memory:"
                free -h

                echo "Disk:"
                df -h /

                echo "========================"
            '''
        }
    }

    stage('Test') {
        steps {
            dir('app') {
                sh '''
                    set -e

                    echo "===== APPLICATION TEST ====="

                    test -f package.json
                    echo "package.json found"

                    test -f Dockerfile
                    echo "Dockerfile found"

                    echo "Installing dependencies..."

                    npm ci \
                      --no-audit \
                      --no-fund \
                      --prefer-offline \
                      --progress=false \
                      --maxsockets=2

                    echo "Dependencies installed successfully"

                    echo "Running tests..."

                    npm test -- --runInBand

                    echo "Tests completed successfully"
                '''
            }
        }
    }

    stage('Docker Build') {
        steps {
            sh '''
                set -e

                echo "===== DOCKER BUILD ====="

                test -f app/Dockerfile
                echo "Dockerfile found at app/Dockerfile"

                docker rm -f ${CONTAINER_NAME} 2>/dev/null || true

                echo "Building Docker image..."

                docker build \
                    --pull=false \
                    --tag ${IMAGE_NAME}:${BUILD_NUMBER} \
                    --tag ${IMAGE_NAME}:latest \
                    ./app

                echo "Docker image built successfully"

                docker images ${IMAGE_NAME}
            '''
        }
    }

    stage('Deploy') {
        steps {
            sh '''
                set -e

                echo "===== DEPLOY ====="

                docker rm -f ${CONTAINER_NAME} 2>/dev/null || true

                echo "Starting application container..."

                docker run -d \
                    --name ${CONTAINER_NAME} \
                    --restart unless-stopped \
                    -p ${HOST_PORT}:${APP_PORT} \
                    ${IMAGE_NAME}:latest

                echo "Container started"

                sleep 5

                echo "===== CONTAINER STATUS ====="

                docker ps --filter "name=${CONTAINER_NAME}"

                echo "===== CONTAINER LOGS ====="

                docker logs --tail 50 ${CONTAINER_NAME}
            '''
        }
    }

    stage('Health Check') {
        steps {
            sh '''
                set -e

                echo "===== HEALTH CHECK ====="

                echo "Waiting for application..."

                sleep 5

                echo "Checking container..."

                docker ps --filter "name=${CONTAINER_NAME}" --format "{{.Status}}"

                echo "Checking HTTP endpoint..."

                curl --fail --silent --show-error \
                    --max-time 10 \
                    http://127.0.0.1:${HOST_PORT}/health

                echo ""
                echo "Health check passed successfully"
            '''
        }
    }
}

post {
    success {
        echo '========================================='
        echo '8Byte deployment successful!'
        echo '========================================='

        sh '''
            echo "===== FINAL CONTAINER ====="
            docker ps --filter "name=${CONTAINER_NAME}"

            echo "===== FINAL IMAGE ====="
            docker images ${IMAGE_NAME}
        '''
    }

    failure {
        echo '========================================='
        echo '8Byte deployment failed!'
        echo '========================================='

        sh '''
            echo "===== DOCKER STATUS ====="
            docker ps -a --filter "name=${CONTAINER_NAME}" || true

            echo "===== DOCKER LOGS ====="
            docker logs --tail 100 ${CONTAINER_NAME} 2>/dev/null || true

            echo "===== MEMORY ====="
            free -h

            echo "===== DISK ====="
            df -h /
        '''
    }

    always {
        sh '''
            docker image prune -f || true
        '''
    }
}

}
