/**
 * updateManifest.groovy
 *
 * Updates the container image tag in the Kubernetes deployment patch file.
 * Uses sed for an in-place replacement — no YAML parser dependency required.
 *
 * After this step the working tree has a modified manifest file that
 * pushManifest.groovy will commit and push to trigger ArgoCD.
 *
 * @param imageName   Full Docker Hub image name
 * @param buildNum    New image tag (Jenkins build number)
 * @param patchFile   Relative path to the kustomize patch file to update
 */
def call(String imageName, String buildNum, String patchFile = 'kubernetes/overlays/dev/deployment-patch.yaml') {
    echo "Updating manifest: ${patchFile} → ${imageName}:${buildNum}"
    sh """
        sed -i 's|image: ${imageName}:.*|image: ${imageName}:${buildNum}|g' ${patchFile}
        grep "image:" ${patchFile}
    """
}
