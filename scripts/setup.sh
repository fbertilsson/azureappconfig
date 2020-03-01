#!/bin/bash
# It is convenient to run this script in Azure Cloud Shell

appConfigName=AzureAppConfig1
#resource name must be lowercase
appConfNameProd=${appConfigName,,}"-prod"
appConfNameTest=${appConfigName,,}"-test"
groupName="rg-"$appConfigName
location=westeurope

# Create resource group 
az group create --name $groupName --location $location

# Create the Azure AppConfig Service resource and query the hostName
appConfigHostnameProd=$(az appconfig create \
  --name $appConfNameProd \
  --location $location \
  --resource-group $groupName \
  --query hostName \
  --sku free \
  -o tsv
  )

# Get the AppConfig connection string 
appConfigConnectionStringProd=$(az appconfig credential list \
--resource-group $groupName \
--name $appConfNameProd \
--query "[?name=='Secondary Read Only'] .connectionString" -o tsv)

# Echo the connection string for use in your application
echo "Prod: $appConfigConnectionStringProd"


# Create the Azure AppConfig Service resource and query the hostName
appConfigHostnameTest=$(az appconfig create \
  --name $appConfNameTest \
  --location $location \
  --resource-group $groupName \
  --query hostName \
  --sku free \
  -o tsv
  )

# Get the AppConfig connection string 
appConfigConnectionStringTest=$(az appconfig credential list \
--resource-group $groupName \
--name $appConfNameTest \
--query "[?name=='Secondary Read Only'] .connectionString" -o tsv)

# Echo the connection string for use in your application
echo "Test: $appConfigConnectionStringTest"

# Create plan
planName="asp-plan"
az appservice plan create \
    --name $planName \
    --resource-group $groupName \
    --location $location \
    --sku S1

# Create webapp
webappName="fagdag2020"
az webapp create \
  --name $webappName \
  --resource-group $groupName \
  --plan $planName

az webapp deployment slot create \
    --name $webappName \
    --resource-group $groupName \
    --slot test

az webapp config appsettings set \
    -g $groupName \
    -n $webappName \
    --slot "test" \
    --slot-settings "ConnectionStrings:AppConfig"=$appConfigConnectionStringTest

az webapp config appsettings set \
    -g $groupName \
    -n $webappName \
    --slot-settings "ConnectionStrings:AppConfig"=$appConfigConnectionStringProd
