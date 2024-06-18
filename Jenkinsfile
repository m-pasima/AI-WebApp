pipeline {
    agent any

    tools {
        maven 'Maven 3.6.3'
        jdk 'Java 11'
    }

    environment {
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'
        IMAGE_NAME = 'yourdockerhubusername/aiwebapp'
        SONAR_TOKEN = credentials('SONAR_TOKEN')
        NEXUS_USERNAME = credentials('NEXUS_USERNAME')
        NEXUS_PASSWORD = credentials('NEXUS_PASSWORD')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn sonar:sonar -Dsonar.login=$SONAR_TOKEN'
                }
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${env.IMAGE_NAME}:${env.BUILD_NUMBER}")
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('', env.DOCKER_CREDENTIALS_ID) {
                        docker.image("${env.IMAGE_NAME}:${env.BUILD_NUMBER}").push()
                        docker.image("${env.IMAGE_NAME}:${env.BUILD_NUMBER}").push('latest')
                    }
                }
            }
        }

        stage('Deploy to Nexus') {
            steps {
                script {
                    sh """
                        mvn deploy -DaltDeploymentRepository=nexus::default::http://nexus.example.com/repository/maven-releases/ \
                        -Dusername=${NEXUS_USERNAME} \
                        -Dpassword=${NEXUS_PASSWORD}
                    """
                }
            }
        }

        stage('Deploy Docker Container') {
            steps {
                script {
                    docker.image("${env.IMAGE_NAME}:${env.BUILD_NUMBER}").run('-p 4567:4567')
                }
            }
        }
    }

    post {
        always {
            junit 'target/surefire-reports/*.xml'
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
        }
    }
}
