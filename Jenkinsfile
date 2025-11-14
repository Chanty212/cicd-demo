pipeline {
    agent {
        docker {
            image 'python:3.10'
            args '-u'
        }
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/Chanty212/cicd-demo.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'pip install --upgrade pip'
                sh 'pip install pytest'
            }
        }

        stage('Run Tests') {
            steps {
                sh 'pytest -q'
            }
        }
    }

    post {
        success {
            script {
                withCredentials([string(credentialsId: 'webex-token', variable: 'WEBEX_TOKEN')]) {
                    sh '''
                        echo "Sending WebEx SUCCESS notification..."
                        curl -v --fail -X POST \
                            -H "Authorization: Bearer $WEBEX_TOKEN" \
                            -H "Content-Type: application/json" \
                            -d '{"roomId": "2dae9c10-c114-11f0-9124-93790abe5897", "text": "Jenkins Build SUCCESS!"}' \
                            https://webexapis.com/v1/messages
                    '''
                }
            }
        }

        failure {
            script {
                withCredentials([string(credentialsId: 'webex-token', variable: 'WEBEX_TOKEN')]) {
                    sh '''
                        echo "Sending WebEx FAILURE notification..."
                        curl -v --fail -X POST \
                            -H "Authorization: Bearer $WEBEX_TOKEN" \
                            -H "Content-Type: application/json" \
                            -d '{"roomId": "2dae9c10-c114-11f0-9124-93790abe5897", "text": "Jenkins Build FAILED!"}' \
                            https://webexapis.com/v1/messages
                    '''
                }
            }
        }
    }
}
