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

$deploy_vms = Read-Host "Do you want to deploy the VMs (y/n)"
if($deploy_vms -eq 'y')
{
    #STUDENTS
    $rangecontrol.DeployClones("kali.2022.4.f22","kali01")
    $rangecontrol.DeployClones("windows.10.ltsc.f22.v2","win10-02")
}

