
mkdir c:\buildArtifacts
echo MJL-Azure-Image-Builder-Was-Here  > c:\buildArtifacts\azureImageBuilder.txt

#Install FSLogix
FSLogixAppsSetup.exe /install /quiet

#Disable WU
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f

#Setup TZ Redirection
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fEnableTimeZoneRedirection /t REG_DWORD /d 1 /f

