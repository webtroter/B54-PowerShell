#--------------------------------------
# Modification du dossier par d�faut des disques durs virtuels
# Modification du dossier par d�faut des ordinateurs virtuels
# Cr�ation d'un commutateur virtuel de type "PRIV�"
# Cr�ation de trois ordinateurs virtuels
#
# Ce code doit s'ex�cuter sur votre serveur r�el
#
# Richard Jean
#
# 30 novembre 2018
#--------------------------------------

Clear-Host

#-------------------------------------------------------------
# Modification du dossier par d�faut des disques durs virtuels
#-------------------------------------------------------------
Set-VMHost  -VirtualHardDiskPath  C:\_VirDisque

#------------------------------------------------------------
# Modification du dossier par d�faut des ordinateurs virtuels
#------------------------------------------------------------
Set-VMHost  -VirtualMachinePath  C:\_VirOrdi

#-------------------------------------------------
# Cr�ation du commutateur virtuel "ComPriv�"
#-------------------------------------------------
$collection = (Get-VMSwitch).Name

$nom_switch = "ComPriv�"

if ($nom_switch -notin $collection)
{
  Write-Host "Création du commutateur virtuel $nom_switch" -Foreground Yellow
  New-VMSwitch -Name $nom_switch `
               -SwitchType Private
}
else
{
  Write-Warning "Le commutateur virtuel $nom_switch existe d�j�."
}

#----------------------------------------------------------------------
# Le commutateur virtuel de type EXTERNE doit avoir le nom "ComPublic"
#----------------------------------------------------------------------

#-------------------------------------------------
# Création des trois ordinateurs virtuels
#-------------------------------------------------
New-VM -Name "Serveur1" `
       -Generation 2 `
       -VHDPath "serv1.vhdx" `
		-SwitchName "ComPublic"

New-VM -Name "Serveur2" `
       -Generation 2 `
       -VHDPath "serv2.vhdx" `
		-SwitchName "ComPriv�"

# Ajout de la deuxi�me carte r�seau pour "Serveur2"
Add-VMNetworkAdapter -VMName "Serveur2" `
                    -SwitchName "ComPublic"

New-VM -Name "Serveur3" `
       -Generation 2 `
       -VHDPath "serv3.vhdx" `
       -SwitchName "ComPriv�"

for ($i = 1; $i -le 3; $i++)
{
 Set-VMMemory -VMName "Serveur$i" `
              -DynamicMemoryEnabled $true `
              -MaximumBytes 8192MB `
              -MinimumBytes 4096MB `
              -StartupBytes 4096MB

 Set-VMProcessor -VMName "Serveur$i" `
                 -Count 8
}
