pipeline {
  agent any
  environment {
    DOCKER_IMAGE = "sadikmert/flask-ci-cd"   // <-- Docker Hub kullanıcı adını yaz
    TAG = "latest"
    KUBECONFIG = "/root/.kube/config"
  }
  triggers {
    // Webhook (GitHub) ekleyince otomatik tetiklenir:
    githubPush()
  }
  stages {
    stage('Stage 1: Clone') {
      steps { checkout scm }
    }
    stage('Stage 2: Build (python pkg)') {
      steps {
        sh '''
          python3 -m venv .venv
          . .venv/bin/activate
          pip install --upgrade pip build
          python -m build || true   # jar yerine paketleme; Python için opsiyonel
        '''
      }
    }
    stage('Stage 3: Docker Build') {
      steps { sh 'docker build -t ${DOCKER_IMAGE}:${TAG} .' }
    }
    stage('Stage 4: Docker Login') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
          sh 'echo $DH_PASS | docker login -u $DH_USER --password-stdin'
        }
      }
    }
    stage('Stage 5: Docker Push') {
      steps { sh 'docker push ${DOCKER_IMAGE}:${TAG}' }
    }
    stage('Stage 6: K8s Apply Deployment') {
      steps {
        sh '''
          kubectl apply -f k8s/deployment.yaml
          kubectl rollout status deployment/flask-ci-cd --timeout=120s
        '''
      }
    }
    stage('Stage 7: K8s Apply Service') {
      steps {
        sh '''
          kubectl apply -f k8s/service.yaml
          kubectl get svc flask-ci-cd-service -o wide
        '''
      }
    }
    stage('Verify Pods') {
      steps { sh 'kubectl get pods -l app=flask-ci-cd -o wide' }
    }
  }
  post {
    always { sh 'docker logout || true' }
  }
}