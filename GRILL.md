# cmdshort — Grill Questions

## Round 1: Architecture & Scope

**Q1:** ไฟล์ `.zshrc` มี marker block `# >>>> cmdshort` — ถ้าผู้ใช้มี plugin manager (oh-my-zsh, zinit, antigen) อยู่แล้ว หรือ `.zshrc` ถูกจัดการโดย dotfiles manager (chezmoi, yadm, stow) — `install.sh` ควรทำยังไง? แค่เติมบรรทัดต่อท้าย, แทรกที่ตำแหน่งเฉพาะ, หรือให้ผู้ใช้เลือก?
: เติมบรรทัดต่อท้าย

**Q2:** ตอน `uninstall` — ลบเฉพาะ marker block ใน `.zshrc` หรือลบทั้งโปรเจกต์ directory ด้วย?
: ลบทั้งโปรเจกต์ directory

**Q3:** ถ้ามี alias ชื่อซ้ำกับที่มีอยู่แล้วในระบบ (เช่น `alias g='git'` ซ้ำกับ oh-my-zsh git plugin) — tool ควรเตือน, error, หรือ override เงียบๆ?
: แจ้ง error

## Round 2: Data & State

**Q4:** ไฟล์ `aliases/category.sh` — ควรมี header comment อธิบายหมวดหมู่ไหม? (เช่น `# Category: git — Git shortcuts`) หรือปล่อย raw อย่างเดียว?
: ทีแรกที่เราคุยกันฉันเข้าใจว่าจะแยกเป็นไฟล์ตาม tools ไปเลย แต่หากเป็นลักษณะวิธีนี้จริงๆ ควรมี header comment

**Q5:** `cmdshort ls` — แสดงแค่ชื่อ alias หรือแสดง command ด้วย? แสดงผลแบบไหน: table, list, หรือ tree แยกหมวด?
: แสดง alias และ command เป็นรูปแบบ table

**Q6:** scripts directory — ทุกไฟล์ใน `scripts/` ถูกเติมเข้า PATH อัตโนมัติเลย หรือต้อง `chmod +x` ถึงจะถูกเพิ่ม? แล้วถ้ามีไฟล์ที่ไม่ใช่ shell script หลุดเข้ามาล่ะ?
: ต้องถูก chmod +x ก่อน

**Q7:** `cmdshort backup` — backup ไปที่ไหน? archive เป็น tarball? เก็บ metadata อะไรบ้าง?
- เก็บไว้ในแพลนว่าจะมีในอนาคตแต่ตอนนี้ยังไม่ต้องสรา้งออกมาเป็นระบบ

## Round 3: Edge Cases & Safety

**Q8:** ถ้าผู้ใช้ย้ายโปรเจกต์ไป path อื่น — marker block ใน `.zshrc` จะพัง (เพราะ path เดิมตาย) — มีกลไก `cmdshort repair` หรือ auto-detect ไหม?
- tool ต้องสามารถบอกได้ว่า .zhsrc พังไปแล้วจาก path เดิมตาย แต่ว่าบันทึกเป็นระบบในอนาคตไปก่อน

**Q9:** ถ้า `/data/` เป็น external drive และไม่ได้ mount ตอน login — Zsh จะ error หรือแค่ skip หายไปเงียบๆ?
- แจ้งบอก error

**Q10:** alias มี `'` (single quote) ใน command — เช่น `alias say='echo "it'"'"'s working"'` — tool จัดการ escaping ยังไงตอน `cmdshort add`?
- ระบบควรมีการจัดการ escaping อาจจะใช้วธีครอบด้วย "" แทน หรือใช้ \ แทน

Grill Round 4: Technology Stack
เครื่องมือสำหรับสร้าง cmdmg มี 4 ตัวเลือก:
ตัวเลือก	Dependency	ความซับซ้อน
A: Shell Script	ไม่มี	ต่ำ
B: Python	Python 3	กลาง
C: Go	Go compiler	กลาง-สูง
D: Rust	Rust compiler	สูง
Q11: cmdmg เป็น shell tool — ใช้ Shell Script สร้างเลยดีไหม? ข้อดีคือ:
- ไม่มี dependency — ใช้ได้ทันทีบน Debian ทุกเครื่อง
- "กินอาหารตัวเอง" — tool จัดการ alias สร้างด้วย shell script
- ผู้ใช้เปิดอ่าน/แก้เองได้เลย
ข้อเสียคือ data structure จำกัด (no hashmap, no JSON parsing) — แต่สำหรับงานนี้ (อ่าน/เขียนไฟล์ alias, เติม/ลบบรรทัดใน .zshrc) Shell Script ก็พอแล้ว
: Shell script

Q12: ถ้าใช้ Shell Script — ใช้ POSIX sh (พกพา 100%) หรือ Zsh (ใข้ feature Zsh เฉพาะเช่่น associative array)?
: POSIX sh
Q13: Structured data — ปจจุบันไม่มี config ไฟล์ ถ้าในอณาตตอยาากได้ config (เช่น cmdmg.toml หรือ .cmdmg.json) — เปลี่ยนไปใช้ Python เลย หรือ shell + jq / python -c?
: เก็บไว้เป็น plan ในอนาคต

Q14: Testing — shell script เทสอย่่งไง? ใช้ bats หรือเทียบผลลัพธ์เอง?
: ใช้ bats

Q15: ShellCheck — จะ integrate shellcheck ตอนไหน? hook ใน in stall.sh หรือใช้ใน CI?
: ตอน CI
