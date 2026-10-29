# NOTA: los valores entre < > son las contraseñas y el secreto del laboratorio; no se publican en este repositorio.
# ==========================================================
# 06 - Pruebas, SSH y exportacion de configuraciones
# (PowerShell como administrador en NPS-2241)
# ==========================================================

# ---------- 1. Configuracion del cliente SSH ----------
# La imagen de IOS 15.2 solo ofrece cifrados CBC y algoritmos antiguos,
# desactivados por defecto en el cliente SSH de Windows.
New-Item -ItemType Directory -Force "$env:USERPROFILE\.ssh" | Out-Null
@"
Host 10.22.41.1
    KexAlgorithms +diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha1
    HostKeyAlgorithms +ssh-rsa
    Ciphers +aes128-cbc,aes256-cbc

Host 10.22.41.2
    KexAlgorithms +diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha1
    HostKeyAlgorithms +ssh-rsa
    Ciphers +aes128-cbc,aes256-cbc
"@ | Add-Content -Encoding ascii "$env:USERPROFILE\.ssh\config"

# Si se recrea un equipo, borrar la huella anterior:
# ssh-keygen -R 10.22.41.1
# ssh-keygen -R 10.22.41.2

# ---------- 2. Acceso por SSH con el usuario local ----------
ssh admin-local@10.22.41.1
ssh admin-local@10.22.41.2
# Dentro de cada sesion:
#   show privilege
#   show running-config | section aaa
#   show aaa servers
#   show logging | include SEC_LOGIN|PRIV_AUTH|LOGOUT

# ---------- 3. Pruebas por consola (en la consola de cada equipo, GNS3) ----------
# Usuarios: user-nivel0, user-nivel5, user-nivel10 (clave <contraseña-usuarios>)
#   nivel 0 : ?
#   nivel 5 : show privilege / show ip interface brief / ping 10.22.41.10 / show running-config (rechazado)
#   nivel 10: show privilege / show running-config / show logging / configure terminal (rechazado)
# Login fallido: user-nivel5 con una contrasena incorrecta

# ---------- 4. Eventos de NPS: accesos concedidos (6272) y denegados (6273) ----------
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=6272,6273} -MaxEvents 8 | Select-Object TimeCreated, Id, @{n='Evento';e={($_.Message -split "`r?`n")[0]}} | Format-Table -AutoSize -Wrap

# ---------- 5. Exportar las configuraciones al repositorio ----------
# Primero, en cada equipo por SSH: configure terminal / line vty 0 4 (switch: 0 15) / length 0 / end / write memory
New-Item -ItemType Directory -Force C:\repo-aaa2241\running-configs, C:\repo-aaa2241\scripts, C:\repo-aaa2241\image | Out-Null
ssh admin-local@10.22.41.1 "show running-config" | Out-File -Encoding ascii C:\repo-aaa2241\running-configs\R1-2241-running-config.txt
ssh admin-local@10.22.41.2 "show running-config" | Out-File -Encoding ascii C:\repo-aaa2241\running-configs\SW1-2241-running-config.txt

# Ocultar la clave RADIUS (formato reversible) antes de publicar
foreach ($f in "R1-2241","SW1-2241") { $p = "C:\repo-aaa2241\running-configs\$f-running-config.txt"; (Get-Content $p) -replace 'key 7 \S+','key 7 <OCULTO>' | Set-Content -Encoding ascii $p }

netsh nps export filename="C:\repo-aaa2241\running-configs\NPS-2241-config.xml" exportPSK=NO
