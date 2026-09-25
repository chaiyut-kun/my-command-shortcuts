# ADR-003: Conflict Detection & Safety Rules

**Status:** Accepted
**Date:** 2026-09-25

## Decision Matrix

| Scenario | Behavior |
|----------|----------|
| **Alias ชื่อซ้ำ** ในหมวดเดียวกัน | แจ้ง error — ไม่อนุญาตให้เพิ่ม |
| **Alias ชื่อซ้ำ** ในหมวดอื่น | แจ้ง error — ชื่อ alias ต้อง unique ทั้งระบบ |
| **Single quote** ใน command | `cmdmg add` รับ command ผ่าน argument — shell จะจัดการ quoting เอง ผู้ใช้ใช้ `"` ครอบแทน `'` หรือใช้ `\` escape |
| **ไฟล์ใน scripts/ ไม่มี shebang** | ติดตั้งได้ แต่ควรมี shebang (`#!/bin/sh`) |
| **ไฟล์ใน scripts/ ไม่ได้ chmod +x** | ไม่ถูกเพิ่มเข้า PATH (ADR-002 กำหนดให้ตรวจสอบ) |
| **PROJECT_DIR ไม่พร้อมใช้งาน (unmount)** | `cmdmg init` แจ้ง error ชัดเจน `[cmdmg] directory not accessible: ...` |
| **marker block พัง (ย้าย path)** | ในอนาคตจะมี `cmdmg repair` ตรวจจับและแจ้งเตือน (v2) |
| **uninstall** | ลบ marker block จาก `.zshrc` + ลบทั้ง PROJECT_DIR |

## Rationale

### Duplicate Detection

Alias เป็น namespace แบน — ชื่อซ้ำทำให้ alias หลัง override alias แรกใน shell session เดียว
การแจ้ง error ทันทีป้องกันความสับสนและพฤติกรรมที่ไม่คาดคิด

### Escaping

`cmdmg add` รับ command ผ่าน positional argument ของ shell — การ quoting จะถูกจัดการโดย shell ก่อนส่งถึง `cmdmg`:

```sh
# OK — shell strips outer quotes
cmdmg add git/gs "git status"

# OK — escaped quotes
cmdmg add git/say "echo \"hello\""

# Avoid — single quote causes trouble in POSIX sh
cmdmg add git/say 'echo "hello"'
```

### PATH Safety

เฉพาะไฟล์ที่ `chmod +x` เท่านั้นที่ถูกเพิ่มใน PATH — ป้องกันไฟล์ config, README, หรือไฟล์ไม่พึงประสงค์หลุดเข้า PATH

## Consequences

- `cmdmg add` ต้อง grep หาชื่อ alias ทั่วทั้ง `aliases/*.sh` ก่อนเพิ่ม
- `cmdmg init` ต้องตรวจสอบ `PROJECT_DIR` ก่อน source — ถ้าไม่มีให้แจ้ง error
- `cmdmg init` ต้องตรวจสอบ file permission (`-x`) ก่อนเพิ่มใน PATH