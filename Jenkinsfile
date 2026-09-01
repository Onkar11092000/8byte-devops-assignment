pipeline {
agent any

options {
    disableConcurrentBuilds()
    timeout(time: 20, unit: 'MINUTES')
    timestamps()
}

environment {
    APP_NAME = 'eightbyte-app'
    IMAGE_NAME = 'eightbyte-app'
    CONTAINER_PORT = '3000'
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

                echo "Docker access:"
                docker info >/dev/null

                echo "===== SYSTEM CHECK COMPLETE ====="
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

                    echo "===== TESTS PASSED ====="
                '''
            }
        }
    }

    stage('Docker Build') {
        steps {
            dir('app') {
                sh '''
                    set -e

                    echo "===== DOCKER BUILD ====="

                    test -f Dockerfile

                    echo "Dockerfile found"

                    echo "Removing old container if present..."

                    docker rm -f ${APP_NAME} 2>/dev/null || true

                    echo "Building Docker image..."

                    docker build \
                        --pull=false \
                        --tag ${IMAGE_NAME}:${BUILD_NUMBER} \
                        --tag ${IMAGE_NAME}:latest \
                        .

                    echo "Docker image built successfully"

                    docker images ${IMAGE_NAME}
                '''
            }
        }
    }

    stage('Deploy') {
        steps {
            dir('app') {
                sh '''
                    set -e

                    echo "===== DEPLOY ====="

                    echo "Stopping old container..."

                    docker rm -f ${APP_NAME} 2>/dev/null || true

                    echo "Starting new container..."

                    docker run -d \
                        --name ${APP_NAME} \
                        --restart unless-stopped \
                        -p ${HOST_PORT}:${CONTAINER_PORT} \
                        ${IMAGE_NAME}:latest

                    echo "Container started"

                    sleep 5

                    echo "===== CONTAINER STATUS ====="

                    docker ps --filter name=${APP_NAME}

                    echo "===== CONTAINER LOGS ====="

                    docker logs --tail 50 ${APP_NAME}
                '''
            }
        }
    }

    stage('Health Check') {
        steps {
            sh '''
                set -e

                echo "===== HEALTH CHECK ====="

                sleep 3

                echo "Testing application..."

                curl -f http://localhost:${HOST_PORT}/health

                echo ""
                echo "Health check successful"

                echo "===== DEPLOYMENT SUCCESSFUL ====="
            '''
        }
    }
}

post {

    success {
        echo '''

=========================================
8Byte deployment successful!
============================

'''
}

    failure {
        echo '''

=========================================
8Byte deployment failed!
========================

'''

        sh '''
            echo "===== DOCKER STATUS ====="

            docker ps -a --filter name=${APP_NAME} || true

            echo "===== DOCKER LOGS ====="

            docker logs --tail 100 ${APP_NAME} 2>/dev/null || true

            echo "===== MEMORY ====="

            free -h

            echo "===== DISK ====="

            df -h /
        '''
    }

    always {
        sh '''
            echo "===== CLEANUP ====="

            docker image prune -f || true
        '''
    }
}

}
