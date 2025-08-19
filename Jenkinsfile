pipeline {
  agent any

  environment {
    DOCKERHUB_REPO = 'sadikmert/flask-ci-cd'  // <- burayı kendi kullanıcı adınla değiştir
    KUBECONFIG = '/var/jenkins_home/.kube/config'
  }

  triggers {
    githubPush()
  }

  options {
    skipDefaultCheckout(true)
    timestamps()
  }

  stages {
    stage('a) Clone') {
      steps {
        checkout scm
      }
    }

    stage('b) Build Artifact (.tar.gz)') {
      steps {
        sh 'bash build_artifact.sh'
        archiveArtifacts artifacts: 'dist/app.tar.gz', fingerprint: true
      }
    }

    stage('c) Docker Build') {
      steps {
        sh "docker build -t ${DOCKERHUB_REPO}:latest ."
      }
    }

    stage('d) DockerHub Login') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', passwordVariable: 'DH_PASS', usernameVariable: 'DH_USER')]) {
          sh 'echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin'
        }
      }
    }

    stage('e) Docker Push') {
      steps {
        sh "docker push ${DOCKERHUB_REPO}:latest"
      }
    }

    stage('f) K8s Apply Deployment') {
      steps {
        sh "kubectl apply -f k8s/deployment.yaml"
        sh "kubectl rollout status deployment/flask-app --timeout=120s"
      }
    }

    stage('g) K8s Apply Service') {
      steps {
        sh "kubectl apply -f k8s/service.yaml"
        sh "kubectl get svc flask-service -o wide"
      }
    }
  }

  post {
    always {
      sh "kubectl get pods -o wide || true"
      sh "kubectl get svc || true"
    }
  }
}
