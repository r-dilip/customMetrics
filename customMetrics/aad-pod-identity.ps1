az group create -n dilipr-weu -l westeurope
az keyvault create -n keyvaultk8s -g dilipr-weu -l westeurope
az keyvault secret set -n mySecret --vault-name keyvaultk8s --value MySuperSecretThatIDontWantToShareWithYou!

#To create a managed identity, you can use this command:


az identity create -n dilipr-kv-identity -g dilipr-weu
{
  "clientId": "f6d3d765-50d1-47b1-975b-6448d741f5a6",
  "clientSecretUrl": "https://control-westeurope.identity.azure.net/subscriptions/72c8e8ca-dc16-47dc-b65c-6b5875eb600a/resourcegroups/dilipr-weu/providers/Microsoft.ManagedIdentity/userAssignedIdentities/dilipr-kv-identity/credentials?tid=72f988bf-86f1-41af-91ab-2d7cd011db47&oid=b0d77a2e-3348-4bc6-9052-a4b51f643719&aid=f6d3d765-50d1-47b1-975b-6448d741f5a6",
  "id": "/subscriptions/72c8e8ca-dc16-47dc-b65c-6b5875eb600a/resourcegroups/dilipr-weu/providers/Microsoft.ManagedIdentity/userAssignedIdentities/dilipr-kv-identity",
  "location": "westeurope",
  "name": "dilipr-kv-identity",
  "principalId": "b0d77a2e-3348-4bc6-9052-a4b51f643719",
  "resourceGroup": "dilipr-weu",
  "tags": {},
  "tenantId": "72f988bf-86f1-41af-91ab-2d7cd011db47",
  "type": "Microsoft.ManagedIdentity/userAssignedIdentities"
}

az role assignment create --role "Reader" --assignee 'b0d77a2e-3348-4bc6-9052-a4b51f643719' --scope /subscriptions/72c8e8ca-dc16-47dc-b65c-6b5875eb600a/resourceGroups/dilipr-weu/providers/Microsoft.KeyVault/vaults/keyvaultk8s

az keyvault set-policy -n keyvaultk8s --secret-permissions get list --spn 'f6d3d765-50d1-47b1-975b-6448d741f5a6'

#aad-pod-identity uses the service principal of your Kubernetes cluster to access the Azure managed identity resource and work with it.
# This is why you need to give this service principal the rights to use the managed identity created before:
az role assignment create --role "Managed Identity Operator" --assignee  --scope /subscriptions/72c8e8ca-dc16-47dc-b65c-6b5875eb600a/resourceGroups/dilipr-weu/providers/Microsoft.ManagedIdentity/userAssignedIdentities/dilipr-kv-identity

11/29/2018

kubectl create -f https://raw.githubusercontent.com/Azure/aad-pod-identity/master/deploy/infra/deployment.yaml
az identity create -n dilipr-pod-id -g acs-engine-test
{
  "clientId": "25a88763-a64f-44bb-9999-20dc12701e83",
  "clientSecretUrl": "https://control-eastus.identity.azure.net/subscriptions/72c8e8ca-dc16-47dc-b65c-6b5875eb600a/resourcegroups/acs-engine-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/dilipr-pod-id/credentials?tid=72f988bf-86f1-41af-91ab-2d7cd011db47&oid=74e32c1a-4d13-4f1b-81f5-ce257e0d8956&aid=25a88763-a64f-44bb-9999-20dc12701e83",
  "id": "/subscriptions/72c8e8ca-dc16-47dc-b65c-6b5875eb600a/resourcegroups/acs-engine-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/dilipr-pod-id",
  "location": "eastus",
  "name": "dilipr-pod-id",
  "principalId": "74e32c1a-4d13-4f1b-81f5-ce257e0d8956",
  "resourceGroup": "acs-engine-test",
  "tags": {},
  "tenantId": "72f988bf-86f1-41af-91ab-2d7cd011db47",
  "type": "Microsoft.ManagedIdentity/userAssignedIdentities"
}

#Using the principalid from the last step, assign reader role to new identity for this resource
az role assignment create --role "Monitoring Metrics Publisher" --assignee '74e32c1a-4d13-4f1b-81f5-ce257e0d8956' --scope /subscriptions/72c8e8ca-dc16-47dc-b65c-6b5875eb600a/resourcegroups/acs-engine-test/providers/Microsoft.ContainerService/managedClusters/dilipr-watchapi

#the Selector that has been defined earlier in the AzureIdentityBinding is used with the aadpodidbinding label. This is where the binding between the Azure identity and the pod is done.

