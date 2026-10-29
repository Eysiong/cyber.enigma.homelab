# ==============================================================================
# Script Name: Sync-ADUserOnboarding.ps1
# Description: Automates enterprise identity provisioning into Active Directory
#              adhering to corporate naming standards and AGDLP compliance.
# Forest: cyber.enigma.ph
# ==============================================================================

# 1. Define Variables and Paths
$CsvPath = "C:\new_employees.csv"
$Domain = "cyber.enigma.ph"
$BaseOUPath = "OU=Employees,DC=cyber,DC=enigma,DC=ph"

# 2. Check if the CSV data source exists
if (-not (Test-Path $CsvPath)) {
    Write-Error "Data source file missing at $CsvPath. Please create it first!"
    exit
}

# 3. Import the employee list
$Employees = Import-Csv -Path $CsvPath

foreach ($User in $Employees) {
    # Generate clean, standard enterprise variables
    $SamAccountName = ($User.FirstName.Substring(0,1) + "." + $User.LastName).ToLower()
    $UserPrincipalName = "$SamAccountName@$Domain"
    $FullName = "$($User.FirstName) $($User.LastName)"
    $OUName = $User.Department
    $TargetOUPath = "OU=$OUName,$BaseOUPath"
    
    # 4. Check if the Department OU exists; if not, create it
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$OUName'" -SearchBase $BaseOUPath -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $OUName -Path $BaseOUPath
        Write-Host "Created new Department OU: $OUName" -ForegroundColor Cyan
        Start-Sleep -Seconds 1
    }
    
    # 5. AGDLP AUTOMATION: Check if Department Global Group exists; if not, create it
    $GlobalGroupName = "G_$( $OUName.Replace(' ', '') )_Employees"
    $GroupExists = Get-ADGroup -Filter "SamAccountName -eq '$GlobalGroupName'" -ErrorAction SilentlyContinue
    
    if (-not $GroupExists) {
        $GroupParams = @{
            Name          = $GlobalGroupName
            GroupScope    = "Global"
            GroupCategory = "Security"
            Path          = $TargetOUPath
            Description   = "Global Group for all $OUName department personnel."
        }
        New-ADGroup @GroupParams
        Write-Host "Created Missing Global Group: $GlobalGroupName inside $OUName OU" -ForegroundColor Cyan
    }
    
    # 6. SAFETY CHECK: Skip user creation if username OR Full Name already exists
    $UserExists = Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'" -ErrorAction SilentlyContinue
    $NameExists = Get-ADUser -Filter "Name -eq '$FullName'" -ErrorAction SilentlyContinue
    
    if ($UserExists -or $NameExists) {
        Write-Host "User '$FullName' ($SamAccountName) already exists in AD. Checking group membership..." -ForegroundColor Yellow
        
        # If user exists but somehow got left out of the group, add them safely
        $IsMember = Get-ADGroupMember -Identity $GlobalGroupName | Where-Object { $_.SamAccountName -eq $SamAccountName }
        if (-not $IsMember) {
            Add-ADGroupMember -Identity $GlobalGroupName -Members $SamAccountName
            Write-Host "Added existing user $SamAccountName to group $GlobalGroupName." -ForegroundColor Green
        }
        continue
    }
    
    # 7. Generate Password
    $PlainPassword = "CALOncr2025!"  
    $SecurePassword = ConvertTo-SecureString $PlainPassword -AsPlainText -Force
    
    # 8. Collect parameters cleanly using a Splatting Hashtable
    $UserParams = @{
        Name                  = $FullName
        SamAccountName        = $SamAccountName
        UserPrincipalName     = $UserPrincipalName
        GivenName             = $User.FirstName
        Surname               = $User.LastName
        Title                 = $User.Title
        Department            = $User.Department
        Path                  = $TargetOUPath
        AccountPassword       = $SecurePassword
        ChangePasswordAtLogon = $true
        Enabled               = $true
    }
    
    # 9. Provision the user smoothly
    New-ADUser @UserParams
    Write-Host "Successfully provisioned employee: $UserPrincipalName inside $OUName OU" -ForegroundColor Green
    
    # 10. Automatically assign the user to their department's Global Security Group
    Add-ADGroupMember -Identity $GlobalGroupName -Members $SamAccountName
    Write-Host "Assigned $SamAccountName to security group: $GlobalGroupName" -ForegroundColor DarkGreen
}
