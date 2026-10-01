# Bug Report: Interactive Shell Closes/Detaches on Command Not Found

**Status:** Resolved / Fixed  
**Date:** 2026-09-28  
**Component:** `cmdmg` (Initialization / Sourced Script)  
**Severity:** High (Crash / Terminal Session Termination)  

---

## 1. Symptoms (อาการที่พบ)
- เมื่อติดตั้งแอปพลิเคชันลงใน `~/.zshrc` แล้ว เมื่อพิมพ์คำสั่งที่ไม่มีอยู่จริงในระบบ (Command Not Found เช่น พิมพ์คำสั่งผิด)
- Shell จะไม่พิมพ์ข้อความแจ้งเตือนข้อผิดพลาดตามปกติ
- หน้าต่าง/แท็บ Terminal จะหลุด (detached) และปิดตัวลงทันที
- **การทดสอบยืนยัน (A/B Testing):**
  - เมื่อรัน `./install.sh`: ปัญหาเกิดขึ้นทันที (Command not found ทำให้ shell exit/tab ปิด)
  - เมื่อรัน `./install.sh --undo`: ปัญหานี้หายไปทันที (Command not found แจ้ง error ตามปกติ โดย Shell ไม่ exit)
  - ยืนยันได้ 100% ว่าเกิดจากการโหลดโค้ดของโปรเจกต์นี้เข้า Shell

---

## 2. Root Cause Analysis (สาเหตุของปัญหา)

### 2.1 มีการใช้ `set -eu` ในระดับ Global ของสคริปต์
ในไฟล์ `cmdmg` บรรทัดที่ 5 มีการเปิดโหมด strict error checking:
```sh
set -eu
```

### 2.2 การติดตั้งใช้การ `source` สคริปต์เข้า Interactive Shell
เมื่อผู้ใช้รัน `./install.sh` จะมี Marker Block ถูกแทรกลงใน `~/.zshrc`:
```zsh
# >>>> cmdmg (auto-generated — run: cmdmg install) >>>>
[ -f /path/to/cmdmg ] && . /path/to/cmdmg init
# <<<< cmdmg <<<<
```
- การใช้คำสั่ง `.` (dot / source) จะทำให้โค้ดทั้งหมดใน `cmdmg` ถูกประมวลผลบน **Interactive Shell หลักของผู้ใช้โดยตรง** (ไม่ใช่ subshell แยก)
- ส่งผลให้คำสั่ง `set -eu` ถูกนำไปบังคับใช้กับ session ของ Terminal ในทุกแท็บ:
  1. **`set -e` (`errexit`)**: สั่งให้ Shell จบการทำงาน (Exit) ทันทีเมื่อมีคำสั่งใดคืนค่า exit status ไม่เท่ากับ 0 (Non-zero exit code)
  2. **`set -u` (`nounset`)**: ถือว่าการเรียกใช้ตัวแปรที่ยังไม่ได้กำหนดค่าเป็น fatal error และสั่งจบการทำงานทันที

### 2.3 เหตุการณ์เมื่อเกิด `Command Not Found`
1. เมื่อผู้ใช้พิมพ์คำสั่งที่ไม่มีอยู่จริง Zsh จะคืน exit code `127`
2. ภายใต้สภาวะปกติ Interactive Shell จะพิมพ์แจ้งว่า `zsh: command not found: ...` และแสดง prompt รอรับคำสั่งถัดไป
3. แต่เนื่องจากมี **`errexit` (`set -e`) ค้างอยู่ใน Shell หลัก** ตัว Zsh จึงสั่ง **Terminate กระบวนการตัวเองทันที**
4. เมื่อกระบวนการ Shell ตาย โปรแกรม Terminal Emulator (เช่น GNOME Terminal, Alacritty, Kitty) หรือตัวจัดการ session (tmux/screen) จะถือว่าคำสั่งจบแล้ว จึง detached และปิดแท็บทิ้งทันที

> **Note:** ปัญหานี้เป็นสาเหตุเดียวกันกับที่เคยพบข้อผิดพลาด `_NEW_LINE_BEFORE_PROMPT: parameter not set` ในฟังก์ชัน `precmd()` ก่อนหน้านี้ เนื่องจาก `nounset` (`set -u`) ถูกเปิดค้างไว้เช่นกัน

---

## 3. Impact (ผลกระทบ)
- ผู้ใช้เสีย shell session ทันทีเมื่อพิมพ์คำสั่งผิดพลาด
- คำสั่งทั่วไปที่คืนค่า non-zero เป็นปกติ (เช่น `grep` ที่ค้นหาไม่เจอ, `diff`, หรือคำสั่ง `test`) เสี่ยงที่จะทำให้ Terminal ปิดตัวกะทันหัน
- สคริปต์ plugins หรือ prompts ของ Zsh ที่มีการอ่านตัวแปรว่างอาจหยุดทำงานกะทันหัน

---

## 4. Proposed Fix (แนวทางแก้ไข)

### กฎสำคัญของการเขียน Shell Script:
> **ห้ามรัน `set -e` หรือ `set -u` ในระดับ Global บนสคริปต์ที่จะต้องถูก `source` เข้า Interactive Shell เด็ดขาด**

### วิธีแก้ไขใน `cmdmg`:
เปิดใช้งาน `set -eu` เฉพาะเมื่อทำงานเป็นคำสั่ง CLI (เช่น `add`, `rm`, `ls`, `help`) แต่ **ยกเว้นเมื่อถูกเรียกด้วยคำสั่ง `init`**:

```diff
- set -eu
+ # Only enable strict error handling for CLI commands, NEVER when sourced into interactive shell (init)
+ case "${1:-}" in
+     init) ;;
+     *) set -eu ;;
+ esac
```

---

## 5. Verification Steps (ขั้นตอนการทดสอบหลังแก้ไข)
1. เปิด terminal แท็บใหม่ (ให้ `~/.zshrc` โหลด `cmdmg init` ที่แก้ไขแล้ว)
2. ตรวจสอบว่าไม่มี `errexit` หรือ `nounset` ค้างใน shell:
   ```zsh
   setopt | grep -E "errexit|nounset"
   ```
   *(ต้องไม่แสดงผลลัพธ์ใดๆ)*
3. พิมพ์คำสั่งที่ไม่มีอยู่จริง:
   ```zsh
   non_existent_command_12345
   ```
   *(ต้องแสดง `zsh: command not found` ตามปกติ และแท็บ Terminal ต้องไม่ปิดตัวลง)*
