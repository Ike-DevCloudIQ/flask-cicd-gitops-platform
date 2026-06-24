/**
 * buildImage.groovy
 *
 * Builds a Docker image and tags it with the Jenkins build number.
 * Using the build number (not "latest") means every image is uniquely
 * traceable to the exact pipeline run that produced it.
 *
 * @param imageName  Full Docker Hub image name, e.g. "emekaezedozie276/flask-app"
 * @param buildNum   Jenkins BUILD_NUMBER — used as the image tag
 * @param dockerfile Path to the Dockerfile, relative to workspace root
 */
def call(String imageName, String buildNum, String dockerfile = 'docker/Dockerfile') {
    echo "Building image: ${imageName}:${buildNum}"
    sh """
        docker build \
            -t ${imageName}:${buildNum} \
            -f ${dockerfile} \
            .
    """
}
