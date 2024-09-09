

This keycloak helm chart adds a keycloak container to the same namespace as
the NBS modern system.

There is a required realm in the imports directory with file name
nbs-users.json.

There is also a sample theme added, it requires a persistent volume
currently tested using AWS EFS.  The theme needs to be loaded in
/opt/keycloak/themes/nbs/[login, etc] to be selectable from the keycloak
webui.  There are several methods to load this, it is complicated because
we are using the stock stripped down keycloak container as a base and it
does not have tar, curl etc.

We had tested using a config-map instead of a persistent volume but the one
large background file exceed the size limitations of config-maps

We have tested using a temporary container mounting the same Persistent volume
claim, creating a perminent file transfer sidecar and temporary file
transfer sidecar that can be scaled in and out on demand.

In the current configuration we have an init container that fetches the
entire release zip file and extracts the theme from that then copies it
into the appropriate directory, the path to download the zip file is set in
the values file.  This will probably changes as we anticipate the theme
will be maintained in the keycloak helm chart tree rather than current
github location.

At the moment that scripting in the init container wipes the directory
first and reinstalls nbs/login portion of the theme, we have other code in
test that sets a mode for this container to overwrite, preserve, ignore etc.

Note a non default theme is selected in keycloak (and then recorded in the
database) if it is later missing it will generate a white label error on
login.


Deploy the Helm Chart:

helm install keycloak ./keycloak

After the Helm chart is deployed, use the following command to copy the
theme files from your local machine to the Kubernetes pod:
kubectl get pods

export POD_NAME=$(kubectl get pods --namespace default -o name | grep keycloak | sed 's?pod/??g' | tail -1 )

# get a shell on init container
alias kcbi='export POD_NAME=$(kubectl get pods --namespace default -o name | grep keycloak | sed 's?pod/??g' | tail -1 );  kubectl exec -it -c theme-copy --namespace default "${POD_NAME}" -- sh'

kcbi

# actually copy the theme
export POD_NAME=$(kubectl get pods --namespace default -o name | grep keycloak | sed 's?pod/??g' | tail -1 )

kubectl cp keycloak/theme/nbs/login ${POD_NAME}:/keycloak/themes/ -c theme-copy

# need to clean up mount point to be consistent between init container and
# final container
# from charts dir

# check location to see files were copied
export POD_NAME=$(kubectl get pods --namespace default -o name | grep keycloak | sed 's?pod/??g' | tail -1 )

kubectl exec -it -c theme-copy --namespace default "${POD_NAME}" -- ls -l /keycloak/themes

Terminate the Init Container:

Once the files are copied, you can terminate the init container by running
the following command:

kubectl exec ${POD_NAME} -c theme-copy -- pkill sleep
