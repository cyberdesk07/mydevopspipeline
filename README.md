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
