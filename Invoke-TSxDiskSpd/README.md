# Invoke-TSxDiskSpd
The script act as a wrapper for diskspd.exe, and 3 diffrent preset of testmode
## Download DiskSpd.exe fro
```sh
https://aka.ms/diskspd"
```
#### EXAMPLE 1
Test disk performance using the pressure mode
Tests (size 10GB) with 4K, 8K, 64K and 512K blocks, both with 100% read and 100% write, increasing the Outstanding IOs by 1 starting on 2, saving the result in the samefolder as the script, named the testname
```sh
.\Invoke-TSxDiskSpd.ps1 -Capacity 10 -Path D:\testdisk -OutIOStart 2 -OutIOInc 1 -Testmode Pressure -TestName PutteIIDDiskPRESS
```
#### EXAMPLE 2
Test disk performance using the simulation mode
Tests (size 10GB) with 4K, 8K, 64K and 512K blocks, in 10,60,70,90 % Write , saving the result in the same folder as the script, named the testname
```sh
.\Invoke-TSxDiskSpd.ps1 -Capacity 10 -Path D:\testdisk -OutIOStart 2 -Testmode Simulation -TestName PutteIIDDiskSIM
```
#### EXAMPLE 2
Test disk performance using the pressure mode
Tests (size 10GB) with 4K, 8K, 64K and 512K blocks, both with 100% read and 100% write, saving the result in the samefolder as the script, named the testname
```sh
.\Invoke-TSxDiskSpd.ps1 -Capacity 10 -Path D:\testdisk -OutIOStart 2 -Testmode Benchmark -TestName PutteIIDDiskBENCH
```