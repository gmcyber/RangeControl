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
kali.2022.4.base
pf.2.6.0.base
rocky.9.1.base
server.2019.base.v2
vyos.1.4.base
windows10.ltsc.base
xubuntu.20.04.base.v2
ubuntu.22.04.1.base


#>

$deploy_vms = Read-Host "Do you want to deploy the VMs (y/n)"
if($deploy_vms -eq 'y')
{

    # WEEKS 1 - 6
    #$rangecontrol.DeployClones("rocky.9.1.base","web01")
    #$rangecontrol.DeployClones("pf.2.6.0.base","fw1")
    #$rangecontrol.DeployClones("vyos.f22","fw-mgmt")
    #$rangecontrol.DeployClones("server.2019.base.v2","dc1")
    #$rangecontrol.DeployClones("windows10.ltsc.base","wsk1")


}