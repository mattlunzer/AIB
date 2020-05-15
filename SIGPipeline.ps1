#1 #### Create Variables ###

# Get existing context
$currentAzContext = Get-AzContext

# Get your current subscription ID. 
$subscriptionID=$currentAzContext.Subscription.Id

# Destination image resource group
$imageResourceGroup="aibwinsig"

# Location
$location="westus"

# Image distribution metadata reference name
$runOutputName="aibCustWinManImg05ro"

# Image template name
$imageTemplate="SIGImageTemplateWin10"
$imageTemplateName=$imageTemplate + (get-date -Format yymmddhhmmss)

# Distribution properties object name (runOutput).
# This gives you the properties of the managed image on completion.
$runOutputName="win10msclientR05"

# Create a resource group for Image Template and Shared Image Gallery
#New-AzResourceGroup `
#   -Name $imageResourceGroup `
#   -Location $location

#2 ### Create a user-assigned identity and set permissions on the resource group ###

# setup role def names, these need to be unique
#$timeInt=$(get-date -UFormat "%s")
#$imageRoleDefName="Azure Image Builder Image Def"+$timeInt
#$idenityName="aibIdentity"+$timeInt

#NewVar
$identityName="aibIdentity1589042999"

## Add AZ PS module to support AzUserAssignedIdentity
Install-Module -Name Az.ManagedServiceIdentity

# create identity
#New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName

$identityNameResourceId=$(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).Id
$identityNamePrincipalId=$(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).PrincipalId

### Assign permissions for identity to distribute images ###

#$aibRoleImageCreationUrl="https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json"
#$aibRoleImageCreationPath = "aibRoleImageCreation.json"

# download config
#Invoke-WebRequest -Uri $aibRoleImageCreationUrl -OutFile $aibRoleImageCreationPath -UseBasicParsing

#((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<subscriptionID>',$subscriptionID) | Set-Content -Path $aibRoleImageCreationPath
#((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<rgName>', $imageResourceGroup) | Set-Content -Path $aibRoleImageCreationPath
#((Get-Content -path $aibRoleImageCreationPath -Raw) -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName) | Set-Content -Path $aibRoleImageCreationPath

# create role definition
#New-AzRoleDefinition -InputFile  ./aibRoleImageCreation.json

# grant role definition to image builder service principal
#New-AzRoleAssignment -ObjectId $idenityNamePrincipalId -RoleDefinitionName $imageRoleDefName -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"

### NOTE: If you see this error: 'New-AzRoleDefinition: Role definition limit exceeded. No more role definitions can be created.' See this article to resolve:
#https://docs.microsoft.com/azure/role-based-access-control/troubleshooting

#3. ### Create the Shared Image Gallery ###

# Image gallery name
$sigGalleryName= "myIBSIG"

# Image definition name
$imageDefName ="win10msimage"

# additional replication region
$replRegion2="eastus"

# Create the gallery
#New-AzGallery `
#   -GalleryName $sigGalleryName `
#   -ResourceGroupName $imageResourceGroup  `
#   -Location $location

#Get-AzVMImageOffer -Location eastus -PublisherName MicrosoftWindowsDesktop | Select Offer

# Create the image definition
New-AzGalleryImageDefinition `
   -GalleryName $sigGalleryName `
   -ResourceGroupName $imageResourceGroup `
   -Location $location `
   -Name $imageDefName `
   -OsState generalized `
   -OsType Windows `
   -Publisher 'AzureSolutions' `
   -Offer 'WindowsClient' `
   -Sku 'WinSrv10MS'

#4 ### Download and configure the template ###

$templateFilePath = "armTemplateWin10MSSIG.json"

Invoke-WebRequest `
   -Uri "https://raw.githubusercontent.com/mattlunzer/AIB/master/armTemplateWin10MSSIG.json" `
   -OutFile $templateFilePath `
   -UseBasicParsing

(Get-Content -path $templateFilePath -Raw ) `
   -replace '<subscriptionID>',$subscriptionID | Set-Content -Path $templateFilePath
(Get-Content -path $templateFilePath -Raw ) `
   -replace '<rgName>',$imageResourceGroup | Set-Content -Path $templateFilePath
(Get-Content -path $templateFilePath -Raw ) `
   -replace '<runOutputName>',$runOutputName | Set-Content -Path $templateFilePath
(Get-Content -path $templateFilePath -Raw ) `
   -replace '<imageDefName>',$imageDefName | Set-Content -Path $templateFilePath
(Get-Content -path $templateFilePath -Raw ) `
   -replace '<sharedImageGalName>',$sigGalleryName | Set-Content -Path $templateFilePath
(Get-Content -path $templateFilePath -Raw ) `
   -replace '<region1>',$location | Set-Content -Path $templateFilePath
(Get-Content -path $templateFilePath -Raw ) `
   -replace '<region2>',$replRegion2 | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<imgBuilderId>',$identityNameResourceId) | Set-Content -Path $templateFilePath

### Create the image version ###

New-AzResourceGroupDeployment `
   -ResourceGroupName $imageResourceGroup `
   -TemplateFile $templateFilePath `
   -api-version "2019-05-01-preview" `
   -imageTemplateName $imageTemplateName `
   -svclocation $location

Invoke-AzResourceAction `
   -ResourceName $imageTemplateName `
   -ResourceGroupName $imageResourceGroup `
   -ResourceType Microsoft.VirtualMachineImages/imageTemplates `
   -ApiVersion "2019-05-01-preview" `
   -Action Run


#"publisher": "microsoftwindowsdesktop",
#"offer": "office-365",
#"sku": "19h2-evd-o365pp",
#"version": "latest"