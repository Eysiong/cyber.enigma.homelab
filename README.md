# 🌐 Cyber Enigma Enterprise Homelab
An enterprise-grade Windows Server 2022 and Windows 10 active directory homelab built completely inside an isolated virtualized environment.

---

## 🏗️ Phase 1: Core Architecture & Topology
* **Host Platform:** VirtualBox (Windows 11 Client Host)
* **Network Topology:** 100% isolated VirtualBox Internal Network named `CorpNetwork`.
* **Domain Name:** `cyber.enigma.ph`

### 🖥️ Asset Inventory

| Device Name | Operating System | IP Address | Subnet Mask | Role / Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **DC01** | Windows Server 2022 Standard | `192.168.10.10` | `255.255.255.0` | Domain Controller, AD DS, DNS, DHCP |
| **Client01** | Windows 10 Professional | Dynamic (DHCP) | `255.255.255.0` | Corporate Workstation |

---

## 🛠️ Phase 2: Domain Controller Configuration (DC01)
* **Active Directory Forest:** Successfully promoted to the root DC for `cyber.enigma.ph`.
* **Organizational Structure:** Created the `Employees` Organizational Unit (OU).
* **Identity Management:** Provisioned standard employee account `jdoe` (John Doe).
* **Group Policy (GPO):** Enforced `Restrict - Control Panel Access` linked directly to the `Employees` OU.

---

## 📡 Phase 3: Core Network Services (DHCP Deployment)
To transition away from rigid static IP management, **DC01** was configured with the DHCP Server Role.
* **Scope Name:** `CorpNetwork-Pool`
* **Address Range Pool:** `192.168.10.50` to `192.168.10.254` (Leaves `.1` through `.49` free for static network infrastructure).
* **Active Options:** 
  * Option `003` (Router/Gateway): `192.168.10.1`
  * Option `006` (DNS Server): `192.168.10.10`

### 🧪 Verification & Testing
Switching **Client01**'s network adapter to automatic (DHCP) successfully yields an active lease directly from **DC01**:
* **Command Executed:** `ipconfig /renew` followed by `ipconfig /all`
* **Result:** Client successfully pulled an IP address within the authorized `.50+` pool and properly configured `192.168.10.10` as its primary DNS authority.

---

## 📜 Phase 4: PowerShell Active Directory Automation
To simulate an enterprise onboarding workflow, user provisioning was completely automated via a native PowerShell script.

* **Data Source:** Managed via an external flat file database (`C:\new_employees.csv`) detailing employee names, departments, and dynamic corporate titles.
* **Logic Framework:** Built a conditional `foreach` loop that scans the CSV data array to parse variables programmatically using robust `.Substring(0,1)` string management to output uniform corporate-standard user logon names (`firstinitial.lastname`).
* **Directory Structural Controls:** The script automatically evaluates directory paths, dynamically creates corresponding departmental sub-OUs (**Executive, Finance, HR, IT**) inside the parent `Employees` container if missing, and gracefully skips pre-existing records via integrated validation checkpoints to avoid pipeline conflicts.
* **Security Controls Applied:** Generated uniform UPN strings (`username@cyber.enigma.ph`), injected complex default temporary credentials, explicitly enabled the accounts natively, and checked the administrative force-flag requiring users to explicitly update their credentials at initial workstation logon.

---

## 🛡️ Phase 5: Advanced Group Policy Objects (GPOs)
To transition away from flat global policies, the domain structure was augmented with highly targeted departmental security controls:
* **GPO Applied:** `Restrict - Command Prompt Access`
* **Targeting Vector:** Linked directly to the **HR, Finance, and Executive** sub-OUs while explicitly omitting the **IT** OU.
* **Result Matrix:** Non-technical employees are securely blocked from accessing the command line terminal environment to enforce internal security boundaries. IT personnel maintain uninterrupted workspace controls.

---

## 📂 Phase 6: Secured Enterprise File Services
Configured the local domain controller as a central file storage engine to govern file access control across the enterprise fabric.

* **Central Workspace Engine:** Built a unified storage root at `C:\CompanyShares` housing independent subdirectories tailored to individual corporate departments.
* **Access Control Mechanisms:** Configured permissive Advanced Share parameters alongside highly restricted NTFS discretionary access control lists (DACLs). Inherited permissions were stripped from child folders, granting explicit `Modify` access tokens only to corresponding operational identities.
* **Automated Drive Routing:** Created a Group Policy preference object (`Map - Company Share Network Drives`) linked to the parent `Employees` tree. The policy updates user configurations on the fly to natively map the secure network directory directly to the client's file system as a persistent `S:` drive letter.
* **Cross-Validation Testing:** Logged onto a domain workstation as an HR operator (`j.andaya`). The `S:` drive automatically mapped at login. The operator successfully conducted daily data management inside the `HR` directory, but was explicitly denied access by the Windows file subsystem when attempting to breach the `Finance` or `IT` document vaults.

---

## 🧠 Solved Infrastructure Roadblocks
* **Hardware Freezes:** Resolved multi-threading decompressor loop issues during installation by throttling the VM to 1 vCPU temporarily, then safely restoring it to 2 vCPUs post-install.
* **Registry Override:** Bypassed unexpected loop setup reboots via a `regedit` ChildCompletion flag override.
* **Hypervisor Layer:** Resolved underlying AMD-V/SVM sub-layer virtualization errors inside the host physical BIOS.
