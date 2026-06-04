pipeline {
    agent any

    environment {
        DOCKER_USER = 'tanishkaborade'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify') {
            steps {
                sh 'pwd'
                sh 'ls -la'
            }
        }

        stage('Build Vote') {
            steps {
                sh '''
                    docker build \
                    -t $DOCKER_USER/vote:latest \
                    ./vote
                '''
            }
        }

        stage('Build Result') {
            steps {
                sh '''
                    docker build \
                    -t $DOCKER_USER/result:latest \
                    ./result
                '''
            }
        }

        stage('Build Worker') {
            steps {
                sh '''
                    docker build \
                    -t $DOCKER_USER/worker:latest \
                    ./worker
                '''
            }
        }

        stage('Push Images') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'docker-creds',
                        usernameVariable: 'USER',
                        passwordVariable: 'PASS'
                    )
                ]) {
                    sh '''
                        echo $PASS | docker login \
                        -u $USER \
                        --password-stdin

                        docker push $DOCKER_USER/vote:latest
                        docker push $DOCKER_USER/result:latest
                        docker push $DOCKER_USER/worker:latest
                    '''
                }
            }
        }
    }
}