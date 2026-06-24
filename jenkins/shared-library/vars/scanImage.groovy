/**
 * scanImage.groovy
 *
 * Scans a Docker image with Trivy for OS and library vulnerabilities.
 * The pipeline fails fast if any CRITICAL severity CVE is found.
 * Results are also archived as a text report for audit purposes.
 *
 * @param imageName  Full Docker Hub image name
 * @param buildNum   Image tag (Jenkins build number)
 */
def call(String imageName, String buildNum) {
    echo "Scanning image: ${imageName}:${buildNum}"
    sh """
        # Install Trivy if not already present on the agent
        if ! command -v trivy &>/dev/null; then
            curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
                | sh -s -- -b /usr/local/bin
        fi

        trivy image \
            --exit-code 1 \
            --severity CRITICAL \
            --no-progress \
            --format table \
            --output trivy-report-${buildNum}.txt \
            ${imageName}:${buildNum}
    """
    archiveArtifacts artifacts: "trivy-report-${buildNum}.txt", allowEmptyArchive: false
}
