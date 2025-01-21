pipeline {
    agent { label 'agent' }

    environment {
        VERSION = readFile('VERSION').trim()
        TRIVY_CACHE_DIR = "${env.WORKSPACE}/.cache"
        SKIP_ALL = "true" 
    }

    stages {
        stage('Security Scan') {
            when {
                expression { return env.SKIP_ALL == "false" }
            }
            agent {
                docker {
                    image 'aquasec/trivy:latest'
                    args '--entrypoint="" --user root -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                script {
                    echo 'Running Dependency Scan...'
                    sh 'trivy fs --exit-code 1 --severity CRITICAL ./weatherProject/app'
                    echo 'Running Dockerfile Scan...'
                    sh 'trivy config --exit-code 1 --severity CRITICAL weatherProject/app/Dockerfile'
                }
            }
        }

        stage('Static Analysis') {
            when {
                expression { return env.SKIP_ALL == "false" }
            }
            steps {
                script {
                    def scannerHome = tool 'sonarQube scanner'
                    withSonarQubeEnv('SonarQube Server') {
                        withCredentials([usernamePassword(credentialsId: 'sonar-credentials', usernameVariable: 'SONAR_LOGIN', passwordVariable: 'SONAR_PASSWORD')]) {
                            sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=weather -Dsonar.sources=weatherProject/app/app.py -Dsonar.login=${SONAR_LOGIN} -Dsonar.password=${SONAR_PASSWORD}"
                        }
                    }
                }
            }
        }

        stage('Bump Version') {
            when {
                allOf {
                    branch 'main'
                    expression { return env.SKIP_ALL == "false" }
                }
            }
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'gitlab_pat', usernameVariable: 'GITLAB_USERNAME', passwordVariable: 'GITLAB_PASS')]) {
                        sh '''
                        chmod +x version.sh
                        chmod +w VERSION
                        export GITLAB_USERNAME=${GITLAB_USERNAME}
                        export GITLAB_PASS=${GITLAB_PASS}
                        echo "patch" | ./version.sh
                        '''
                    }
                }
            }
        }

        stage('Build App Image') {
          
            steps {
                script {
                    sh 'docker build -t weather-app -f weatherProject/app/Dockerfile weatherProject/app'
                    
                   
                }
            }
        }
        stage('Selenium Tests') {
            when {
                allOf {
                    branch 'main'
                    expression { return env.SKIP_ALL == "false" }
                }
            }
            agent {
                docker {
                    image 'selenium/standalone-firefox:latest'
                     args '--net=host --entrypoint="" --user root'
                }
            }
            steps {
                script {
                    sh '''
                         pip3 install pytest selenium 
                         python3 -m pytest ./weatherProject/app/test_app_selenium.py -v --tb=short
                    '''
                }
            }
        }

        stage('Push To ECR') {
            
           steps {
                script {
                     withCredentials([aws(credentialsId: 'aws-credentials', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh """
                            aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 145023133356.dkr.ecr.us-east-1.amazonaws.com
                            docker tag weather-app 145023133356.dkr.ecr.us-east-1.amazonaws.com/weather-app:${env.VERSION}
                            docker push 145023133356.dkr.ecr.us-east-1.amazonaws.com/weather-app:${env.VERSION}
                            """
                }
            }
        }
        }


        stage('Sign Docker Image') {
            when {
                expression { return env.SKIP_ALL == "false" }
            }
            steps {
                script {
                    withCredentials([
                        file(credentialsId: 'cosign-private-key', variable: 'COSIGN_KEY'),
                        string(credentialsId: 'cosign-password', variable: 'COSIGN_PASSWORD')
                    ]) {
                        withEnv([
                            "COSIGN_PASSWORD=${COSIGN_PASSWORD}",
                            "VERSION=${env.VERSION}"
                        ]) {
                            sh '''
                            cosign sign --yes --key "$COSIGN_KEY" docker.io/oriamrani/weather-app:$VERSION
                            '''
                        }
                    }
                }
            }
        }

        stage('Verify Container Image') {
            when {
                expression { return env.SKIP_ALL == "false" }
            }
            steps {
                script {
                    withCredentials([
                        file(credentialsId: 'cosign-public-key', variable: 'COSIGN_PUBLIC')
                    ]) {
                        def verifyResult = sh(
                            script: """
                            cosign verify \
                            --key $COSIGN_PUBLIC \
                            --allow-insecure-registry \
                            --insecure-ignore-tlog=true \
                            docker.io/oriamrani/weather-app:$VERSION
                            """,
                            returnStatus: true
                        )
                    }
                }
            }
        }

        stage('Deployment to staging environment') {
            when {
                branch 'develop'
            }
            steps {
                script {
                    sshagent(['ec2-weather-app']) {
                        sh '''
                        ssh -o StrictHostKeyChecking=no ubuntu@10.0.12.47 '
                        docker compose down &&
                        docker compose pull &&
                        docker compose up -d
                        '
                        '''
                    }
                }
            }
        }

        stage('Deployment to production') {
           
            steps {
                   withCredentials([usernamePassword(credentialsId: 'gitlab_pat', usernameVariable: 'GITLAB_USERNAME', passwordVariable: 'GITLAB_PASS')]){
            script {
                def  manifestsRepo = "http://${GITLAB_USERNAME}:${GITLAB_PASS}@10.0.128.91/oriamrani128/weatherApp-manifests.git"
                
                sh """
                if [ -d 'manifestsRepo' ]; then
                    rm -rf manifestsRepo
                fi

                git clone ${manifestsRepo} manifestsRepo
                cd manifestsRepo
                sed -i 's/latest/${env.VERSION}/g' deployment.yml
                git config user.name "Jenkins"
                git config user.email "jenkins@example.com"
                git add deployment.yml
                git commit -m "Update image tag to ${env.VERSION}"
                git push origin main
                """
            }
        }
            }
        } DockerHub
    }

    post {
        always {
            script {
                sh 'docker system prune -f'
                cleanWs()
            }
        }
        success {
            slackSend(channel: '#succeeded-buid', color: 'good', message: "Build #${env.BUILD_NUMBER} succeeded!")
        }
        failure {
            script {
                def logOutput = currentBuild.rawBuild.getLog().join("\n")
                def exitCode = sh(script: 'echo $?', returnStatus: true)

                def msg = """
                *Build Failed!*
                - *Build Number*: #${env.BUILD_NUMBER}
                - *Exit Code*: ${exitCode}
                - View the full error log and details here: <${env.BUILD_URL}|Click here>
                """
                slackSend(channel: '#devops-alerts', color: 'danger', message: msg)
            }
        }
    }
}
