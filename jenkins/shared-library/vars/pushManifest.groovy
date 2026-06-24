/**
 * pushManifest.groovy
 *
 * Commits the updated Kubernetes manifest back to Git and pushes it.
 * This is the GitOps trigger: once the manifest lands on main, ArgoCD
 * detects the image tag change and rolls out the new version automatically.
 *
 * Git credentials are stored in Jenkins as a "Username with password" secret
 * (ID: github-credentials) where the password is a GitHub Personal Access Token.
 *
 * @param buildNum       Jenkins build number (used in the commit message)
 * @param credentialsId  Jenkins credentials ID for GitHub access
 */
def call(String buildNum, String credentialsId = 'github-credentials') {
    withCredentials([usernamePassword(
        credentialsId: credentialsId,
        usernameVariable: 'GIT_USER',
        passwordVariable: 'GIT_TOKEN'
    )]) {
        sh """
            git config user.email "jenkins@flask-cicd-gitops-platform"
            git config user.name  "Jenkins CI"
            git add kubernetes/overlays/dev/deployment-patch.yaml
            git diff --cached --quiet || git commit -m "ci: update image tag to build-${buildNum} [skip ci]"
            git push https://\${GIT_USER}:\${GIT_TOKEN}@github.com/Ike-DevCloudIQ/flask-cicd-gitops-platform.git HEAD:main
        """
    }
}
