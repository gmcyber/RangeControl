using module RangeControl
$configuration_file = "../configs/ETHHACK.json"
$roster = "../rosters/ETHHACK.txt"

$initialize_course = Read-Host "Do you want to initialize a course (y/n)"
if($initialize_course -eq 'y')
{
    initializeCourse -configuration_file $configuration_file
}

$rangecontrol = [RangeControl]::new($configuration_file,$roster)

# Note, Students do not need personal networks in this class.  Kali lands on the COURSE-WAN and picks up a DHCP address
<#
These are the Base VMs
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
    #STUDENTS
    $rangecontrol.DeployClones("kali.2022.4.base","kali01")
    $rangecontrol.DeployClones("windows10.ltsc.base","wks01")
}

