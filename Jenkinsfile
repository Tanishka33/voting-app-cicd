pipeline {
    agent {
        label 'ec2-agent'
    }

    environment {
        DOCKER_USER = 'tanishka3315'
        IMAGE_TAG = "${BUILD_NUMBER}"
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

        stage('Parallel Build') {
            parallel {
                stage('Build Vote') {
                    steps {
                        sh '''
                        docker build \
                        -t $DOCKER_USER/vote:$IMAGE_TAG \
                        ./vote
                        '''
                    }
                }

                stage('Build Result') {
                    steps {
                        sh '''
                        docker build \
                        -t $DOCKER_USER/result:$IMAGE_TAG \
                        ./result
                        '''
                    }
                }

                stage('Build Worker') {
                    steps {
                        sh '''
                        docker build \
                        -t $DOCKER_USER/worker:$IMAGE_TAG \
                        ./worker
                        '''
                    }
                }
            }
        }

        stage('Trivy Scan') {
            parallel {
                stage('Scan Vote') {
                    steps {
                        sh '''
                        trivy image \
                        --severity CRITICAL \
                        --exit-code 1 \
                        $DOCKER_USER/vote:$IMAGE_TAG
                        '''
                    }
                }

                stage('Scan Result') {
                    steps {
                        sh '''
                        trivy image \
                        --severity CRITICAL \
                        --exit-code 1 \
                        $DOCKER_USER/result:$IMAGE_TAG
                        '''
                    }
                }

                stage('Scan Worker') {
                    steps {
                        sh '''
                        trivy image \
                        --severity CRITICAL \
                        --exit-code 1 \
                        $DOCKER_USER/worker:$IMAGE_TAG
                        '''
                    }
                }
            }
        }

        stage('Integration Test') {
            steps {
                sh '''
                    docker compose up -d

                    sleep 30

                    curl -f http://localhost:8090
                    curl -f http://localhost:8081

                    docker compose down
                '''
            }
        }

        stage('Terraform Init') {
            steps {
                sh '''
                    cd terraform
                    terraform init
                '''
            }
        }

        stage('Terraform Plan') {
            steps {
                sh '''
                    cd terraform
                    terraform plan
                '''
            }
        }

        stage('Manual Approval') {
            steps {
                input(
                    message: 'Approve deployment?',
                    ok: 'Deploy'
                )
            }
        }

        stage('Terraform Apply') {
            steps {
                sh '''
                    cd terraform
                    terraform apply -auto-approve
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

                        docker push $DOCKER_USER/vote:$IMAGE_TAG
                        docker push $DOCKER_USER/result:$IMAGE_TAG
                        docker push $DOCKER_USER/worker:$IMAGE_TAG
                    '''
                }
            }
        }

        stage('Deploy To Kubernetes') {
            steps {
                sh '''
                    aws eks update-kubeconfig \
                    --region ap-south-1 \
                    --name voting-app-cluster

                    kubectl apply -f k8s-specifications/

                    kubectl set image deployment/vote vote=$DOCKER_USER/vote:$IMAGE_TAG
                    kubectl set image deployment/result result=$DOCKER_USER/result:$IMAGE_TAG
                    kubectl set image deployment/worker worker=$DOCKER_USER/worker:$IMAGE_TAG

                    kubectl rollout status deployment/vote
                    kubectl rollout status deployment/result
                    kubectl rollout status deployment/worker

                    kubectl get pods
                '''
            }
        }

        stage('Cleanup') {
            steps {
                sh '''
                docker system prune -af
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully'
        }
        failure {
            echo 'Pipeline failed → previous deployment remains active'
        }
        always {
            cleanWs()
        }
    }
}