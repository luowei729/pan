pipeline {
    agent any

    environment {
        IMAGE = "ghcr.io/luowei729/pan"
        TAG = "${env.BUILD_NUMBER}"
    }

    stages {

        stage('拉代码') {
            steps {
                deleteDir()
                git branch: 'main',
                    url: 'https://github.com/luowei729/pan.git'
            }
        }

        stage('构建镜像') {
            steps {
                sh "docker build -t $IMAGE:$TAG ."
                sh "docker tag $IMAGE:$TAG $IMAGE:latest"
            }
        }

        stage('推送镜像') {
            steps {
                withCredentials([string(credentialsId: 'ghcr-token', variable: 'TOKEN')]) {
                    sh """
                    echo $TOKEN | docker login ghcr.io -u luowei729 --password-stdin
                    docker push $IMAGE:$TAG
                    docker push $IMAGE:latest
                    """
                }
            }
        }

        stage('创建镜像拉取凭证') {
            steps {
                withCredentials([
                    string(credentialsId: 'ghcr-token', variable: 'TOKEN'),
                    file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')
                ]) {
                    sh '''
                    export KUBECONFIG=$KUBECONFIG

                    kubectl create secret docker-registry ghcr-secret \
                      --docker-server=ghcr.io \
                      --docker-username=luowei729 \
                      --docker-password=$TOKEN \
                      --docker-email=xxx@gmail.com \
                      --dry-run=client -o yaml | kubectl apply -f -
                    '''
                }
            }
        }

        stage('部署到 K8s') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh '''
                    set -eu
                    export KUBECONFIG="$KUBECONFIG"

                    kubectl get namespace rook-ceph >/dev/null 2>&1 || {
                      echo "rook-ceph namespace not found. Run: microk8s enable rook-ceph"
                      exit 1
                    }

                    kubectl get crd cephfilesystems.ceph.rook.io >/dev/null 2>&1 || {
                      echo "CephFilesystem CRD not found. Rook Ceph is not installed or not ready."
                      echo "For MicroK8s, enable the addon first: microk8s enable rook-ceph"
                      exit 1
                    }

                    kubectl -n rook-ceph get secret rook-csi-cephfs-provisioner >/dev/null 2>&1 || {
                      echo "CephFS CSI secret not found. The Ceph cluster is not ready or has not been imported."
                      echo "Finish creating/importing Ceph before deploying this app."
                      exit 1
                    }

                    kubectl apply -f k8s/rook-ceph-filesystem.yaml
                    kubectl apply -f k8s/rook-cephfs-storageclass.yaml
                    kubectl apply -f k8s/pvc.yaml

                    kubectl apply -f k8s/mysql-service.yaml
                    kubectl apply -f k8s/mysql.yaml
                    kubectl apply -f k8s/service.yaml
                    kubectl apply -f k8s/ingress.yaml
                    kubectl apply -f k8s/deployment.yaml

                    kubectl rollout restart deployment/pan

                    kubectl rollout status deployment/pan
                    '''
                }
            }
        }
    }
}
