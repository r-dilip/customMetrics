"https://eastus.monitoring.azure.com/subscriptions//resourcegroups/acs-engine-test/providers/Microsoft.ContainerService/managedClusters/dilipr-watchapi/metrics"

$subId = "72c8e8ca-dc16-47dc-b65c-6b5875eb600a"
$tenantId = "72f988bf-86f1-41af-91ab-2d7cd011db47"
$aksRg = "acs-engine-test"
$clusterName="dilipr-watchapi"
$uaiName = "$($clusterName)-$($aksRg)-aad-pod-id"

# Get service principal ID for acs-engine cluster
CLUSTER_SP_ID=$(az ad sp list --display-name $aksRg --query "[?appDisplayName=='$aksRg'] | [0].appId" -o tsv)

# Create user assigned identity in the key vault rg
az identity create -g $aksRg -n $uaiName
UAI_ID=$(az identity show -g $KV_RG -n $uaiName --query id -o tsv)
UAI_CLIENT_ID=$(az identity show -g $KV_RG -n $uaiName --query clientId -o tsv)
UAI_PRINCIPAL_ID=$(az identity show -g $KV_RG -n $uaiName --query principalId -o tsv)

# Assign UAI the Reader Role on key vault
az role assignment create --role Reader --assignee $UAI_PRINCIPAL_ID --scope $KV_ID

# set policy to access secrets in your keyvault
az keyvault set-policy -n $KV_NAME --secret-permissions get list --spn $UAI_CLIENT_ID

# Let cluster service principal operate on behalf of the user assigned identity
az role assignment create --role "Managed Identity Operator" --assignee $CLUSTER_SP_ID --scope $UAI_ID

# Deploy aad-pod-identity infrastructure
kubectl create -f https://raw.githubusercontent.com/Azure/aad-pod-identity/master/deploy/infra/deployment.yaml

# Deploy KeyVault Flex volume infrastructure
kubectl create -f https://raw.githubusercontent.com/Azure/kubernetes-keyvault-flexvol/master/deployment/kv-flexvol-installer.yaml

# Deploy aad identity and binding
AAD_POD_IDENTITY_FILE_NAME=aadpodidentity.yaml

cat <<EOT >> $AAD_POD_IDENTITY_FILE_NAME
apiVersion: "aadpodidentity.k8s.io/v1"
kind: AzureIdentity
metadata:
 name: $uaiName
spec:
 type: 0
 ResourceID: $UAI_ID
 ClientID: $UAI_CLIENT_ID
---
apiVersion: "aadpodidentity.k8s.io/v1"
kind: AzureIdentityBinding
metadata:
 name: $uaiName-binding
spec:
 AzureIdentity: $uaiName
 Selector: $uaiName-binding-selector
EOT

kubectl apply -f $AAD_POD_IDENTITY_FILE_NAME
kubectl get azureidentity
kubectl get azureidentitybinding

# Deploy test app that needs test secret
DEPLOYMENT_FILE_NAME=deployment.yaml

cat <<EOT >> $DEPLOYMENT_FILE_NAME
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: nginx-flex-kv-podid
    aadpodidbinding: "$uaiName-binding-selector"
  name: nginx-flex-kv-podid
spec:
  containers:
  - name: nginx-flex-kv-podid
    image: nginx
    volumeMounts:
    - name: test
      mountPath: /kvmnt
      readOnly: true
  volumes:
  - name: test
    flexVolume:
      driver: "azure/kv"
      options:
        usepodidentity: "true"
        keyvaultname: "$KV_NAME"
        keyvaultobjectname: "$KV_SECRET_NAME"
        keyvaultobjecttype: secret # OPTIONS: secret, key, cert
        keyvaultobjectversion: "$KV_SECRET_VERSION"
        resourcegroup: "$KV_RG"
        subscriptionid: "$SUB_ID"
        tenantid: "$TENANT_ID"
EOT

kubectl apply -f $DEPLOYMENT_FILE_NAME