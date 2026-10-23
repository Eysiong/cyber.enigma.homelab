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

## 🏁 Phase 4: PowerShell Active Directory Automation
*(Coming Soon - In Progress!)*

---

## 🧠 Solved Infrastructure Roadblocks
* **Hardware Freezes:** Resolved multi-threading decompressor loop issues during installation by throttling the VM to 1 vCPU temporarily, then safely restoring it to 2 vCPUs post-install.
* **Registry Override:** Bypassed unexpected loop setup reboots via a `regedit` ChildCompletion flag override.
* **Hypervisor Layer:** Resolved underlying AMD-V/SVM sub-layer virtualization errors inside the host physical BIOS.
