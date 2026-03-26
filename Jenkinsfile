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
                    sh """
                    export KUBECONFIG=$KUBECONFIG

                    kubectl apply -f k8s/

                    kubectl rollout restart deployment/pan

                    kubectl rollout status deployment/pan
                    """
                }
            }
        }
    }
}