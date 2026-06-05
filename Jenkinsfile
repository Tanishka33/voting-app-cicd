pipeline {
    agent {
        label 'ec2-agent'
    }

    environment {
        DOCKER_USER = 'tanishka3315'
        IMAGE_TAG = "${BUILD_NUMBER}"
        TRIVY_PASS = 'true'
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
                            -t $DOCKER_USER/vote:${IMAGE_TAG} \
                            ./vote
                        '''
                    }
                }

                stage('Build Result') {
                    steps {
                        sh '''
                            docker build \
                            -t $DOCKER_USER/result:${IMAGE_TAG} \
                            ./result
                        '''
                    }
                }

                stage('Build Worker') {
                    steps {
                        sh '''
                            docker build \
                            -t $DOCKER_USER/worker:${IMAGE_TAG} \
                            ./worker
                        '''
                    }
                }
            }
        }

        stage('Trivy Scan') {
            steps {
                script {
                    // Scan Vote Image
                    def voteResult = sh(
                        script: "trivy image --severity CRITICAL --exit-code 1 \$DOCKER_USER/vote:\$IMAGE_TAG",
                        returnStatus: true
                    )

                    // Scan Result Image
                    def resultResult = sh(
                        script: "trivy image --severity CRITICAL --exit-code 1 \$DOCKER_USER/result:\$IMAGE_TAG",
                        returnStatus: true
                    )

                    // Scan Worker Image
                    def workerResult = sh(
                        script: "trivy image --severity CRITICAL --exit-code 1 \$DOCKER_USER/worker:\$IMAGE_TAG",
                        returnStatus: true
                    )

                    // If any image scan returns a non-zero exit status (vulnerabilities found)
                    if (voteResult != 0 || resultResult != 0 || workerResult != 0) {
                        echo "⚠️ Critical vulnerabilities found in one or more microservice images!"
                        env.TRIVY_PASS = 'false'
                    } else {
                        echo "✅ All images passed Trivy security screening."
                    }
                }
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
            when {
                expression {
                    env.TRIVY_PASS == 'true'
                }
            }
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

                        docker push $DOCKER_USER/vote:${IMAGE_TAG}
                        docker push $DOCKER_USER/result:${IMAGE_TAG}
                        docker push $DOCKER_USER/worker:${IMAGE_TAG}
                    '''
                }
            }
        }

        stage('Deploy To Kubernetes') {
            when {
                expression {
                    env.TRIVY_PASS == 'true'
                }
            }
            steps {
                sh '''
                    aws eks update-kubeconfig \
                    --region ap-south-1 \
                    --name voting-app-cluster

                    kubectl apply -f k8s-specifications/

                    kubectl set image deployment/vote \
                    vote=$DOCKER_USER/vote:$IMAGE_TAG

                    kubectl set image deployment/result \
                    result=$DOCKER_USER/result:$IMAGE_TAG

                    kubectl set image deployment/worker \
                    worker=$DOCKER_USER/worker:$IMAGE_TAG

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
                    docker image prune -af
                '''
            }
        }
    }
}