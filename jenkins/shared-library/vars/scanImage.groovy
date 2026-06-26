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

        # Check if Trivy is already available (pre-installed on slave)
        if command -v trivy &>/dev/null; then
            echo "Using pre-installed Trivy: \$(which trivy)"
        else
            # Install Trivy with retries if not present
            mkdir -p "\$TRIVY_BIN_DIR"
            max_attempts=3
            for attempt in \$(seq 1 \$max_attempts); do
                echo "Downloading Trivy (attempt \$attempt/\$max_attempts)..."
                if curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
                    | sh -s -- -b "\$TRIVY_BIN_DIR"; then
                    echo "Trivy installation successful"
                    break
                elif [ \$attempt -lt \$max_attempts ]; then
                    echo "Download failed, retrying in 5 seconds..."
                    sleep 5
                else
                    echo "Failed to download Trivy after \$max_attempts attempts"
                    exit 1
                fi
            done
        fi

        # Run Trivy scan with critical severity only
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
