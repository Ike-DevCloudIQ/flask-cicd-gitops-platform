/**
 * pushImage.groovy
 *
 * Pushes the scanned and approved image to Docker Hub.
 * Credentials are stored in Jenkins as a "Username with password" secret
 * (ID: dockerhub-credentials) and are never exposed in logs.
 *
 * @param imageName        Full Docker Hub image name
 * @param buildNum         Image tag (Jenkins build number)
 * @param credentialsId    Jenkins credentials ID for Docker Hub login
 */
def call(String imageName, String buildNum, String credentialsId = 'dockerhub-credentials') {
    echo "Pushing image: ${imageName}:${buildNum}"
    withCredentials([usernamePassword(
        credentialsId: credentialsId,
        usernameVariable: 'DOCKER_USER',
        passwordVariable: 'DOCKER_PASS'
    )]) {
        sh """
            echo "\$DOCKER_PASS" | docker login -u "\$DOCKER_USER" --password-stdin
            docker push ${imageName}:${buildNum}
            docker logout
        """
    }
}
