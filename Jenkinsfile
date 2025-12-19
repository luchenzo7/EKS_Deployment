pipeline {
  agent any

  environment {
    AWS_REGION = "us-east-1"
    ECR_REPO   = "hello-python"
    IMAGE_TAG  = "${BUILD_NUMBER}"
    CLUSTER    = "tc2-dev-eks"
  }

  stages {
    stage("Checkout") {
      steps {
        checkout scm
      }
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
            248828787576.dkr.ecr.${AWS_REGION}.amazonaws.com
        """
      }
    }

    stage("Push Image") {
      steps {
        sh """
          docker tag ${ECR_REPO}:${IMAGE_TAG} \
            248828787576.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}

          docker push \
            248828787576.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
        """
      }
    }

    stage("Deploy to EKS") {
      steps {
        sh """
          aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER}

          helm upgrade hello-python helm/hello-python \
            --namespace hello-python \
            --set image.tag=${IMAGE_TAG}
        """
      }
    }
  }
}
