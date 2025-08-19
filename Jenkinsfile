pipeline {
  agent any

  environment {
    // ---- Docker Hub ----
    DOCKERHUB_REPO = 'sadikmert/flask-ci-cd'
    IMAGE_TAG      = "${BUILD_NUMBER}"

    // ---- Kubernetes (Minikube) ----
    KUBECONFIG     = '/var/jenkins_home/.kube/config'
    APP_NAME       = 'flask-app'

    // ---- EC2 (Docker ile deploy) ----
    EC2_HOST       = '51.20.66.234'  // Örn: 3.XX.XX.XX veya ec2-xx-xx-xx.compute.amazonaws.com
    EC2_USER       = 'ubuntu'                     // Amazon Linux ise 'ec2-user'
  }

  // GitHub push ile otomatik tetikleme
  triggers { githubPush() }

  options {
    skipDefaultCheckout(true)
    timestamps()
    disableConcurrentBuilds()
  }

  stages {

    stage('a) Clone') {
      steps {
        checkout scm
      }
    }

    stage('b) Build Artifact (.tar.gz)') {
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail
bash build_artifact.sh
'''
        archiveArtifacts artifacts: 'dist/app.tar.gz', fingerprint: true
      }
    }

    stage('c) Docker Build') {
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail
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
          sh '''#!/usr/bin/env bash
set -euo pipefail
echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
'''
        }
      }
    }

    stage('e) Docker Push') {
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail
docker push ${DOCKERHUB_REPO}:${IMAGE_TAG}
docker push ${DOCKERHUB_REPO}:latest
'''
      }
    }

    // ---- Minikube (K8s) ----
    stage('f) K8s Apply Manifests (Minikube)') {
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
'''
      }
    }

    stage('g) K8s Update Image & Rollout (Minikube)') {
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail
kubectl set image deployment/${APP_NAME} ${APP_NAME}=${DOCKERHUB_REPO}:${IMAGE_TAG} --record
kubectl rollout status deployment/${APP_NAME} --timeout=180s
'''
      }
    }

    // ---- EC2 (Docker) ----
    stage('h) Deploy to EC2 (Docker)') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', passwordVariable: 'DH_PASS', usernameVariable: 'DH_USER')]) {
          sshagent(credentials: ['ec2-ssh-key']) {
            sh '''#!/usr/bin/env bash
set -euo pipefail

# Uzak tarafta env taşıyarak bash ile çalıştır
ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} "DOCKERHUB_REPO=${DOCKERHUB_REPO} IMAGE_TAG=${IMAGE_TAG} DH_USER=${DH_USER} DH_PASS=${DH_PASS} bash -lc '
  set -euo pipefail

  # Docker yoksa kur
  if ! command -v docker >/dev/null 2>&1; then
    if [ -f /etc/debian_version ]; then
      sudo apt-get update && sudo apt-get install -y docker.io
      sudo systemctl enable --now docker
    else
      sudo yum update -y || true
      (sudo amazon-linux-extras install docker -y || sudo yum install -y docker)
      sudo systemctl enable --now docker
    fi
  fi

  # Docker Hub login (pull için)
  echo \"$DH_PASS\" | sudo docker login -u \"$DH_USER\" --password-stdin

  # Yeni imajı çek, eskiyi kaldır, yeniyi 80:5000 ile ayağa kaldır
  sudo docker pull \"$DOCKERHUB_REPO:$IMAGE_TAG\"
  sudo docker rm -f flask-app || true
  sudo docker run -d --name flask-app --restart unless-stopped -p 80:5000 \"$DOCKERHUB_REPO:$IMAGE_TAG\"
'"
'''
          }
        }
      }
    }

    stage('i) Post-Deploy Check (EC2)') {
      steps {
        sshagent(credentials: ['ec2-ssh-key']) {
          sh '''#!/usr/bin/env bash
set -euo pipefail
ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} 'bash -lc "
  set -euo pipefail
  sudo docker ps
  curl -fsS http://localhost/health || true
"'
'''
        }
      }
    }

    stage('j) Smoke Check (K8s Summary)') {
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail
kubectl get deploy,po,svc -o wide
kubectl get svc flask-service -o wide
'''
      }
    }
  }

  post {
    always {
      sh '''#!/usr/bin/env bash
set -euo pipefail
kubectl get pods -o wide || true
kubectl get svc || true
'''
    }
  }
}
