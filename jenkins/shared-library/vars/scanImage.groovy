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
        TRIVY_BIN_DIR="\$WORKSPACE/.bin"
        export PATH="\$TRIVY_BIN_DIR:\$PATH"

        # Install Trivy if not already present on the agent
        if ! command -v trivy &>/dev/null; then
            mkdir -p "\$TRIVY_BIN_DIR"
            curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
                | sh -s -- -b "\$TRIVY_BIN_DIR"
        fi

        trivy image \
            --exit-code 1 \
            --severity CRITICAL \
            --ignore-unfixed \
            --no-progress \
            --format table \
            --output trivy-report-${buildNum}.txt \
            ${imageName}:${buildNum}
    """
    archiveArtifacts artifacts: "trivy-report-${buildNum}.txt", allowEmptyArchive: false
}
