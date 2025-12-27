pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  parameters {
    choice(
      name: 'ENVIRONMENT',
      choices: ['dev', 'prod'],
      description: 'Target environment'
    )
    booleanParam(
      name: 'DEPLOY',
      defaultValue: true,
      description: 'If unchecked, build/push only (no deploy)'
    )
  }

  environment {
    AWS_REGION     = "us-east-1"
    AWS_ACCOUNT_ID = "248828787576"
    ECR_REPO       = "hello-python"
    IMAGE_TAG      = "${BUILD_NUMBER}"
  }

  stages {

    stage("Set env vars") {
      steps {
        script {
          if (params.ENVIRONMENT == 'prod') {
            env.CLUSTER      = "tc2-prod-eks"
            env.HELM_VALUES  = "helm/hello-python/values-prod.yaml"
            // Keep same namespace if you already use it:
            env.NAMESPACE    = "hello-python"
            // Optional safer alternative:
            // env.NAMESPACE = "hello-python-prod"
            env.CREATE_NS_FLAG = ""   // no --create-namespace in prod
          } else {
            env.CLUSTER      = "tc2-dev-eks"
            env.HELM_VALUES  = "helm/hello-python/values.yaml"
            env.NAMESPACE    = "hello-python"
            env.CREATE_NS_FLAG = "--create-namespace"
          }
        }
      }
    }

    stage("Checkout") {
      steps { checkout scm }
    }

    stage("Build Image") {
      steps {
        sh """
          docker build -t ${ECR_REPO}:${IMAGE_TAG} app/hello-python
        """
      }
    }

    stage("Login to ECR") {
      steps {
        sh """
          aws ecr get-login-password --region ${AWS_REGION} \
          | docker login --username AWS --password-stdin \
            ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
        """
      }
    }

    stage("Push Image") {
      steps {
        sh """
          docker tag ${ECR_REPO}:${IMAGE_TAG} \
            ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}

          docker push \
            ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
        """
      }
    }

    stage("Manual approval (PROD only)") {
      when {
        allOf {
          expression { params.ENVIRONMENT == 'prod' }
          expression { params.DEPLOY == true }
        }
      }
      steps {
        input message: "Deploy to PROD cluster (${CLUSTER}) with image tag ${IMAGE_TAG}?", ok: "Deploy"
      }
    }

    stage("Deploy to EKS") {
      when { expression { params.DEPLOY == true } }
      steps {
        sh """
          set -e

          aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER}

          helm upgrade --install hello-python helm/hello-python \
            --namespace ${NAMESPACE} \
            ${CREATE_NS_FLAG} \
            -f ${HELM_VALUES} \
            --set image.repository=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO} \
            --set image.tag=${IMAGE_TAG}

          kubectl -n ${NAMESPACE} rollout status deploy/hello-python --timeout=180s || true
          kubectl -n ${NAMESPACE} get pods -o wide || true
          kubectl -n ${NAMESPACE} get svc || true
        """
      }
    }
  }
}
