/**
 * pushManifest.groovy
 *
 * Commits the updated Kubernetes manifest back to Git and pushes it.
 * This is the GitOps trigger: once the manifest lands on main, ArgoCD
 * detects the image tag change and rolls out the new version automatically.
 *
 * Uses SSH key-based authentication (github_deploy_key) for secure Git operations.
 * The private key is stored on the Jenkins master at /var/lib/jenkins/.ssh/github_deploy_key
 *
 * @param buildNum       Jenkins build number (used in the commit message)
 */
def call(String buildNum) {
    sh """
        # Configure Git SSH with Jenkins deploy key
        export GIT_SSH_COMMAND="ssh -i /var/lib/jenkins/.ssh/github_deploy_key -o StrictHostKeyChecking=accept-new"
        
        git config user.email "jenkins@flask-cicd-gitops-platform"
        git config user.name  "Jenkins CI"
        git add kubernetes/overlays/dev/deployment-patch.yaml
        git diff --cached --quiet || git commit -m "ci: update image tag to build-${buildNum} [skip ci]"
        git push git@github.com:Ike-DevCloudIQ/flask-cicd-gitops-platform.git HEAD:main
    """
}
