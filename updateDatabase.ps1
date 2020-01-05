param([switch]$upd, [switch]$install, [switch]$lazymode, [string]$db)
if($install -eq $true) {
    invoke-expression ".\install.ps1"
}
if($upd -eq $true) {
    invoke-expression "lib\runUpdate.ps1"
}
if($lazymode -eq $true) {
    invoke-expression "lib\runUpdate.ps1 -lazymode -lazymodedb ""$db"""
}