pipeline {
    agent any
    
    stages{
        stage('Build'){
            steps {
                sh 'mvn clean package'
            }
            post {
                success {
                    echo 'Archiving the artifacts'
                    archiveArtifacts artifacts: '**/target/*.war'
                }
            }
        }
        stage ("Deploy to Tomcat"){
            steps {
                sshagent(['jenkins-key']) {
                    sh "scp -o StrictHostKeyChecking=no **/*.war ubuntu@15.236.37.116:/opt/tomcat/webapps"
                    sh 'ssh -t -t ubuntu@15.236.37.116 -o strictHostKeyChecking=no "rm -rvf /opt/tomcat/webapps/ROOT.war && mv /opt/tomcat/webapps/*.war /opt/tomcat/webapps/ROOT.war"'
                }
            }
        }
    }
}
