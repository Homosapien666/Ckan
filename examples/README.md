# การสาธิต CKAN Data APIs

ผลที่ทำแล้วอยู่ใน api-crud-evidence.json: ผ่าน 8 รายการ ครอบคลุมชุดข้อมูลและแถว DataStore ทั้ง Create, Read, Update, Delete สคริปต์ API-CRUD-demo.ps1 เป็นตัวอย่างสำหรับรันสาธิตซ้ำ ไม่ต้องรันเพื่อให้งานที่ทำแล้วสมบูรณ์

## อ่านข้อมูลจริงโดยไม่ใช้ token

เปิดลิงก์นี้ได้ในเบราว์เซอร์:

- http://localhost:8881/api/3/action/status_show
- http://localhost:8881/api/3/action/package_show?id=province-groups
- http://localhost:8881/api/3/action/datastore_search?resource_id=760d60ff-558f-403b-b724-07781b491648&limit=5

## สาธิตซ้ำ (มีการสร้าง แก้ไข และลบข้อมูลทดสอบ)

ใช้ PowerShell 7 และ token ที่ผู้ใช้เตรียมเองสำหรับเว็บไซต์ local นี้ โดย token ต้องมีสิทธิ์จัดการชุดข้อมูลในองค์กร CKAN Lab และ DataStore ชุดส่งมอบนี้ไม่มี token จริง

```powershell
$env:CKAN_API_TOKEN = 'ใส่ token ของคุณเอง'
.\API-CRUD-demo.ps1 -Run
Remove-Item Env:\CKAN_API_TOKEN
```

สคริปต์เรียก HTTP POST ไปที่ http://localhost:8881/api/3/action/ โดยใช้ Authorization header และ JSON body สร้างชื่อชุดข้อมูลส่วนตัวตามเวลา จึงแยกจาก province-groups ที่ใช้จริง จากนั้นสร้างแถว DEMO001 ค่า 1 อ่านยืนยัน แก้เป็น 2 อ่านยืนยัน แล้วลบและตรวจว่าเหลือ 0 แถว ก่อน soft-delete ชุดข้อมูลทดสอบ ผลรอบใหม่อยู่ใน api-crud-rerun-evidence.json

หากการสาธิตขัดข้องกลางทาง อาจเหลือชุดข้อมูลส่วนตัวชื่อ api-crud-demo-<เวลา> ให้ตรวจชื่อนั้นก่อนลบ ห้ามใช้คำสั่งลบกับชุดข้อมูล province-groups หรือไฟล์ต้นฉบับ

## ลำดับที่ใช้อธิบายอาจารย์

1. package_create สร้างชุดข้อมูลส่วนตัว → package_show อ่านชื่อชุดข้อมูล
2. package_patch แก้ชื่อ → package_show ยืนยันชื่อใหม่
3. datastore_create สร้างตารางและแถวค่า 1 → datastore_search ยืนยัน
4. datastore_upsert แก้ค่าเป็น 2 → datastore_search ยืนยัน
5. datastore_delete ลบแถว → datastore_search คืน total=0
6. resource_delete และ package_delete ลบวัตถุทดสอบ → package_show คืน state=deleted

การลบในข้อ 6 เป็น soft-delete ของ CKAN ไม่มีการ purge และ CSV หลัก 76 แถวไม่ถูกลบ
