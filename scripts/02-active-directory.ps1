# NOTA: los valores entre < > son las contraseñas y el secreto del laboratorio; no se publican en este repositorio.
# ==========================================================
# 02 - Active Directory (PowerShell como administrador en NPS-2241)
# ==========================================================

# Si la clave del Administrador local no cumple complejidad, cambiarla primero:
# net user Administrador <contraseña-usuarios>

# 1. Instalar el rol AD DS
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

# 2. Promover el servidor a controlador de dominio (pide la clave DSRM y reinicia solo)
Install-ADDSForest -DomainName "aaa2241.local" -DomainNetbiosName "AAA2241" -InstallDns -SafeModeAdministratorPassword (Read-Host -AsSecureString "Clave DSRM") -Force

# 3. Tras el reinicio, iniciar sesión como AAA2241\Administrador y verificar el dominio
Get-ADDomain | Select-Object Name, DNSRoot, DomainMode

# 4. Crear la OU, los 3 grupos y los 3 usuarios
New-ADOrganizationalUnit -Name "AAA-2241" -Path "DC=aaa2241,DC=local"

New-ADGroup -Name "GRP-Nivel0"  -GroupScope Global -GroupCategory Security -Path "OU=AAA-2241,DC=aaa2241,DC=local"
New-ADGroup -Name "GRP-Nivel5"  -GroupScope Global -GroupCategory Security -Path "OU=AAA-2241,DC=aaa2241,DC=local"
New-ADGroup -Name "GRP-Nivel10" -GroupScope Global -GroupCategory Security -Path "OU=AAA-2241,DC=aaa2241,DC=local"

$clave = ConvertTo-SecureString "<contraseña-usuarios>" -AsPlainText -Force

New-ADUser -Name "user-nivel0"  -SamAccountName "user-nivel0"  -UserPrincipalName "user-nivel0@aaa2241.local"  -AccountPassword $clave -Enabled $true -PasswordNeverExpires $true -Path "OU=AAA-2241,DC=aaa2241,DC=local"
New-ADUser -Name "user-nivel5"  -SamAccountName "user-nivel5"  -UserPrincipalName "user-nivel5@aaa2241.local"  -AccountPassword $clave -Enabled $true -PasswordNeverExpires $true -Path "OU=AAA-2241,DC=aaa2241,DC=local"
New-ADUser -Name "user-nivel10" -SamAccountName "user-nivel10" -UserPrincipalName "user-nivel10@aaa2241.local" -AccountPassword $clave -Enabled $true -PasswordNeverExpires $true -Path "OU=AAA-2241,DC=aaa2241,DC=local"

Add-ADGroupMember -Identity "GRP-Nivel0"  -Members "user-nivel0"
Add-ADGroupMember -Identity "GRP-Nivel5"  -Members "user-nivel5"
Add-ADGroupMember -Identity "GRP-Nivel10" -Members "user-nivel10"

# 5. Verificar (ejecutar uno por uno)
Get-ADGroup -Filter 'Name -like "GRP-Nivel*"' | Select-Object Name
Get-ADGroupMember -Identity "GRP-Nivel0"  | Select-Object Name
Get-ADGroupMember -Identity "GRP-Nivel5"  | Select-Object Name
Get-ADGroupMember -Identity "GRP-Nivel10" | Select-Object Name
