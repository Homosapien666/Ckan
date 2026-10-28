# PowerShell 7; execute intentionally with: .\API-CRUD-demo.ps1 -Run
# Uses only a private disposable demo dataset. The real CSV is preserved.
param([switch]$Run)
$ErrorActionPreference='Stop'
if(-not $Run){ Write-Output 'Use -Run to create, verify, update and delete a private demo dataset.'; return }
if([string]::IsNullOrWhiteSpace($env:CKAN_API_TOKEN)){throw 'Set your own CKAN_API_TOKEN environment variable before running.'}
$headers=@{Authorization=$env:CKAN_API_TOKEN}
$script:evidence=[System.Collections.Generic.List[object]]::new()
function Api([string]$action, [object]$data) {
 $body=[System.Text.Encoding]::UTF8.GetBytes(($data | ConvertTo-Json -Depth 30 -Compress))
 $r=Invoke-RestMethod -Uri ('http://localhost:8881/api/3/action/'+$action) -Method Post -Headers $headers -ContentType 'application/json; charset=utf-8' -Body $body -TimeoutSec 30
 if(-not $r.success){throw ('API failed: '+$action)}
 return $r.result
}
function New-LabMetadata([string]$name,[string]$title,[bool]$private) {
 return @{
  name=$name; title=$title; owner_org='1677ea44-fa49-43ac-a327-96fa29e6eb85'; private=$private; type='dataset';
  data_type='ข้อมูลระเบียน'; maintainer='CKAN Lab'; maintainer_email=$(if($env:CKAN_CONTACT_EMAIL){$env:CKAN_CONTACT_EMAIL}else{'student@example.com'});
  tag_string='CKAN, การศึกษา'; notes='ข้อมูลสำหรับฝึกปฏิบัติการจัดทำบัญชีข้อมูลและทดสอบ API ใน CKAN Lab';
  objective=@('อื่นๆ'); objective_other='เพื่อการศึกษาและทดสอบระบบบัญชีข้อมูล';
  update_frequency_unit='ไม่มีการปรับปรุงหลังจากการจัดเก็บข้อมูล'; geo_coverage='ไม่มี';
  data_source='จัดทำโดย CKAN Lab เพื่อประกอบการเรียน'; data_format=@('CSV');
  data_category='ข้อมูลสาธารณะ'; data_classification='เปิดเผย'; license_id='Creative Commons Attributions';
  data_language=@('ไทย'); allow_harvest='False'; high_value_dataset='False'; reference_data='False'
 }
}
if($Run){
 $stamp=Get-Date -Format 'yyyyMMddHHmmss'
 $taskUpdatedTitle='สาธิต Update ผ่าน CKAN API สำเร็จ '+$stamp
 $pkg=Api 'package_create' (New-LabMetadata ('api-crud-demo-'+$stamp) ('สาธิต Create ผ่าน CKAN API '+$stamp) $true)
 $evidence.Add(@{target='dataset'; operation='Create'; action='package_create'; success=$true; id=$pkg.id; value=$pkg.title})
 $read=Api 'package_show' @{id=$pkg.id}
 if($read.title -ne $pkg.title){throw 'Dataset Read verification failed.'}
 $evidence.Add(@{target='dataset'; operation='Read'; action='package_show'; success=$true; id=$pkg.id; value=$read.title})
 $upd=Api 'package_patch' @{id=$pkg.id; title=$taskUpdatedTitle}
 if($upd.title -ne $taskUpdatedTitle){throw 'Dataset Update verification failed.'}
 $evidence.Add(@{target='dataset'; operation='Update'; action='package_patch'; success=$true; id=$pkg.id; value=$upd.title})
 $ds=Api 'datastore_create' @{resource=@{package_id=$pkg.id; name='ข้อมูลทดสอบ DataStore CRUD'; format='CSV'}; fields=@(@{id='code';type='text'},@{id='name';type='text'},@{id='value';type='int'}); primary_key=@('code'); records=@(@{code='DEMO001';name='ข้อมูลทดลอง';value=1}); force=$true}
 $rid=$ds.resource_id
 $evidence.Add(@{target='datastore'; operation='Create'; action='datastore_create'; success=$true; resource_id=$rid; value=1})
 $r=Api 'datastore_search' @{resource_id=$rid; filters=@{code='DEMO001'}}
 if($r.total -ne 1 -or $r.records[0].value -ne 1){throw 'DataStore Read verification failed.'}
 $evidence.Add(@{target='datastore'; operation='Read'; action='datastore_search'; success=$true; total=$r.total; value=$r.records[0].value})
 $u=Api 'datastore_upsert' @{resource_id=$rid; method='update'; records=@(@{code='DEMO001';name='ข้อมูลทดลองที่แก้ไขแล้ว';value=2})}
 $r=Api 'datastore_search' @{resource_id=$rid; filters=@{code='DEMO001'}}
 if($r.records[0].value -ne 2){throw 'DataStore Update verification failed.'}
 $evidence.Add(@{target='datastore'; operation='Update'; action='datastore_upsert'; success=$true; value=$r.records[0].value})
 $d=Api 'datastore_delete' @{resource_id=$rid; filters=@{code='DEMO001'}; force=$true}
 $r=Api 'datastore_search' @{resource_id=$rid}
 if($r.total -ne 0){throw 'DataStore Delete verification failed.'}
 $evidence.Add(@{target='datastore'; operation='Delete'; action='datastore_delete'; success=$true; total_after_delete=$r.total})
 $ignored=Api 'resource_delete' @{id=$rid}
 $ignored=Api 'package_delete' @{id=$pkg.id}
 $deleted=Api 'package_show' @{id=$pkg.id}
 if($deleted.state -ne 'deleted'){throw 'Dataset Delete verification failed.'}
 $evidence.Add(@{target='dataset'; operation='Delete'; action='package_delete'; success=$true; state=$deleted.state; id=$pkg.id})
 $report=@{base_url='http://localhost:8881'; completed_at=(Get-Date -Format 'o'); test_dataset=$pkg.name; data_preserved=@{real_dataset='province-groups'; real_resource='760d60ff-558f-403b-b724-07781b491648'}; results=@($evidence)}
 $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path  'api-crud-rerun-evidence.json') -Encoding utf8
 Write-Output ('CRUD checks passed: '+$evidence.Count)
}
