# cmdmg — Technical Architecture

## Overview

cmdmg เป็น CLI tool สำหรับจัดการ Zsh alias และ scripts แยกออกจาก home directory
ใช้ POSIX sh ทั้งหมด — ไม่มี dependency ภายนอก

## Layers

```
~/.zshrc
  └─ source >>>> cmdmg init
       ├─ validate PROJECT_DIR
       ├─ source aliases/*.sh
       └─ export PATH += scripts/
            │
            ├── aliases/git.sh
            ├── aliases/docker.sh
            ├── aliases/system.sh
            └── aliases/project.sh
```

## Components

### 1. Marker Block (ใน `.zshrc`)

```zsh
# >>>> cmdmg (auto-generated — run: cmdmg install) >>>>
[ -f /data/Documents/my-command-shortcuts/cmdmg ] && . /data/Documents/my-command-shortcuts/cmdmg init
# <<<< cmdmg <<<<
```

- `[ -f ... ]` ป้องกัน error ถ้าไฟล์ไม่มี (unmounted / ลบโปรเจกต์)
- `&&` — ถ้าไฟล์มีจริง ถึงจะ source
- `cmdmg init` เป็นฟังก์ชันภายใน ไม่ใช่ subcommand

### 2. `cmdmg` — CLI Tool (POSIX sh)

Entry point: รับ subcommand เป็น argument แรก

```
cmdmg [command] [args...]
```

| Layer | หน้าที่ |
|-------|--------|
| `cmd_main()` | Dispatch subcommand → เรียกฟังก์ชันที่ตรงกัน |
| `cmd_init()` | source aliases + export PATH (ถูกเรียกจาก marker block) |
| `cmd_install()` | เติม marker block ใน `.zshrc` |
| `cmd_uninstall()` | ลบ marker block + ลบ PROJECT_DIR |
| `cmd_add()` | เพิ่ม alias ลงไฟล์หมวดหมู่ |
| `cmd_rm()` | ลบ alias จากไฟล์หมวดหมู่ |
| `cmd_ls()` | แสดง table: NAME, CATEGORY, COMMAND |
| `cmd_reload()` | source `aliases/*.sh` ใหม่ |
| `cmd_path()` | แสดง PROJECT_DIR |
| `cmd_version()` | แสดงเวอร์ชัน |

### 3. `install.sh` — Setup Script

```
./install.sh        # ติดตั้ง — เติม marker block
./install.sh --undo # ถอนการติดตั้ง — ลบ marker block
```

**Safety checks:**
- ตรวจสอบว่า PROJECT_DIR มี `cmdmg` และ `aliases/`
- ตรวจสอบ marker block ว่ามีอยู่แล้วหรือไม่
- ไม่แตะส่วนอื่นของ `.zshrc`

### 4. Data Layer — `aliases/*.sh`

Plain text ธรรมดา — 1 alias ต่อบรรทัด

```sh
# Category: git — Git shortcuts
alias g='git'
alias gs='git status'
```

### 5. Scripts Layer — `scripts/`

Executable shell scripts — เฉพาะไฟล์ที่มี `chmod +x` เท่านั้นที่ถูกเพิ่มใน PATH

```sh
#!/bin/sh
echo "hello"
```

## Flow

```
User: cmdmg add git/gs "git status"
  → cmdmg: parse cat=git, name=gs
  → cmdmg: grep ทั้ง aliases/*.sh หาชื่อซ้ำ
  → cmdmg: ถ้าไม่มี → เติม "alias gs='git status'" ใน aliases/git.sh
  → cmdmg: ถ้าไฟล์ยังไม่มี → สร้างใหม่ + header comment

User: cmdmg ls
  → cmdmg: อ่านทุกไฟล์ใน aliases/
  → cmdmg: parse header comment เอา category name
  → cmdmg: แสดง table: NAME | CATEGORY | COMMAND

User: เปิด terminal ใหม่
  → .zshrc source marker block
  → marker block source cmdmg init
  → cmdmg init: validate PROJECT_DIR
  → cmdmg init: for f in aliases/*.sh; do . "$f"; done
  → cmdmg init: for f in scripts/*; do [ -x "$f" ] && PATH=...
  → aliases พร้อมใช้งาน
```