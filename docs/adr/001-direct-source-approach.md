# ADR-001: Direct Source Approach

**Status:** Accepted
**Date:** 2026-09-25

## Context

ต้องการจัดเก็บ alias และ scripts ไว้นอก home directory (`/data/Documents/my-command-shortcuts/`) โดยมี footprint ใน home directory ให้น้อยที่สุด

มี 3 วิธีที่เป็นไปได้:
1. **Source ตรง** — เติม marker block ใน `.zshrc` ให้ source ไฟล์ alias จาก path ภายนอก
2. **ZDOTDIR** — เปลี่ยน directory ที่ Zsh อ่าน config ไปไว้ข้างนอก โดยเหลือแค่ `.zshenv` ใน home
3. **Symlink** — สร้าง symlink ใน home ชี้ไปยัง path จริง

## Decision

เลือก **วิธี Source ตรง** — เติม marker block ต่อท้าย `.zshrc`

## Rationale

- เข้าใจง่าย ไม่เปลี่ยนพฤติกรรม Zsh พื้นฐาน
- home directory เหลือ footprint แค่ 2 บรรทัด (marker block เริ่มต้น + ปิด)
- ไม่เสี่ยงตอน login ถ้า `/data/` ไม่พร้อมใช้งาน — แค่ skip + แจ้ง error
- ผู้ใช้ยังคง `.zshrc` เดิมไว้ได้ ไม่ต้อง migrate config
- ถ้า `.zshrc` ไม่มี marker block — Zsh ทำงานปกติเหมือนเดิม

## Consequences

- `install.sh` ต้องจัดการเติม/ลบ marker block ใน `.zshrc` อย่างปลอดภัย
- `cmdmg init` ถูก source จาก marker block เพื่อ setup environment
- marker block ใช้ `# >>>> cmdmg` / `# <<<< cmdmg` เป็นตัวคั่น

## Marker Block Format

```zsh
# >>>> cmdmg (auto-generated — run: cmdmg install) >>>>
[ -f /data/Documents/my-command-shortcuts/cmdmg ] && . /data/Documents/my-command-shortcuts/cmdmg init
# <<<< cmdmg <<<<
```