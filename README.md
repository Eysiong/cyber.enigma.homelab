# 🌐 Cyber Enigma Enterprise Homelab
An enterprise-grade Windows Server 2022 and Windows 10 Active Directory homelab built completely inside an isolated, sandboxed virtual environment. 

This repository documents the end-to-end design, secure identity architecture, resource governance, and disaster recovery baselines implemented within the lab fabric.

---

## 🏗️ Phase 1: Core Architecture & Network Topology
*   **Host Platform:** VirtualBox (Windows 11 Client Host Platform)
*   **Network Topology:** 100% isolated VirtualBox Internal Network named `CorpNetwork`.
*   **Active Directory Domain Services (AD DS) Forest:** `cyber.enigma.ph`

### 🖥️ Asset Inventory Matrix

| Device Name | Operating System | IP Address | Subnet Mask | Role / Infrastructure Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **DC01** | Windows Server 2022 Standard | 192.168.10.10 | 255.255.255.0 | Domain Controller, AD DS, DNS, DHCP, FSRM, Backup Primary |
| **Client01** | Windows 10 Professional | Dynamic (DHCP) | 255.255.255.0 | Managed Corporate Workstation Asset |

---

## 📡 Phase 2: Core Infrastructure Network Services
To transition away from rigid static IP configurations, **DC01** was authorized as the primary DHCP lease distributor for the domain segment.

*   **Authorized Scope Name:** `CorpNetwork-Pool`
*   **Lease Pool Allocation:** `192.168.10.50` to `192.168.10.254` *(Reserves `.1` through `.49` for static infrastructure assets).*
*   **Broadcast Options Distributed:**
    *   **Option 003 (Router/Gateway):** `192.168.10.1`
    *   **Option 006 (DNS Server Authority):** `192.168.10.10`

### 🧪 DHCP Verification Testing
Switching the network adapter profile of **Client01** to automatic dynamic retrieval yielded immediate results:
*   **Verification Command:** `ipconfig /renew` followed by `ipconfig /all`
*   **Result Matrix:** The client workstation successfully leased an IP within the authorized `.50+` pool and natively configured `192.168.10.10` as its explicit, primary DNS resolver.

---

## 📜 Phase 3: Identity Lifecycle Management & Group Automation
To scale administration efficiently, user provisioning and security tracking boundaries were transitioned from flat accounts to a programmatic framework adhering strictly to the **AGDLP best-practice standard** (*Accounts ➡️ Global Groups ➡️ Domain Local Groups ➡️ Permissions*).

### 🚀 1. Automated Onboarding Engine (Script 1)
An advanced PowerShell automation script handles the **Identity Layer** by parsing raw employee rosters from an external flat-file database (`C:\new_employees.csv`).
*   **Roster Template File:** [new_employees.csv](./new_employees.csv)

*   **Source Code Inventory:** [scripts/Sync-ADUserOnboarding.ps1](./scripts/Sync-ADUserOnboarding.ps1)
*   **Execution Profile:** Run this script first to establish directory entries.

```powershell
# Core logic framework snippet
foreach (User in Employees) {
    SamAccountName = (User.FirstName.Substring(0,1) + "." + \(User.LastName).ToLower()\)GlobalGroupName = "G_( OUName.Replace(' ', '') )_Employees"
    New-ADUser @UserParams
    Add-ADGroupMember -Identity GlobalGroupName -Members SamAccountName
}
```

### 📁 2. Automated Resource Scaffolding Engine (Script 2)
A secondary standalone automation script handles the **Resource Layer** on the local file system by scanning Active Directory container states.

*   **Source Code Inventory:** [scripts/Initialize-FolderSecurity.ps1](./scripts/Initialize-FolderSecurity.ps1)
*   **Execution Profile:** Run this script immediately following the user onboarding pass.

```powershell
# Core logic framework snippet
foreach (\$Dept in \(Departments) {\)DomainLocalName = "DL_CompanyShares_( OUName.Replace(' ', '') )_Modify"
    Add-ADGroupMember -Identity \$DomainLocalName -Members \(GlobalGroupName\)NetBIOSName = (Get-ADDomain).NetBIOSName
    ArIdentity = "NetBIOSName\$DomainLocalName"
    Set-Acl -Path FolderPath -AclObject Acl
}
```

---

## 🛡️ Phase 4: Enterprise Group Policy Objects (GPOs)
Rather than maintaining generalized domain configurations, granular role-based workspace controls were deployed across the Organizational Unit architecture:

*   **Policy Name:** `Restrict - Command Prompt Access`
    *   **Targeting Vector:** Linked directly to the `HR`, `Finance`, `Developer`, and `Executive` sub-OUs while explicitly omitting the `IT` OU.
    *   **Result:** Non-technical operators are natively blocked from launching `cmd.exe` or executing scripts, hardening the local endpoint attack surface, while IT staff maintain unobstructed console controls.
*   **Policy Name:** `Map - Company Share Network Drives`
    *   **Targeting Vector:** Linked to the root `Employees` tree to update user network spaces on the fly.
    *   **Result:** Automatically maps the network share path `\\DC01\CompanyShares` directly to the client's file system as a persistent `S:` drive letter at initial logon.

---

## 📁 Phase 5: Storage Architecture & Governance (FSRM Deployment)
To prevent network users from hoarding hard drive space or introducing dangerous unapproved files into corporate shares, the **File Server Resource Manager (FSRM)** role was added to **DC01**.

*   **Automated Storage Quotas:** Configured a custom **2 GB Hard Quota** applied dynamically to target storage directories. The system enforces strict blocks when breached and writes high-priority warnings to the Application Event Log once directory paths cross an 85% capacity threshold.
*   **Active File Screening:** Implemented an aggressive, active **Executable File Screen** across `C:\CompanyShares`. The real-time kernel filter driver inspects files on the fly and blocks users from saving or executing unapproved file strings (`*.exe`, `*.msi`, `*.bat`).

---

## 🛡️ Phase 6: System Resilience & Disaster Recovery Baseline
To guarantee domain survivability and baseline service continuity against configuration failures or systemic data corruption, manual backup and health mechanisms were configured:

*   **System State Backup Schedule:** Utilizing **Windows Server Backup**, a dedicated, raw, unallocated **50 GB secondary VirtualBox hard disk (`Disk 1`)** was mounted and formatted as a permanent storage repository. A daily automated schedule executes at **11:00 PM** to pull bare-metal System State images (including the Active Directory `ntds.dit` database, SYSVOL shares, registry configs, and boot sector structures).
*   **Performance Monitoring Telemetry Alerts:** Created a user-defined Data Collector Set within **Performance Monitor** targeting the local CPU core parameters (`% Processor Time`). The engine is actively armed to instantly log a high-priority warning entry into the Windows System logs whenever processor utilization spikes above 90%.

---

## 💻 Phase 7: Advanced Virtualization & Hyper-V Core
To satisfy the virtualization requirements of the curriculum within a Type-2 hypervisor constraints environment, **Nested Virtualization** was forced down to the processor layer:

*   **Hypervisor Interface Unlock:** VirtualBox configuration states were modified via the physical host command line interface (`VBoxManage modifyvm "DC01" --nested-hw-virt on`) to cleanly pass down underlying physical AMD-V/VT-x virtualization extensions.
*   **Kernel Package Injection:** Because typical graphical wizards block deployment inside virtualized environments, the native hypervisor engine was injected into the server image using the Deployment Image Servicing and Management framework:
    ```powershell
    DISM /Online /Enable-Feature /FeatureName:Microsoft-Hyper-V /All /NoRestart
    ```
*   **Boot Sector Initialization:** The active boot profile configuration was updated using `bcdedit /set "{current}" hypervisorlaunchtype auto` to force the hypervisor layer to wake up on system start, creating a fully functioning, native **Hyper-V Manager** control console inside **DC01**.

---

## 🧠 Solved Infrastructure Roadblocks & Patches
1.  **Hardware Freezes:** Resolved deployment engine multi-threading constraints by throttling the primary server VM down to 1 vCPU during setup loops, returning it to 2 vCPUs post-installation.
2.  **NTFS String Translation Faults:** Resolved localized Active Directory folder permissions failures during automated ACL execution by updating scripts to pull the target NetBIOS context dynamically via `(Get-ADDomain).NetBIOSName` instead of hardcoding raw text values.
3.  **VirtualBox Storage Detection Failures:** Resolved Windows Server Backup validation errors by initializing the second virtual drive under `diskmgmt.msc` using the GPT partition standard while intentionally leaving it as *Unallocated* raw storage for the application to claim.
