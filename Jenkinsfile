pipeline {
    agent any

    environment {
        IMAGE      = "ghcr.io/luowei729/pan"
        TAG        = "${env.BUILD_NUMBER}"
        CACHE_TAG  = "cache"
        K8S_NAMESPACE = "pan"

        // ⚠️ 如果觉得慢，先改成 linux/amd64（强烈建议）
        PLATFORMS  = "linux/amd64,linux/arm64"

        DOCKER_CLI_EXPERIMENTAL = "enabled"
        DOCKER_BUILDKIT = "1"
    }

    stages {

        stage('拉代码') {
            steps {
                deleteDir()
                git branch: 'main', url: 'https://github.com/luowei729/pan.git'
            }
        }

        stage('检查 Docker / buildx') {
            steps {
                sh '''
                    set -eux
                    docker version
                    docker buildx version || true
                    docker buildx ls || true
                '''
            }
        }

        stage('准备 buildx / qemu') {
            steps {
                sh '''
                    set -eux

                    # 注册 QEMU（支持 arm64）
                    docker run --rm --privileged tonistiigi/binfmt --install all || true

                    # 创建 builder
                    docker buildx create --name panbuilder --driver docker-container --use 2>/dev/null || docker buildx use panbuilder

                    docker buildx inspect --bootstrap
                '''
            }
        }

        stage('登录 GHCR') {
            steps {
                withCredentials([string(credentialsId: 'ghcr-token', variable: 'TOKEN')]) {
                    sh '''
                        set -eux
                        echo "$TOKEN" | docker login ghcr.io -u luowei729 --password-stdin
                    '''
                }
            }
        }

        stage('拉取缓存镜像') {
            steps {
                sh '''
                    set -eux
                    docker pull ${IMAGE}:${CACHE_TAG} || true
                '''
            }
        }

        stage('Buildx 多架构构建并缓存') {
            steps {
                sh '''
                    set -eux

                    docker buildx build \
                      --platform ${PLATFORMS} \
                      --cache-from type=registry,ref=${IMAGE}:${CACHE_TAG} \
                      --cache-to type=registry,ref=${IMAGE}:${CACHE_TAG},mode=max \
                      --build-arg BUILDKIT_INLINE_CACHE=1 \
                      -t ${IMAGE}:${TAG} \
                      -t ${IMAGE}:latest \
                      --push \
                      .
                '''
            }
        }

        // ✅ 回归最稳定写法（你原来的方式）
        stage('部署到 K8s') {
            steps {
                withCredentials([
                    string(credentialsId: 'ghcr-token', variable: 'TOKEN'),
                    file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')
                ]) {
                    sh '''
                        set -eux
                        export KUBECONFIG=$KUBECONFIG

                        kubectl apply -f k8s/namespace.yaml

                        # 创建/更新镜像拉取凭证
                        kubectl create secret docker-registry ghcr-secret \
                          -n ${K8S_NAMESPACE} \
                          --docker-server=ghcr.io \
                          --docker-username=luowei729 \
                          --docker-password=$TOKEN \
                          --docker-email=xxx@gmail.com \
                          --dry-run=client -o yaml | kubectl apply -f -

                        # 部署非 Deployment 资源
                        for manifest in k8s/*.yaml; do
                          case "$manifest" in
                            k8s/namespace.yaml|k8s/deployment.yaml) continue ;;
                          esac
                          kubectl apply -f "$manifest"
                        done

                        # 使用当前构建号渲染 Deployment，避免 latest + rollout restart 产生额外 ReplicaSet
                        sed "s|${IMAGE}:latest|${IMAGE}:${TAG}|g" k8s/deployment.yaml | kubectl apply -f -

                        kubectl rollout status deployment/pan -n ${K8S_NAMESPACE}
                    '''
                }
            }
        }
    }
}
