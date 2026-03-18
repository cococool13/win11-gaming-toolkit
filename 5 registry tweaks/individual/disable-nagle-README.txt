Windows Registry Editor Version 5.00

; NOTE: Nagle's Algorithm must be disabled per network adapter.
; This file cannot do it automatically because the registry key
; includes your adapter's unique GUID.
;
; To disable Nagle manually:
;   1. Open Registry Editor (regedit)
;   2. Navigate to:
;      HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces
;   3. Find the subkey that has your IP address in "DhcpIPAddress" or "IPAddress"
;   4. Create two new DWORD (32-bit) values:
;      - TcpAckFrequency = 1
;      - TCPNoDelay = 1
;
; Or use the network optimization script in "7 network/" which does
; this automatically via PowerShell.
