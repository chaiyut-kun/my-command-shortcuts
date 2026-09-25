# ADR-002: File-per-Category as Source of Truth

**Status:** Accepted
**Date:** 2026-09-25

## Context

ต้องการรูปแบบการจัดเก็บ alias ที่:
- แก้ไขง่ายด้วย editor ใดๆ
- Git-friendly — เห็น diff ชัดเจน
- แยกหมวดหมู่ชัดเจน (git, docker, system, project)
- CLI tool (`cmdmg`) เป็นแค่ helper — ไม่มี database แยก

## Decision

Alias จัดเก็บเป็นไฟล์ `.sh` ธรรมดา แยกตามหมวดหมู่ (เครื่องมือ) — 1 หมวด = 1 ไฟล์

```
aliases/
├── git.sh        # Category: git — Git shortcuts
├── docker.sh     # Category: docker — Docker commands
├── system.sh     # Category: system — System administration
└── project.sh    # Category: project — Project-specific tasks
```

## File Format

```sh
# Category: git — Git shortcuts
alias g='git'
alias gs='git status'
alias gc='git commit -m'
alias gp='git push'
```

ทุกไฟล์ต้องมี header comment บรรทัดแรกในรูปแบบ `# Category: <name> — <description>`

## Rationale

- Plain text — เปิดด้วย editor ไหนก็ได้ (vim, nano, vscode)
- Git diff เห็นการเปลี่ยนแปลงทีละบรรทัด
- เพิ่มด้วยมือหรือผ่าน `cmdmg add` ได้ผลลัพธ์เหมือนกัน
- ไม่ต้องพึ่ง database, JSON, YAML, หรือ format พิเศษใดๆ
- source ตรงด้วย `.` (dot) ได้ทันที

## Consequences

- `cmdmg` ต้อง parse header comment เพื่อดึงชื่อหมวดหมู่
- `cmdmg add` ต้องสร้างไฟล์ใหม่ + header อัตโนมัติถ้าหมวดนั้นยังไม่มี
- `cmdmg rm` ต้องลบบรรทัด alias ออกจากไฟล์ — ถ้าไฟล์ว่างให้ลบไฟล์
- `cmdmg init` ต้อง source ทุกไฟล์ `aliases/*.sh` เวลา shell เริ่มต้น