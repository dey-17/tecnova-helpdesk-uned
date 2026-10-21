param([string]$Servidor='(localdb)\MSSQLLocalDB',[Parameter(Mandatory=$true)][string]$Nombre,[Parameter(Mandatory=$true)][string]$Email)
$ErrorActionPreference='Stop'
$claveTecnova=Read-Host 'Contraseña del administrador (mínimo 12 caracteres)' -AsSecureString
$ptrTecnova=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($claveTecnova)
try {
    $textoTecnova=[Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptrTecnova)
    if($textoTecnova.Length -lt 12 -or $textoTecnova.Length -gt 128){throw 'Longitud de contraseña inválida.'}
    $bibliotecaTecnova=Join-Path $PSScriptRoot '../Tecnova.HelpDesk/bin/Tecnova.HelpDesk.dll'
    Add-Type -Path $bibliotecaTecnova
    $hashTecnova=[Tecnova.HelpDesk.Security.Passwords]::Hash($textoTecnova)
    $conexionTecnova=New-Object System.Data.SqlClient.SqlConnection "Data Source=$Servidor;Initial Catalog=TecnovaHelpDesk;Integrated Security=True"
    $conexionTecnova.Open()
    try {
        $comandoTecnova=$conexionTecnova.CreateCommand()
        $comandoTecnova.CommandText="IF EXISTS(SELECT 1 FROM Usuarios WHERE Rol='Administrador') THROW 51000,'Ya existe un administrador; no se modifica.',1; INSERT Usuarios(Nombre,Email,PasswordHash,Rol) VALUES(@n,@e,@p,'Administrador');"
        [void]$comandoTecnova.Parameters.AddWithValue('@n',$Nombre.Trim())
        [void]$comandoTecnova.Parameters.AddWithValue('@e',$Email.Trim().ToLowerInvariant())
        [void]$comandoTecnova.Parameters.AddWithValue('@p',$hashTecnova)
        [void]$comandoTecnova.ExecuteNonQuery()
        Write-Host 'Administrador creado. Ya puede iniciar sesión.'
    }finally{$conexionTecnova.Dispose()}
}finally{[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptrTecnova);$textoTecnova=$null}
