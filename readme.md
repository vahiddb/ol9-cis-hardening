# Oracle Linux 9 CIS Hardening Framework (vahiddb)

A comprehensive, modular, and interactive Bash-based framework to Audit and Remediate Oracle Linux 9 servers according to the CIS (Center for Internet Security) Benchmarks.

## 🚀 Features
- **Modular Design:** 29 distinct Audit and Remediation modules (from filesystem configurations to user rights).
- **Interactive Menu:** A centralized orchestrator script (`vahiddb_ol9_cis_hardening_v1.0.sh`) for easy execution.
- **Selective Execution:** Run all modules at once or select specific modules by number.
- **Safe & Standard:** Developed using standard Bash practices, avoiding destructive defaults.

## 📁 Repository Structure
- `vahiddb_ol9_cis_hardening_v1.0.sh`: The main wrapper/menu script.
- `modules/`: Contains all `audit_*.sh` and `remediate_*.sh` scripts.
- `README.md`: Project documentation.

## ⚙️ How to Use

1. Clone the repository:
```bash
   git clone https://github.com/yourusername/vahiddb-ol9-cis-hardening.git
   cd vahiddb-ol9-cis-hardening
   
2. Make the scripts executable:
   chmod +x vahiddb_ol9_cis_hardening_v1.0.sh
   chmod +x modules/*.sh
   
3. Run the framework as root:
   sudo ./vahiddb_ol9_cis_hardening_v1.0.sh
   
4.Follow the interactive menu to Audit or Remediate your system.
⚠️ WARNING: Remediation scripts alter system configurations. Always run them in a test environment first and ensure you have proper backups or snapshots before executing them in production.

📞 Author & Contact
This project is maintained by Vahid Nowrouzi. Let’s connect!

🌐 Website: vahiddb.com
✈️ Telegram: @vahiddb_dba
💼 LinkedIn: Vahid Nowrouzi
📧 Email: vahidnowrouzi@gmail.com
📄 License
This project is licensed under the MIT License. Feel free to use, modify, and distribute.