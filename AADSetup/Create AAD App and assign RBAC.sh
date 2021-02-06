echo "Creating AAD App for an Azure VM to use SPN credentials to access blob storage.."

create_spn_and_app(){
    # check if an SPN with this name already exists, if it does then skip this line
    if [ `az ad app list --display-name $APP_NAME | jq -r '.[] | length'` > 1 ]; then
        echo "${APP_NAME} exists. Skipping.."
    else
        echo "${APP_NAME} does not exist, creating ${APP_NAME}.."
        echo "Create AAD App registration"
        az ad app create --display-name $APP_NAME --homepage "http://localhost/$APP_NAME" --identifier-uris "http://localhost/$APP_NAME" --password $APP_PWD --output none
        APP_ID=$(az ad app list --display-name ${APP_NAME} --query [0].appId -o tsv)
        
        echo "Apply needed API permissions"
        
        # Azure Storage - user_impersonation - Delegated - Access Azure Storage
        echo "-- Azure Storage --"
        az ad app permission add --id $APP_ID --api e406a681-f3d4-42a8-90b6-c2b029497af1 --api-permissions 03e0da56-190b-40ad-a80c-ea378c433f7f=Scope

        # Graph API - User.Read - Delegated - Sign in and read profile
        echo "-- Graph API --"
        az ad app permission add --id $APP_ID --api 00000003-0000-0000-c000-000000000000 --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope

        echo "Create SPN"
        az ad sp create-for-rbac --name $APP_ID --role "Storage Blob Data Contributor" --scopes /subscriptions/$SUB_ID/resourceGroups/$STORAGE_RG/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME
        SP_APP_ID=$(az ad sp list --spn http://$APP_ID --query [0].appId -o tsv)

        echo "Grant delegated permissions"
        az ad app permission grant --id $SP_APP_ID --api e406a681-f3d4-42a8-90b6-c2b029497af1 --output none
        az ad app permission grant --id $SP_APP_ID --api 00000003-0000-0000-c000-000000000000 --output none
        echo "Done!"
    fi
}
# interactive login
az login
# Set subscription by Name
az account set --subscription $1

# now extract the subscription Id just in case $1 was the name
$SUB_ID = az account show --query id --output tsv

# Use year and current month as guid
guid=$(date '+%Y-%m')

# 2nd parameter is the app name for the new Azure Application you are creating
APP_NAME=$2

# third param is the password for the new Azure Application you are creating
APP_PWD= $3
#$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 ; echo '')

# 4th param is the storage account name that needs the RBAC permissions
STORAGE_ACCOUNT_NAME = $4

# 5th param is the resource group for the storage account
STORAGE_RG = $5
echo "Creating app (SPN) for $APP_NAME with password $APP_PWD.."
create_spn_and_app $APP_NAME $SUB_ID $APP_RG $STORAGE_ACCOUNT_NAME $APP_PWD