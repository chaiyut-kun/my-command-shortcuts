# cmdmg — Domain Glossary

| Term | Definition |
|------|------------|
| **Shortcut** | ชื่อรวมของ alias และ script ที่ cmdmg จัดการ |
| **Alias** | Zsh alias — คำสั่งสั้นที่ map ไปหาคำสั่งยาว (`alias gs='git status'`) เก็บใน `aliases/*.sh` |
| **Category** | หมวดหมู่ของ shortcut — 1 ไฟล์ต่อ 1 หมวด (git, docker, system, project) |
| **Header Comment** | บรรทัดแรกของไฟล์ alias รูปแบบ `# Category: <name> — <description>` ใช้ระบุหมวดหมู่ |
| **Script** | ไฟล์ executable ใน `scripts/` ที่ถูกเพิ่มใน PATH |
| **Marker Block** | บล็อก `# >>>> cmdmg` ... `# <<<< cmdmg` ใน `.zshrc` ใช้เป็นจุดเชื่อมต่อ |
| **`cmdmg`** | CLI tool หลัก — จัดการ alias, script, install, uninstall |
| **`cmdmg init`** | ฟังก์ชันภายใน — ถูก source จาก marker block จัดการ source alias ทั้งหมด + export PATH |
| **`install.sh`** | สคริปต์ตั้งค่าครั้งแรก — เติม/ลบ marker block ใน `.zshrc` |
| **PROJECT_DIR** | Root directory ของโปรเจกต์ที่มี `cmdmg`, `aliases/`, `scripts/` |
| **Duplicate Detection** | กลไกตรวจสอบชื่อ alias ซ้ำทั่วทั้งระบบ — แจ้ง error ทันที