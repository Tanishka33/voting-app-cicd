pipeline {
    agent {
        label 'ec2-agent'
    }

    environment {
        DOCKER_USER = 'tanishka3315'
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

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'
                    withSonarQubeEnv('SonarQube') {
                        sh """
                            ${scannerHome}/bin/sonar-scanner
                        """
                    }
                }
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

        stage('Trivy Scan') {
            steps {
                sh '''
                    trivy image \
                    --severity HIGH,CRITICAL \
                    --exit-code 1 \
                    $DOCKER_USER/vote:latest

                    trivy image \
                    --severity HIGH,CRITICAL \
                    --exit-code 0 \
                    $DOCKER_USER/result:latest

                    trivy image \
                    --severity HIGH,CRITICAL \
                    --exit-code 0 \
                    $DOCKER_USER/worker:latest
                '''
            }
        }

        stage('Integration Test') {
                    steps {
                        sh '''
                            docker compose up -d
                            
                            sleep 30
                            
                            # Test the Voting Front-end (Port 8090)
                            echo "Testing Vote application..."
                            curl -f http://localhost:8090
                            
                            # Test the Result Front-end (Port 8081)
                            echo "Testing Result application..."
                            curl -f http://localhost:8081
                            
                            docker compose down
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

        stage('Cleanup') {
            steps {
                sh '''
                    docker system prune -af
                    docker image prune -af
                '''
            }
        }
    }
}