pipeline {
    agent any

    environment {
        IMAGE_NAME = "eightbyte-app"
        EC2_USER = "ubuntu"
        EC2_HOST = "13.232.70.193"
    }

    stages {

        stage('Test') {
            steps {
                dir('app') {
                    bat 'npm.cmd test -- --runInBand'
                }
            }
        }

        stage('Docker Build') {
            steps {
                bat 'docker build -t %IMAGE_NAME%:latest app'
            }
        }

        stage('Deploy to EC2') {
            steps {
                bat '''
                docker save %IMAGE_NAME%:latest -o eightbyte-app.tar
                scp -i terraform\\ssh_key.pem eightbyte-app.tar %EC2_USER%@%EC2_HOST%:/home/ubuntu/
                ssh -i terraform\\ssh_key.pem %EC2_USER%@%EC2_HOST% "sudo docker load -i /home/ubuntu/eightbyte-app.tar && sudo docker rm -f eightbyte-app || true && sudo docker run -d --name eightbyte-app -p 3000:3000 eightbyte-app:latest"
                '''
            }
        }

        stage('Health Check') {
            steps {
                bat 'curl http://%EC2_HOST%:3000/health'
            }
        }
    }
}