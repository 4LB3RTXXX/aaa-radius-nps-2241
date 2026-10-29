# NOTA: los valores entre < > son las contraseñas y el secreto del laboratorio; no se publican en este repositorio.
# ==========================================================
# 03 - NPS, servidor RADIUS (PowerShell como administrador en NPS-2241)
# ==========================================================

# 1. Instalar el rol y registrarlo en Active Directory
Install-WindowsFeature NPAS -IncludeManagementTools
netsh nps add registeredserver

# 2. Clientes RADIUS (router y switch), mismo secreto compartido que en los equipos
netsh nps add client name="R1-2241"  address=10.22.41.1 state=enable sharedsecret="<secreto-radius>"
netsh nps add client name="SW1-2241" address=10.22.41.2 state=enable sharedsecret="<secreto-radius>"
netsh nps show client

# 3. Directivas de red (se crean en la consola nps.msc, una por grupo)
#    nps.msc -> Directivas -> Directivas de red -> Nueva
#
#    Nombre            Grupo (condicion)     Atributo Cisco-AV-Pair
#    Nivel0-Cisco      GRP-Nivel0            shell:priv-lvl=0
#    Nivel5-Cisco      GRP-Nivel5            shell:priv-lvl=5
#    Nivel10-Cisco     GRP-Nivel10           shell:priv-lvl=10
#
#    Para cada directiva:
#    - Condiciones: Grupos de usuarios -> el grupo correspondiente
#    - Permiso de acceso: Acceso concedido
#    - Metodos de autenticacion: solo "Autenticacion sin cifrar (PAP, SPAP)"
#      (en el aviso sobre metodos no seguros, pulsar "No")
#    - Configuracion: Atributos especificos del proveedor -> Cisco -> Cisco-AV-Pair
#      con el valor de la tabla
#    - Atributos estandar: quitar Framed-Protocol y poner Service-Type = Inicio de sesion (Login)
#    - Orden de procesamiento: las tres directivas en las posiciones 1, 2 y 3
#    - Deshabilitar las dos directivas por defecto:
#        "Conexiones al servidor de Enrutamiento y acceso remoto de Microsoft"
#        "Conexiones a otros servidores de acceso"

# 4. Verificar
Get-Service IAS | Select-Object Name, Status
netsh nps show client
Get-NetFirewallRule -Enabled True -Direction Inbound | Where-Object { ($_ | Get-NetFirewallPortFilter).LocalPort -contains '1812' } | Select-Object DisplayName, Enabled

# 5. Auditoria de eventos de NPS (para ver accesos concedidos y denegados)
auditpol /set /subcategory:"{0CCE9243-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable

# 6. Exportar la configuracion de NPS (sin secretos)
netsh nps export filename="C:\repo-aaa2241\running-configs\NPS-2241-config.xml" exportPSK=NO
