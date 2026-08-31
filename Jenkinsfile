pipeline {
agent any

options {
    skipDefaultCheckout(true)
    disableConcurrentBuilds()
    timeout(time: 15, unit: 'MINUTES')
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '5'))
}

environment {
    APP_DIR = 'app'
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

                echo "===== SYSTEM ====="
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
            '''
        }
    }

    stage('Test') {
        steps {
            dir("${APP_DIR}") {
                sh '''
                    set -e

                    echo "===== APPLICATION TEST ====="

                    test -f package.json

                    echo "package.json found"

                    echo "Installing dependencies with memory-friendly settings..."

                    npm ci \
                        --no-audit \
                        --no-fund \
                        --prefer-offline \
                        --progress=false \
                        --maxsockets=2

                    echo "Dependencies installed successfully"

                    if npm run | grep -q "test"; then
                        echo "Running npm test..."
                        npm test -- --runInBand
                    else
                        echo "No test script configured. Skipping npm test."
                    fi
                '''
            }
        }
    }

    stage('Docker Build') {
        steps {
            sh '''
                set -e

                echo "===== DOCKER BUILD ====="

                docker rm -f ${CONTAINER_NAME} 2>/dev/null || true

                docker build \
                    --pull=false \
                    --tag ${IMAGE_NAME}:${BUILD_NUMBER} \
                    --tag ${IMAGE_NAME}:latest \
                    .

                echo "Docker image created:"
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

                docker run -d \
                    --name ${CONTAINER_NAME} \
                    --restart unless-stopped \
                    -p ${HOST_PORT}:${APP_PORT} \
                    ${IMAGE_NAME}:${BUILD_NUMBER}

                echo "Container started"

                sleep 5

                docker ps --filter "name=${CONTAINER_NAME}"

                echo "Container logs:"
                docker logs --tail 50 ${CONTAINER_NAME}
            '''
        }
    }

    stage('Health Check') {
        steps {
            sh '''
                set -e

                echo "===== HEALTH CHECK ====="

                SUCCESS=0

                for i in 1 2 3 4 5 6 7 8 9 10
                do
                    echo "Health check attempt $i..."

                    if curl --fail --silent --show-error \
                        http://127.0.0.1:${HOST_PORT}/ > /dev/null
                    then
                        SUCCESS=1
                        echo "Application is healthy!"
                        break
                    fi

                    sleep 2
                done

                if [ "$SUCCESS" -ne 1 ]; then
                    echo "Health check failed."
                    echo "===== CONTAINER STATUS ====="
                    docker ps -a --filter "name=${CONTAINER_NAME}"

                    echo "===== CONTAINER LOGS ====="
                    docker logs ${CONTAINER_NAME} || true

                    exit 1
                fi
            '''
        }
    }
}

post {
    success {
        echo '========================================='
        echo '8Byte deployment completed successfully!'
        echo '========================================='
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
            free -h || true
        '''
    }

    cleanup {
        sh '''
            docker image prune -f || true
        '''
    }
}

}
