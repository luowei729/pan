pipeline {
    agent any

    environment {
        IMAGE = "ghcr.io/luowei729/pan"
        TAG = "${env.BUILD_NUMBER}"
    }

    stages {

        stage('拉代码') {
            steps {
                git 'https://github.com/pan.git'
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

        stage('部署到 K8s') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh """
                    kubectl apply -f k8s/

                    kubectl set image deployment/pan \
                    php-site=$IMAGE:$TAG

                    kubectl rollout status deployment/pan
                    """
                }
            }
        }
    }
}