# AI WebApp

This project demonstrates a simple Java-based web application that provides information about how AI is changing the world. The project is built using Maven and is deployed using Docker. It also includes a CI/CD pipeline setup with Jenkins, which performs code analysis using SonarQube, builds and pushes Docker images to Docker Hub, and deploys artifacts to Nexus.

## Prerequisites

- AWS account
- Java 11
- Maven
- Docker
- Jenkins with the following plugins:
  - Maven Integration
  - Docker Pipeline
  - SonarQube Scanner
- SonarQube
- Nexus Repository Manager

## Setup Instructions

### Step 1: Create AWS EC2 Instances

1. **Log in to the AWS Management Console.**
2. **Navigate to the EC2 Dashboard.**
3. **Launch EC2 instances for Jenkins, SonarQube, Nexus, and Docker.**
    - Choose an appropriate AMI (e.g., Ubuntu Server).
    - Configure instance details, add storage, and configure security groups (open required ports like 8080 for Jenkins, 9000 for SonarQube, 8081 for Nexus, and 2376 for Docker).
    - Launch the instances and connect to them using SSH.

### Step 2: Install and Configure Jenkins

1. **SSH into the Jenkins Server:**

    ```bash
    ssh -i your-key.pem ubuntu@<jenkins-server-public-ip>
    ```

2. **Install Jenkins:**

    ```bash
    sudo apt update
    sudo apt install openjdk-11-jdk -y
    wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
    sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
    sudo apt update
    sudo apt install jenkins -y
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
    ```

3. **Access Jenkins:**
    - Open `http://<jenkins-server-public-ip>:8080` in your browser.
    - Follow the setup instructions and install the recommended plugins.
    - Install the necessary plugins: Maven Integration, Docker Pipeline, SonarQube Scanner.

### Step 3: Install and Configure SonarQube

1. **SSH into the SonarQube Server:**

    ```bash
    ssh -i your-key.pem ubuntu@<sonarqube-server-public-ip>
    ```

2. **Install SonarQube:**

    ```bash
    sudo apt update
    sudo apt install openjdk-11-jdk -y
    wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.2.4.50792.zip
    unzip sonarqube-9.2.4.50792.zip
    sudo mv sonarqube-9.2.4.50792 /opt/sonarqube
    sudo useradd -d /opt/sonarqube -s /bin/bash sonarqube
    sudo chown -R sonarqube: /opt/sonarqube
    ```

3. **Configure SonarQube:**

    - Edit the SonarQube configuration file (`/opt/sonarqube/conf/sonar.properties`) to bind SonarQube to the server's IP address.

    ```bash
    sudo nano /opt/sonarqube/conf/sonar.properties
    ```

    - Update the following properties:

    ```properties
    sonar.web.host=0.0.0.0
    sonar.web.port=9000
    ```

4. **Start SonarQube:**

    ```bash
    sudo -u sonarqube /opt/sonarqube/bin/linux-x86-64/sonar.sh start
    ```

5. **Access SonarQube:**
    - Open `http://<sonarqube-server-public-ip>:9000` in your browser.
    - Follow the setup instructions to create an admin user and configure a new project.

### Step 4: Install and Configure Nexus

1. **SSH into the Nexus Server:**

    ```bash
    ssh -i your-key.pem ubuntu@<nexus-server-public-ip>
    ```

2. **Install Nexus:**

    ```bash
    sudo apt update
    sudo apt install openjdk-11-jdk -y
    wget https://download.sonatype.com/nexus/3/nexus-3.34.0-01-unix.tar.gz
    tar -xvf nexus-3.34.0-01-unix.tar.gz
    sudo mv nexus-3.34.0-01 /opt/nexus
    sudo useradd -d /opt/nexus -s /bin/bash nexus
    sudo chown -R nexus: /opt/nexus
    ```

3. **Configure Nexus:**

    - Edit the Nexus configuration file (`/opt/nexus/bin/nexus.rc`) to run Nexus as a service.

    ```bash
    sudo nano /opt/nexus/bin/nexus.rc
    ```

    - Add the following line:

    ```bash
    run_as_user="nexus"
    ```

4. **Start Nexus:**

    ```bash
    sudo -u nexus /opt/nexus/bin/nexus start
    ```

5. **Access Nexus:**
    - Open `http://<nexus-server-public-ip>:8081` in your browser.
    - Follow the setup instructions to create an admin user and configure a new repository.

### Step 5: Set Up Jenkins Pipeline

1. **Create a Jenkins Pipeline Job:**
    - Open Jenkins at `http://<jenkins-server-public-ip>:8080`.
    - Create a new Pipeline job.
    - Connect the job to your repository.
    - Add the Jenkinsfile content to the pipeline script.

### Jenkinsfile

```groovy
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
```

### Directory Structure

```
AI-WebApp/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/
│   │   │       └── example/
│   │   │           └── aiwebapp/
│   │   │               └── App.java
│   │   ├── resources/
│   │   │   └── index.html
│   ├── test/
│   │   └── java/
│   │       └── com/
│   │           └── example/
│   │               └── aiwebapp/
│   │                   └── AppTest.java
├── Dockerfile
├── Jenkinsfile
├── pom.xml
└── README.md
```

### Codebase

Refer to the source code files in the `src` directory for the application code base:
- `src/main/java/com/example/aiwebapp/App.java`: Main application code.
- `src/main/resources/index.html`: HTML file for the web page.
- `src/test/java/com/example/aiwebapp/AppTest.java`: Unit tests.



This README provides a comprehensive guide for setting up the

 CI/CD pipeline on AWS, with references to the application code base.
