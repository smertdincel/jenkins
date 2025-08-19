pipeline {
  agent any
  environment {
    DOCKERHUB_REPO = 'sadikmert/flask-ci-cd'
    IMAGE_TAG      = "${BUILD_NUMBER}"
    KUBECONFIG     = '/var/jenkins_home/.kube/config'
    APP_NAME       = 'flask-app'
  }
  triggers { githubPush() }
  options { skipDefaultCheckout(true); timestamps(); disableConcurrentBuilds() }

  stages {
    stage('a) Clone') { steps { checkout scm } }

    stage('b) Build Artifact (.tar.gz)') {
      steps {
        sh 'bash build_artifact.sh'
        archiveArtifacts artifacts: 'dist/app.tar.gz', fingerprint: true
      }
    }

    stage('c) Docker Build') {
      steps {
        sh '''
          set -eux
          docker build \
            -t ${DOCKERHUB_REPO}:${IMAGE_TAG} \
            -t ${DOCKERHUB_REPO}:latest \
            .
        '''
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
        sh '''
          set -eux
          docker push ${DOCKERHUB_REPO}:${IMAGE_TAG}
          docker push ${DOCKERHUB_REPO}:latest
        '''
      }
    }

    stage('f) Apply Manifests') {
      steps {
        sh '''
          set -eux
          kubectl apply -f k8s/deployment.yaml
          kubectl apply -f k8s/service.yaml
        '''
      }
    }

    stage('g) Update Image & Rollout') {
      steps {
        sh '''
          set -eux
          kubectl set image deployment/${APP_NAME} ${APP_NAME}=${DOCKERHUB_REPO}:${IMAGE_TAG} --record
          kubectl rollout status deployment/${APP_NAME} --timeout=180s
        '''
      }
    }

    stage('h) Smoke Check') {
      steps {
        sh '''
          set -eux
          kubectl get deploy,po,svc -o wide
          kubectl get svc flask-service -o wide
        '''
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
