using module RangeControl
$sections = @('OMJ-100-01')

$i = 0
foreach($section in $sections)
{
    Write-Host [$i] $section
    $i++
}

$section_selected = Read-Host "Pick a Section"

Write-Host "You Chose " $sections[$section_selected]
$roster = "..\rosters\{0}.txt" -f $sections[$section_selected]
$configuration_file = "..\configs\{0}.json" -f $sections[$section_selected]



$initialize_course = Read-Host "Do you want to initialize a course (y/n)"
if($initialize_course -eq 'y')
{
    initializeCourse -configuration_file $configuration_file
}

$rangecontrol = [RangeControl]::new($configuration_file,$roster)

$initialize_nets = Read-Host "Do you want to initialize student/group networks (y/n)"
if($initialize_nets -eq 'y')
{
    $rangecontrol.InitializeUserNetworks()
}

<#
server.2019.core.f22
server.2019.gui.f22.base
windows.10.ltsc.f22
centos7.2002.base.rs2
pf2.5.2.2022.base.rs2
vyos.f22
xubuntu.f22

ubuntu.server.f22
#>

$deploy_vms = Read-Host "Do you want to deploy the VMs (y/n)"
if($deploy_vms -eq 'y')
{

    # WEEKS 1 - 6 (Weeks 1 - 3)
    #$rangecontrol.DeployClones("centos7.2002.base.rs2","web01")
    #$rangecontrol.DeployClones("centos7.2002.base.rs2","log01")
    #$rangecontrol.DeployClones("vyos.f22","fw-pleaswork")
    #$rangecontrol.DeployClones("vyos.f22","fw-mgmt")
    #$rangecontrol.DeployClones("xubuntu.f22","rw01")
    #$rangecontrol.DeployClones("xubuntu.f22","mgmt01")
    #$rangecontrol.DeployClones("windows.10.ltsc.f22","wks1")
    #$rangecontrol.DeployClones("server.2019.gui.f22.base","mgmt02-v2")
    #$rangecontrol.DeployClones("ubuntu.server.f22","jump")


    ## Assessment Practice
    #$rangecontrol.DeployClones("ubuntu.server.f22","practice")
    #$rangecontrol.DeployClones("vyos.f22.v2","fw-mgmt")

    ## Asessment Week 9
    #$rangecontrol.DeployClones("ubuntu.server.f22","nginx")
    #$rangecontrol.DeployClones("ubuntu.server.f22","dhcp")
    #$rangecontrol.DeployClones("windows.10.ltsc.f22","traveler")
    #$rangecontrol.DeployClones("vyos.f22.v2","edge01")

    #CA Week 10
    #$rangecontrol.DeployClones("rocky.f22","ca")

    #WEEKS 11-12 NIDS
    #$rangecontrol.DeployClones("ubuntu.server.f22","zeek")
    #FINAL PROJECT
    # $rangecontrol.DeployClones("ubuntu.20.04.03.2022.base","ubuntu1")
    # $rangecontrol.DeployClones("ubuntu.20.04.03.2022.base","ubuntu2")
    # $rangecontrol.DeployClones("centos7.2022.base","centos1")
    # $rangecontrol.DeployClones("vyos.1.4.2022.base.v2","vyos1")
    # $rangecontrol.DeployClones("pf2.5.2.2022.base","pf1")
    # $rangecontrol.DeployClones("win10.ltsc.2022.base","wks1")
    # $rangecontrol.DeployClones("win10.ltsc.2022.base","wks2")
    # $rangecontrol.DeployClones("server.2019.gui.2022.base","srv1")
    # $rangecontrol.DeployClones("xubuntu.21.10.2022.base","xubuntu1")
}

$adhoc = Read-Host "Do you to run adhoc tasks (y/n)"
if($adhoc -eq 'y')
{

    #tweakVMPerformance -Name log01-SEC350-0*-* -gb 4 -cpu 2
    #tweakVMPerformance -Name mgmt02-SEC350-0*-* -gb 4 -cpu 2
    #Week 11
    #SetSwitchPromiscuous -name "SEC350-0*MGMT*" -on $true
    #SetSwitchPromiscuous -name "SEC350-0*DMZ*" -on $true
    #tweakVMPerformance -Name zeek-SEC350-0* -gb 2 -cpu 2

    #final project extra vms
    #$rangecontrol.DeployClones("server.2019.core.2022.base","srvcore1")
    #$rangecontrol.DeployClones("ubuntu.20.04.03.2022.base","ubuntu3")
    #$rangecontrol.DeployClones("ubuntu.20.04.03.2022.base","zeek")
    #$rangecontrol.DeployClones("centos7.2022.base","centos2")
    #$rangecontrol.DeployClones("win10.ltsc.2022.base","wks1.new")
    #$rangecontrol.DeployClones("win10.ltsc.2022.base","wks2.new")
    #$rangecontrol.DeployClones("xubuntu.21.10.2022.base","xubuntu1.new")
    #$rangecontrol.DeployClones("ubuntu.20.04.03.2022.base","ubuntu3")
    #$rangecontrol.DeployClones("ubuntu.server.2022","ubuntu-big")

    #$rangecontrol.DeployClones("vyos.1.4.2022.base.v2","vyos2")
    #$rangecontrol.DeployClones("ubuntu.20.04.03.2022.base","ubuntu3")


    #$rangecontrol.DeployClones("pf2.5.2.2022.base","pf2")
    #$rangecontrol.DeployClones("win10.ltsc.2022.base","wks3")
    #$rangecontrol.DeployClones("win10.ltsc.2022.base","wks4")
    #$rangecontrol.DeployClones("server.2019.gui.2022.base","srv2")
   # $rangecontrol.DeployClones("xubuntu.21.10.2022.base","xubuntu-another-jump")
    


}

$instructors=@('devin.paden')
$spares = Read-Host "Do you want to create spare vms for the instructor? (y/n)"
if($spares -eq 'y')
{
    $i = 0
    foreach($instructor in $instructors)
    {
        Write-Host [$i] $instructor
        $i++
    }

    $instructor_selected = Read-Host "Pick an instructor"
    for($num=1; $num -le 3;$num++)
    {

       #$rangecontrol.DeployClone("win10.ltsc.base.f21","wks-$num-$section_selected",$instructors[$instructor_selected])
       #$rangecontrol.DeployClone("vyos.1.4.base.f21","vyos-$num-$section_selected",$instructors[$instructor_selected])
       #$rangecontrol.DeployClone("centos7.2009.base.f21","centos-$num-$section_selected",$instructors[$instructor_selected])
       #$rangecontrol.DeployClone("xubuntu.20.04.2.base.f21","xubuntu-$num-$section_selected",$instructors[$instructor_selected])
       #$rangecontrol.DeployClone("server2019.gui.f21","srv19-gui-$num-$section_selected",$instructors[$instructor_selected])
        
    }
    

}


