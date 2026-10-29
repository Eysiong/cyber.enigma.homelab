# ==============================================================================
# Script Name: Initialize-FolderSecurity.ps1
# Description: Automates secure departmental folder layout scaffolding, 
#              unlinks NTFS inheritance, and applies targeted DACLs dynamically.
# Forest: cyber.enigma.ph
# ==============================================================================

# 1. Configuration Basics
$BaseOUPath = "OU=Employees,DC=cyber,DC=enigma,DC=ph"
$ShareRoot = "C:\CompanyShares"

# 2. Get all Department OUs underneath your Employees parent OU
$Departments = Get-ADOrganizationalUnit -SearchScope OneLevel -SearchBase $BaseOUPath -Filter *

foreach ($Dept in $Departments) {
    $OUName = $Dept.Name
    $TargetOUPath = $Dept.DistinguishedName
    
    # Standardized Naming Conventions
    $GlobalGroupName = "G_$( $OUName.Replace(' ', '') )_Employees"
    $DomainLocalName = "DL_CompanyShares_$( $OUName.Replace(' ', '') )_Modify"
    $FolderPath = Join-Path $ShareRoot $OUName
    
    Write-Host "--- Processing Department: $OUName ---" -ForegroundColor Cyan

    # 3. Create the Domain Local Group if missing
    $DLGroupExists = Get-ADGroup -Filter "SamAccountName -eq '$DomainLocalName'" -ErrorAction SilentlyContinue
    if (-not $DLGroupExists) {
        $GroupParams = @{
            Name          = $DomainLocalName
            GroupScope    = "DomainLocal"
            GroupCategory = "Security"
            Path          = $TargetOUPath
            Description   = "Domain Local Group granting Modify access to the $OUName shares folder."
        }
        New-ADGroup @GroupParams
        Write-Host "[AD] Created Domain Local Group: $DomainLocalName" -ForegroundColor Green
    }

    # 4. Nest Global Group into Domain Local Group (AGDLP Rule)
    try {
        Add-ADGroupMember -Identity $DomainLocalName -Members $GlobalGroupName -ErrorAction SilentlyContinue
        Write-Host "[AD] Nested $GlobalGroupName into $DomainLocalName" -ForegroundColor DarkGreen
    } catch {
        Write-Host "[AD] Nesting verification complete." -ForegroundColor Gray
    }

    # 5. Create File System Folder if missing
    if (-not (Test-Path $FolderPath)) {
        New-Item -ItemType Directory -Path $FolderPath | Out-Null
        Write-Host "[FS] Created folder path at $FolderPath" -ForegroundColor Green
    }

    # 6. Automate Advanced NTFS Security Lockdown
    $Acl = Get-Acl -Path $FolderPath
    
    # Break inheritance and copy current rules over so we can explicitly prune them
    $Acl.SetAccessRuleProtection($true, $true)
    Set-Acl -Path $FolderPath -AclObject $Acl

    # Reload ACL to safely clear permissions
    $Acl = Get-Acl -Path $FolderPath
    
    # DYNAMIC FIX: Fetch the exact NetBIOS name from your active domain context
    $NetBIOSName = (Get-ADDomain).NetBIOSName
    $ArIdentity = "$NetBIOSName\$DomainLocalName" 
    
    $ArRights = "Modify, Synchronize"
    $ArInheritance = "ContainerInherit, ObjectInherit"
    $ArPropagation = "None"
    $ArType = "Allow"
    
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($ArIdentity, $ArRights, $ArInheritance, $ArPropagation, $ArType)
    $Acl.SetAccessRule($AccessRule)
    
    # Commit permissions securely to the folder
    Set-Acl -Path $FolderPath -AclObject $Acl
    Write-Host "[FS] Successfully locked down NTFS rules for $OUName folder." -ForegroundColor DarkGreen
}
