<#
.SYNOPSIS
Keep the SSH tunnel to the Mac agent's streaming port alive.

.DESCRIPTION
The Mac agent listens only on 127.0.0.1, so the SignalRGB plugin reaches it
through this tunnel rather than over the LAN: nothing new is exposed on the
network, and SSH key auth is the only way in.

The plugin connects to 127.0.0.1:7532 on this PC; that is the local end of the
forward. MacHost is whatever your ~/.ssh/config calls the Mac.

.EXAMPLE
powershell -ExecutionPolicy Bypass -File windows\start-mac-tunnel.ps1

.EXAMPLE
Register it to run at logon (adjust the repo path if you moved it):

    schtasks /create /tn "headless-lights mac tunnel" /sc onlogon /rl limited ^
      /tr "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Users\Michel\Projetos\headless-rgb\windows\start-mac-tunnel.ps1"
#>

[CmdletBinding()]
param(
    [string] $MacHost = 'mac',
    [int] $Port = 7532,
    [int] $RetrySeconds = 5
)

$ErrorActionPreference = 'Stop'

$sshArguments = @(
    '-N'                                  # no remote command, forwarding only
    '-T'                                  # no pty
    '-o', 'BatchMode=yes'                 # fail instead of prompting
    '-o', 'ExitOnForwardFailure=yes'      # do not sit there with a dead forward
    '-o', 'ServerAliveInterval=15'
    '-o', 'ServerAliveCountMax=3'
    '-L', "127.0.0.1:${Port}:127.0.0.1:${Port}"
    $MacHost
)

Write-Host "tunneling 127.0.0.1:${Port} -> ${MacHost}:127.0.0.1:${Port}"
Write-Host 'Ctrl+C to stop.'

while ($true) {
    $started = Get-Date
    try {
        & ssh @sshArguments
        $code = $LASTEXITCODE
    } catch {
        $code = -1
        Write-Host "ssh failed to start: $($_.Exception.Message)"
    }

    $lifetime = [int] ((Get-Date) - $started).TotalSeconds
    Write-Host "ssh exited with $code after ${lifetime}s; reconnecting in ${RetrySeconds}s"
    Start-Sleep -Seconds $RetrySeconds
}
