<#
.SYNOPSIS
    Script to meassure performance of storage
.DESCRIPTION
    Script to meassure performance of storage
.EXAMPLE
    Test disk performance using the pressure mode
    Tests with 4K, 8K, 64K and 512K blocks, both with 100% read and 100% write, increasing the Outstanding IOs by 1 starting on 2, saving the result in the samefolder as the script, named the testname
    .\Invoke-TSxDiskSpd.ps1 -Capacity 10 -Path D:\testdisk -OutIOStart 2 -OutIOInc 1 -Testmode Pressure -TestName PutteIIDDiskPRESS
.EXAMPLE
    Test disk performance using the simulation mode
    Tests with 4K, 8K, 64K and 512K blocks, in 10,60,70,90 % Write , saving the result in the samefolder as the script, named the testname
     .\Invoke-TSxDiskSpd.ps1 -Capacity 10 -Path D:\testdisk -OutIOStart 2 -Testmode Simulation -TestName PutteIIDDiskSIM
.EXAMPLE
    Test disk performance using the pressure mode
    Tests with 4K, 8K, 64K and 512K blocks, both with 100% read and 100% write, saving the result in the samefolder as the script, named the testname
    .\Invoke-TSxDiskSpd.ps1 -Capacity 10 -Path D:\testdisk -OutIOStart 2 -Testmode Benchmark -TestName PutteIIDDiskBENCH
.NOTES
        ScriptName: Invoke-TSxDiskSpd.ps1
        Author:     Mikael Nystrom
        Twitter:    @mikael_nystrom
        Email:      mikael.nystrom@truesec.se
        Web:        https://www.TrueSec.com

    Version History
    1.0.0 - Script created [01/10/2019 00:54:52]

Copyright (c) 2019 TrueSec

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

The script was created based on the following blogpost
https://blogs.technet.microsoft.com/josebda/2015/07/03/drive-performance-report-generator-powershell-script-using-diskspd-by-arnaud-torres/
#>

#Requires -RunAsAdministrator

Param(
    $Capacity,
    $Path,
    $OutIOStart,
    $OutIOInc,
    $Testmode,
    $TestName

)

#Check for diskspd.exe
$Location = $MyInvocation.MyCommand | Split-Path
if((Test-Path -Path $Location\diskspd.exe) -ne $true){
    Write-Host "Could not find diskspd.exe, it needs to be in the same folder as the script"
    Write-Host "You can download diskspd.exe from https://aka.ms/diskspd"
    Write-Error -Message "Unable to continue, will break here."
    break
}

#Set Var's
$TestPath = "$Path\testfile.dat"
$OutputFileName = $TestName + ".txt"

#Make sure we have the folder
New-Item -Path $Path -ItemType Directory -Force -ErrorAction Stop

# Reset test counter
$counter = 0

# Use 1 thread / core
$Thread = "-t"+(Get-WmiObject win32_processor).NumberofCores

# Set time in seconds for each run
# 10-120s is fine
$Time = "-d10"

# Outstanding IOs
# Should be 2 times the number of disks in the RAID
# Between  8 and 16 is generally fine
$OutstandingIO = "-o$OutIOStart"

$Cleaning = test-path -Path $TestPath
if ($Cleaning -eq "True")
{"Removing current testfile.dat from drive"
  remove-item $TestPath
}

$CapacityParameter = "-c"+$Capacity+"G"

"Initialization can take some time, we are generating a $Capacity GB file..."
"  "
# Initialize outpout file

# Add the headers to the output file
“Test,Drive,Operation,Access,Blocks,Run,IOPS,MB sec,Latency ms,OutStandingIO,CPU %," > ./$OutputFileName

# Number of tests
# Multiply the number of loops to change this value
# By default there are : (4 blocks sizes) X (2 for read 100% and write 100%) X (2 for Sequential and Random) X (4 Runs of each)

write-host "TEST RESULTS (also logged in .\$OutputFileName)" -foregroundcolor yellow

if($testmode -eq "Benchmark"){
        $NumberOfTests = 64
        "  "

        # Begin Tests loops
        # We will run the tests with 4K, 8K, 64K and 512K blocks
        (4,8,64,512) | ForEach-Object {  

        $BlockParameter = ("-b"+$_+"K")
        $Blocks = ("Blocks "+$_+"K")


    # We will do Read tests and Write tests
      (0,100) | ForEach-Object {
          if ($_ -eq 0){$IO = "Read"}
          if ($_ -eq 100){$IO = "Write"}
          $WriteParameter = "-w"+$_
    # We will do random and sequential IO tests
      ("r","si") | ForEach-Object {
          if ($_ -eq "r"){$type = "Random"}
          if ($_ -eq "si"){$type = "Sequential"}
          $AccessParameter = "-"+$_
            # Each run will be done 4 times
            (1..4) | ForEach-Object {

            # The test itself (finally !!)
            $result = & $Location\diskspd.exe $CapacityPArameter $Time $AccessParameter $WriteParameter $Thread $OutstandingIO $BlockParameter -h -L $TestPath

            # Now we will break the very verbose output of DiskSpd in a single line with the most important values
            foreach ($line in $result) {
                if ($line -like "total:*") {
                    $total=$line; break
                }
            }
            foreach ($line in $result) {
                if ($line -like "avg.*") {
                    $avg=$line; break
                }
            }
            $mbps = $total.Split("|")[2].Trim() 
            $iops = $total.Split("|")[3].Trim()
            $latency = $total.Split("|")[4].Trim()
            $cpu = $avg.Split("|")[1].Trim()
            $counter = $counter + 1

            # A progress bar, for the fun
            Write-Progress -Activity ".\diskspd.exe $CapacityPArameter $Time $AccessParameter $WriteParameter $Thread $OutstandingIO $BlockParameter -h -L $TestPath" -status "Test in progress" -percentComplete ($counter / $NumberofTests * 100)

            # Remove comment to check command line ".\diskspd.exe $CapacityPArameter $Time $AccessParameter $WriteParameter $Thread -$OutstandingIO $BlockParameter -h -L $TestPath"

            # We output the values to the text file
            “Test $Counter,$Path,$IO,$type,$Blocks,Run $_,$iops,$mbps,$latency,$OutstandingIO,$cpu"  >> ./$OutputFileName

            # We output a verbose format on screen
            “Test $Counter, $Path, $IO, $type, $Blocks, Run $_, $iops iops, $mbps MB/sec, $latency ms, OutstIO $OutstandingIO, $cpu CPU"
            }
        }
    }
}
}

if($testmode -eq "Simulation"){

    $NumberOfTests = 64
    "  "

    # Begin Tests loops
    # We will run the tests with 8K and 512K blocks
    (8,64) | ForEach-Object {  

    $BlockParameter = ("-b"+$_+"K")
    $Blocks = ("Blocks "+$_+"K")

    # We will do Read tests and Write tests
    (10,60,70,90) | ForEach-Object {
    if ($_ -eq 10){$IO = "10/90"}
    if ($_ -eq 60){$IO = "60/40"}
    if ($_ -eq 70){$IO = "70/30"}
    if ($_ -eq 90){$IO = "90/10"}
    $WriteParameter = "-w"+$_

        # We will do random and sequential IO tests
        ("r","si") | ForEach-Object {
        if ($_ -eq "r"){$type = "Random"}
        if ($_ -eq "si"){$type = "Sequential"}
        $AccessParameter = "-"+$_

            # Each run will be done 4 times
            (1..4) | ForEach-Object {

                # The test itself (finally !!)
                $result = & $Location\diskspd.exe $CapacityPArameter $Time $AccessParameter $WriteParameter $Thread $OutstandingIO $BlockParameter -h -L $TestPath

                # Now we will break the very verbose output of DiskSpd in a single line with the most important values
                foreach ($line in $result) {
                    if ($line -like "total:*") {
                        $total=$line; break
                    }
                }
                foreach ($line in $result) {
                    if ($line -like "avg.*") {
                        $avg=$line; break
                    }
                }
                $mbps = $total.Split("|")[2].Trim() 
                $iops = $total.Split("|")[3].Trim()
                $latency = $total.Split("|")[4].Trim()
                $cpu = $avg.Split("|")[1].Trim()
                $counter = $counter + 1

                # A progress bar, for the fun
                Write-Progress -Activity ".\diskspd.exe $CapacityPArameter $Time $AccessParameter $WriteParameter $Thread $OutstandingIO $BlockParameter -h -L $TestPath" -status "Test in progress" -percentComplete ($counter / $NumberofTests * 100)

                # Remove comment to check command line ".\diskspd.exe $CapacityPArameter $Time $AccessParameter $WriteParameter $Thread -$OutstandingIO $BlockParameter -h -L $TestPath"

                # We output the values to the text file
                “Test $Counter,$Path,$IO,$type,$Blocks,Run $_,$iops,$mbps,$latency,$OutstandingIO,$cpu"  >> ./$OutputFileName

                # We output a verbose format on screen
                “Test $Counter, $Path, $IO, $type, $Blocks, Run $_, $iops iops, $mbps MB/sec, $latency ms, OutstIO $OutstandingIO, $cpu CPU"
                }
            }
        }
    }
}

if($testmode -eq "Pressure"){
        $NumberOfTests = 64
        "  "

        # Begin Tests loops
        # We will run the tests with 4K, 8K, 64K and 512K blocks
        (4,8,64,512) | ForEach-Object {  

        $BlockParameter = ("-b"+$_+"K")
        $Blocks = ("Blocks "+$_+"K")


    # We will do Read tests and Write tests
      (0,100) | ForEach-Object {
          if ($_ -eq 0){$IO = "Read"}
          if ($_ -eq 100){$IO = "Write"}
          $WriteParameter = "-w"+$_
    # We will do random and sequential IO tests
      ("r","si") | ForEach-Object {
          if ($_ -eq "r"){$type = "Random"}
          if ($_ -eq "si"){$type = "Sequential"}
          $AccessParameter = "-"+$_
            
            $OutstandingIOtmp = $OutIOStart
            # Each run will be done 4 times
            (1..4) | ForEach-Object {

            # The test itself (finally !!)
            $result = & $Location\diskspd.exe $CapacityPArameter $Time $AccessParameter $WriteParameter $Thread "-o$OutstandingIOtmp" $BlockParameter -h -L $TestPath

            # Now we will break the very verbose output of DiskSpd in a single line with the most important values
            foreach ($line in $result) {
                if ($line -like "total:*") {
                    $total=$line; break
                }
            }
            foreach ($line in $result) {
                if ($line -like "avg.*") {
                    $avg=$line; break
                }
            }
            $mbps = $total.Split("|")[2].Trim() 
            $iops = $total.Split("|")[3].Trim()
            $latency = $total.Split("|")[4].Trim()
            $cpu = $avg.Split("|")[1].Trim()
            $counter = $counter + 1

            # A progress bar, for the fun
            Write-Progress -Activity ".\diskspd.exe $CapacityPArameter $Time $AccessParameter $WriteParameter $Thread -o$($OutstandingIOtmp) $BlockParameter -h -L $TestPath" -status "Test in progress" -percentComplete ($counter / $NumberofTests * 100)

            # Remove comment to check command line ".\diskspd.exe $CapacityPArameter $Time $AccessParameter $WriteParameter $Thread -$OutstandingIO $BlockParameter -h -L $TestPath"

            # We output the values to the text file
            “Test $Counter,$Path,$IO,$type,$Blocks,Run $_,$iops,$mbps,$latency,$OutstandingIOtmp,$cpu"  >> ./$OutputFileName

            # We output a verbose format on screen
            “Test $Counter, $Path, $IO, $type, $Blocks, Run $_, $iops iops, $mbps MB/sec, $latency ms, OutstIO $OutstandingIOtmp, $cpu CPU"
            
            $OutstandingIOtmp = $OutstandingIOtmp + $OutIOInc
            }
        }
    }
}
}