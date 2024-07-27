###### jenkins pipeline for ARGOCD AND KUBERNETES ########
1. **Configure CI/CD Pipeline in Jenkins:**
- Create a CI/CD pipeline in Jenkins to automate your application deployment.

```groovy
pipeline {
    agent any
    tools {
        jdk 'jdk17'
    }
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }
    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }
        stage('Checkout from Git') {
            steps {
                git branch: 'main', url: 'https://github.com/cyberdesk07/a-youtube-clone-app.git'
            }
        }
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh '''
                        $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Youtube \
                        -Dsonar.projectKey=Youtube
                    '''
                }
            }
        }
        stage('Docker Build') {
            steps {
                script {
                    def imageTag = "cyberdesk07/youtube:${BUILD_NUMBER}"
                    sh "docker build -t ${imageTag} ."
                }
            }
        }
        stage('Trivy Scan') {
            steps {
                script {
                    def imageTag = "cyberdesk07/youtube:${BUILD_NUMBER}"
                    sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image ${imageTag}"
                }
            }
        }
        stage('Docker Push') {
            steps {
                script {
                    def imageTag = "cyberdesk07/youtube:${BUILD_NUMBER}"
                    withDockerRegistry(credentialsId: 'dockerhub', toolName: 'docker') {   
                        sh "docker push ${imageTag}"
                    }
                }
            }
        }
        stage('Update Deployment File') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'GITHUB-TOKEN', variable: 'GITHUB_TOKEN')]) {
                        def NEW_IMAGE_NAME = "cyberdesk07/youtube:${BUILD_NUMBER}"
                        sh "sed -i 's|image: .*|image: ${NEW_IMAGE_NAME}|' Kubernetes/deployment.yml"
                        sh 'git config --global user.email "cyberdesk07@gmail.com"'
                        sh 'git config --global user.name "cyberdesk07"'
                        sh 'git add Kubernetes/deployment.yml'
                        sh "git commit -m 'Update deployment image to ${NEW_IMAGE_NAME}' || echo 'No changes to commit'"
                        sh "git push https://${GITHUB_TOKEN}@github.com/cyberdesk07/a-youtube-clone-app.git HEAD:main"
                    }
                }
            }
        }
        stage('Clean Up Old Docker Images') {
            steps {
                script {
                    sh '''
                        # Find all images with the repository name and sort by creation date
                        IMAGES=$(docker images cyberdesk07/youtube --format "{{.Repository}}:{{.Tag}} {{.ID}}" | sort -r | awk 'NR>3 {print $2}')
                        
                        # Remove all but the three most recent images
                        if [ -n "$IMAGES" ]; then
                            docker rmi $IMAGES || true
                        fi
                    '''
                }
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}
```

Certainly, here are the instructions without step numbers:



# mydevopspipeline

pipeline {
    agent any

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()  // Clean workspace before starting
            }
        }

        stage('Checkout from Git') {
            steps {
                git branch: 'master', url: 'https://github.com/DevMadhup/node-todo-cicd.git'
            }
        }
        
        stage("SonarQube Analysis") {
            steps {
                script {
                    // Use withSonarQubeEnv to set up SonarQube environment
                    withSonarQubeEnv('sonar-server') {
                        // Execute SonarQube scanner
                        def scannerHome = tool 'sonar-scanner'
                        sh """${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectName=todoapp \
                            -Dsonar.projectKey=todoapp"""
                    }
                }
            }
        }
        
        stage("Build Docker Image") {
            steps {
                script {
                    // Build the Docker image
                    sh 'docker build -t todoapp .'
                }
            }
        }
        
        stage("Deploy to Container") {
            steps {
                script {
                    // Check if the container is already running and stop it
                    sh '''
                    if [ $(docker ps -q -f name=todoapp) ]; then
                        docker stop todoapp
                        docker rm todoapp
                    fi
                    '''

                    // Run the Docker container
                    sh 'docker run -d --name todoapp -p 8081:80 todoapp:latest'
                }
            }
        }
    }
    
    // Post section can be added here if needed for notifications or further actions
}
