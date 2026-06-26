/**
 * pushManifest.groovy
 *
 * Commits the updated Kubernetes manifest back to Git and pushes it.
 * This is the GitOps trigger: once the manifest lands on main, ArgoCD
 * detects the image tag change and rolls out the new version automatically.
 *
 * Uses Jenkins-managed SSH credentials so pushes work on any build agent.
 *
 * @param buildNum       Jenkins build number (used in the commit message)
 * @param credentialsId  Jenkins SSH private key credential ID (default: github-ssh-key)
 */
def call(String buildNum, String credentialsId = 'github-ssh-key') {
    withCredentials([sshUserPrivateKey(credentialsId: credentialsId, keyFileVariable: 'GIT_SSH_KEY')]) {
        sh """
            export GIT_SSH_COMMAND="ssh -i \"$GIT_SSH_KEY\" -o StrictHostKeyChecking=accept-new"

            git config user.email "jenkins@flask-cicd-gitops-platform"
            git config user.name  "Jenkins CI"
            git add kubernetes/overlays/dev/deployment-patch.yaml
            git diff --cached --quiet || git commit -m "ci: update image tag to build-${buildNum} [skip ci]"
            git push git@github.com:Ike-DevCloudIQ/flask-cicd-gitops-platform.git HEAD:main
        """
    }
}
