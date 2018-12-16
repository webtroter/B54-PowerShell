
<#PSScriptInfo

.DATE 28 novembre 2018

.VERSION 0.5

.AUTHOR Yasmine Kaddouri

.DESCRIPTION 
installer et configurer HV et créer les répertoires


.EXTERNALMODULEDEPENDENCIES
HyperV
SUR SR
#>
Install-WindowsFeature -Name Hyper-V -IncludeAllSubFeature -IncludeManagementTools

$HyperVSettings = @{
    VirtualHardDiskPath = "C:\_VirDisque"
    VirtualMachinePath = "C:\_VirOrdi"
}
$HyperVSettings.Values | ForEach-Object { New-Item -Path $_ -ItemType Directory }
Set-VMHost @HyperVSettings
#interface réseaux
$Nic = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}

Rename-NetAdapter -Name $Nic.Name -NewName "CartePublique"

New-VMSwitch -Name "ComPublic" -SwitchType External -NetAdapterName $Nic.Name
New-VMSwitch -Name "ComPrive" -SwitchType Private

$serveur2016parent = "$($HyperVSettings['VirtualHardDiskPath'])\serveur2016.vhdx"
$parentvhd = New-VHD -Path $serveur2016parent -SizeBytes 32GB -Fixed

####  Créer serveur2016 manuellement. avec le disque dur existant.
Read-Host -Prompt "Créer le serveur 2016 parent."
# une fois l'installation complété, avant de créer le mot de passe admin, arrêter le serveur virtuel
# au pire, shift+f10 ouvre une console, la commande "shutdown /i" peut aider
# 
# Après avoir éteint le serveur, marquer le disque dur virtuel comme read-only


$virtualdiskname = @("serv1.vhdx", "serv2.vhdx", "serv3.vhdx")
$virtualdisks = foreach ($disk in $virtualdiskname) {
    New-VHD -Path "$($HyperVSettings['VirtualHardDiskPath'])\$disk" -SizeBytes 32GB -Differencing -ParentPath $parentvhd.Path
}
#region Page 7, point 3
$RAM = @(4096MB, 4096MB, 8192MB) # Ram Config (Start,Min,Max)
$vm1 = New-VM -Name "Serveur1" -MemoryStartupBytes $RAM[0] -SwitchName "ComPublic" -VHDPath $virtualdisks[0].Path
$vm1 | set-vm -MemoryMinimumBytes $RAM[1] -MemoryMaximumBytes $RAM[2]
# TODO: Écrire pour serveur 2 et 3

$vm2 = New-VM -Name "Serveur2" -MemoryStartupBytes $RAM[0] -SwitchName "ComPublic" -VHDPath $virtualdisks[1].Path
$vm2 | set-vm -MemoryMinimumBytes $RAM[1] -MemoryMaximumBytes $RAM[2]
Add-VMNetworkAdapter -VMName $vm2.VMName -SwitchName "ComPrive"

$vm3 = New-VM -Name "Serveur3" -MemoryStartupBytes $RAM[0] -SwitchName "ComPrive" -VHDPath $virtualdisks[2].Path
$vm3 | set-vm -MemoryMinimumBytes $RAM[1] -MemoryMaximumBytes $RAM[2]
#endregion