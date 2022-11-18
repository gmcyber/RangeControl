Function yesno([string]$prompt)
{
    $retVal = $false
    $yesNo = Read-Host -Prompt "$prompt Y/N"
    if($yesNo.ToUpper() -eq "Y")
    {
        $retVal = $true 
    }
    return $retVal
}
function connect_vcenter()
{
    param(
        [string] $vcenter_server
    )
    #are we connected?
    if ($null -ne $global:DefaultVIServer){
        Write-Host "Connected as:" $global:DefaultVIServer.User
    }else{
      Connect-VIServer -Server $vcenter_server   
    }
}
function SearchVMs([string] $Name, [string] $folder)
{
    if($folder)
    {
        return Get-VM -Name $Name -Location $folder
    }
    else
    {
        return Get-VM -Name $Name
    }
}
function tweakVMPerformance([string] $Name, [string] $folder, [int] $gb, [int] $cpu)
{
    $vms = SearchVMs -Name $Name -folder $folder
    foreach($vm in $vms)
    {
        if($gb)
        {
            $res=set-vm -VM $vm -MemoryGB $gb -Confirm:$false
        }
        if($cpu)
        {
            $res=set-vm -VM $vm -NumCpu $cpu -Confirm:$false
        }

    }

}
function GetExistingOrCreateFolder([string] $FolderName, $ParentFolder = $null, [string] $folderType)
{
    $folder = $null
    $bCreated=$false
    try 
    {
        if($null -eq $ParentFolder)
        {
            $folder = Get-Folder -Name $FolderName  -ErrorAction Stop
        }
        else
        {
            $folder = Get-Folder -Name $FolderName -Location $ParentFolder  -ErrorAction Stop
        }        

    }
    # if the folder doesn't exist an exception is thrown
    catch 
    {
        if($null -eq $ParentFolder)
        {
            #$rootFolder=(Get-View (Get-View -viewtype datacenter).vmfolder)
            $rootFolder = Get-Folder -Name $folderType
            $folder =  New-Folder -Name $FolderName -Location $rootFolder
        }
        else 
        #ok, assumption is that we have a parent folder this time
        #if parent is invalid, let default exception deal with it
        {
            $folder = New-Folder -Name $FolderName  -Location $ParentFolder
        }
        $bCreated = $true
    }
    if($bCreated)
    {
        Write-Host $folder.Name, " Created" -ForeGroundColor Green 
    }
    else 
    {
        Write-Host $folder.Name, " Found" -ForeGroundColor Green 
    }
    $folder
}
function createNetwork($destination_folder, [string] $name, [string] $esxi_host)
{
    #ok, this is somewhat involved as virtual port groups are not easily moved
    # the switch name length is restricted but the vpg is not.  There may
    # someday be an issue with duplicate vswitchnames for truncated vswitch names
    # if so, hash the long network name and use that for the vswitch name
    $vswitchname = $name
    if ($vswitchname.length -gt 31)
    {
        $vswitchName = $vswitchname.substring(0,31)
    }
    #Create the vSwitch
    #TODO, trap duplicate errors.
    $vs = $null
    try 
    {
        #GMCYBER DEBUG
        #$vs = New-VirtualSwitch -VMHost $esxi_host -Name $vswitchname -ErrorAction Ignore
        $vs = New-VirtualSwitch -VMHost $esxi_host -Name $vswitchname
    }
    catch 
    {
        $vs = Get-VirtualSwitch -VMHost $this.vmhost -Name $vswitchname
        Write-Host "Ran into an issue with creating a virtual switch: $($PSItem.ToString())"
    }
    try 
    {
        $vpg=New-VirtualPortGroup -VirtualSwitch $vs -Name $name
        Write-Host "Creating Port group:", $name  -ForeGroundColor Green     
    }
    catch 
    {
        Write-Host "Port group:", $name, "exists" -ForeGroundColor Yellow
        #GMCYBER DEBUGGGING
        Write-Host "Ran into an issue creating a port group: $($PSItem.ToString())"
        
    }
    Start-Sleep -Second 1
    #grab the folder destination by view
    $dest = get-view -Id $destination_folder.Id
    #grab the newly created Network Object by view
    $src = Get-View -ViewType Network -Filter @{"Name" = $Name}
    #move via move task on destination
    #this code is error prone and a work around due to -Location not being supported on Switches
    try {
        $task = $dest.MoveIntoFolder_Task($src.MoRef)
    }
    catch 
    {
        Write-Host "Error moving ", $name, " to: ", $destination_folder.Name, ", do so manually" -ForegroundColor Red
    }
    
}
function addPermissionToFolder($folder, [string] $principalName, [string] $domain, [string] $role)
{
    #figure out if the $principalName is a cyber user or group
    $acct = $Null
    if(isUser -Name $principalName -domain $domain)
    {
        $acct=Get-VIAccount -Domain $domain -User $principalName

    }
    elseif(isGroup -Name $principalName -domain $domain )
    {
        $acct=Get-VIAccount -Domain $domain -Group $principalName
    }
    else 
    {
        $message = "{0} is neither a user or a group" -f $principalName
        throw $message    
    }
    $perm = New-VIPermission -Role $role -Principal $acct.Name -Entity $folder -Propagate:$true
    $message = "{0} given {1} access to {2}" -f $acct.Name, $role, $folder.Name
    Write-Host $message -ForegroundColor Green
}
function isGroup([string] $Name,[string] $domain)
{
    <#
        .Description
        isGroup returns true if the accounts object class is a group
    #>
    $retVal = $false
    $acct=Get-VIAccount -Domain $domain -Group $Name -ErrorAction SilentlyContinue
    $retVal = ($null -ne $acct)
    $retVal

}
function isUser([string] $Name, [string] $domain)
{
    <#
        .Description
        isUser returns true if the accounts object class is a user
    #>

    $retVal = $false
    $acct=Get-VIAccount -Domain $domain -User $Name -ErrorAction SilentlyContinue
    $retVal = ($null -ne $acct)
    $retVal
}
function initializeCourse([string] $configuration_file)
{
    $conf = (Get-Content -Raw -Path $configuration_file | ConvertFrom-Json)
    $NETWORKS_BASE_FOLDER = "{0}-NETWORKS" -f $conf.course_name
    $NETWORK_TYPE = "network"
    $VM_TYPE = "vm"

    connect_vcenter($conf.vcenter_server)
    #BUILD COURSE VM HIERARCHY IF IT IS NOT THERE
    $courses_base_folder = GetExistingOrCreateFolder -FolderName $conf.courses_folder -folderType $VM_TYPE
    $semester_base_folder = GetExistingOrCreateFolder -FolderName $conf.semester -ParentFolder $courses_base_folder -folderType $VM_TYPE
    $section_base_folder = GetExistingOrCreateFolder -FolderName $conf.course_name -ParentFolder $semester_base_folder -folderType $VM_TYPE
    $course_vms_folder = GetExistingOrCreateFolder -FolderName $conf.course_vms_folder -ParentFolder $section_base_folder -folderType $VM_TYPE
    $group_vms_folder = GetExistingOrCreateFolder -FolderName $conf.group_vms_folder -ParentFolder $section_base_folder -folderType $VM_TYPE
    $student_vms_folder = GetExistingOrCreateFolder -FolderName $conf.student_vms_folder -ParentFolder $section_base_folder -folderType $VM_TYPE

    #GRANT PRIVILEGES
    #Instructors should have cncs-instructor privileges at the $SECTION_FOLDER level
    foreach($instructor in $conf.instructors)
    { 
        addPermissionToFolder -folder $student_vms_folder -principalName $instructor -domain $conf.domain -role $conf.instructor_role
    }

    #BUILD NETWORK HIERARCHY IF IS NOT THERE 
    $section_network_folder = GetExistingOrCreateFolder -FolderName $NETWORKS_BASE_FOLDER -folderType $NETWORK_TYPE

    $course_networks_folder = GetExistingOrCreateFolder -FolderName $conf.course_networks_folder -ParentFolder $section_network_folder -folderType $NETWORK_TYPE
    $group_networks_folder = GetExistingOrCreateFolder -FolderName $conf.group_networks_folder -ParentFolder $section_network_folder -folderType $NETWORK_TYPE
    $student_networks_folder = GetExistingOrCreateFolder -FolderName $conf.student_networks_folder -ParentFolder $section_network_folder -folderType $NETWORK_TYPE

    #SET PERMISSIONS ON THE COURSE NETWORKS FOLDER to the vsphere-users AD group and cncs-student role
    addPermissionToFolder -folder $course_networks_folder -principalName $conf.ad_vsphere_group -domain $conf.domain -role $conf.student_role

    #CREATE the COURSE LEVEL NETWORKS SUCH AS COURSE-WAN
    createNetwork -destination_folder $course_networks_folder -name $conf.default_network -esxi_host $conf.esxi_host
}
function SetMaxSnapShots($vm, $count)
{
    Write-Host "Giving ", $vm.name , $count, "snapshots"
    New-AdvancedSetting -Name snapshot.maxSnapshots -Value $count -Entity $vm -Confirm:$false -Force
}

function CopyFileToVM([string] $vmName, [string] $source, [string] $destination, [string] $guestuser, [string] $guestpassword)
{
    #wrapper around Copy-VMGuestFile
    $vms = SearchVMs -Name $vmName
    foreach($vm in $vms)
    {
        Copy-VMGuestFile -VM $vm -Source $source -Destination $destination -GuestUser $guestuser -GuestPassword $guestpassword -LocalToGuest -Force
    }
}

function destroy_course([string] $section, [string] $vcenter_server)
#Note this is an exceptionally dangerous function and should only be run over break
{
    #Connect
    connect_vcenter($vcenter_server)
    #STEP 0. Validate with caller the location and names and count of VMs to be deleted.
    $vmfolder = Get-Folder -Type VM -Name $section
    $networkfoldername = "{0}-NETWORKS" -f $section
    $networkfolder = Get-Folder -Type Network -Name $networkfoldername
    
    #Ok, critical to see if we have a folder now.  If you don't do this, all VMs will be returned
    # and potentially deleted.
    if ($null -ne $vmfolder)
    {
        $vms = Get-VM -Location $vmfolder
        Write-Host "List of VMs to be deleted:"
        foreach($vm in $vms)
        {
            Write-Host $vm.name
        }
        $confirmation = Read-Host "Danger:  Are you sure you want to proceed with VM Deletion? (y/n)?"
        if ($confirmation -eq 'y')
        {    
            foreach($vm in $vms){
                if($vm.PowerState -eq "PoweredOn")
                {
                    Write-Host "Powering Down:" $vm.name
                    Stop-VM -VM $vm -Confirm:$False
                }
                Write-Host "Deleting VM: " $vm.Name
                Remove-VM -VM  $vm -DeletePermanently -Confirm: $False

            }
        }
    } 
    else 
    {
        Write-Host "Error Condition, The Virtual Machine Folder was not found"
    }

    $switchname = $section + "*"
    $switches = Get-VirtualSwitch -Name $switchname
    foreach($switch in $switches)
    {
        Write-Host $switch.name
    }
    $confirmation = Read-Host "Danger:  Are you sure you want to delete these switches? (y/n)?"
    if ($confirmation -eq 'y')
    {    
        foreach($switch in $switches){
            Write-Host "Deleting" $switch.name
            Remove-VirtualSwitch -VirtualSwitch $switch -Confirm:$false
        }
    }
    $confirmation = Read-Host "Danger:  Are you sure you want to proceed with Folder Deletion? (y/n)?"
    if ($confirmation -eq 'y')
    {
        Write-Host "Deleting Course Folders"
        $networkfolder | Remove-Folder -Confirm: $False
        $vmfolder | Remove-Folder -Confirm: $False
    }

}
function SetSwitchPromiscuous([string] $name, [Boolean] $on)
{
    $switches = Get-VirtualSwitch -Name $name
    foreach($switch in $switches){
        Write-Host $switch.name
        $switch | Get-SecurityPolicy | Set-SecurityPolicy -AllowPromiscuous $on
    }
}

function SearchSwitches([string] $name)
{
    $switches = Get-VirtualSwitch -Name $name
    foreach($switch in $switches){
        Write-Host $switch.name
    }
}

Function linkedClone([string] $snapshot_name, [string] $vm_host, [string]$sourceVM, [string]$destVM, [string]$datastore, [string]$destNetwork=$null)
{
    $base_vm = Get-VM -Name $sourceVM
    if($base_vm)
    {
        try 
        {          
            $newvm = New-VM -LinkedClone -Name $destVM -VM $base_vm -ReferenceSnapshot $snapshot_name -VMHost $vm_host -Datastore $datastore -Notes "Linked Clone Parent: $base_vm" -ErrorAction Stop
            if($destNetwork)
            {
              Set-Network -vmName $newvm -networkName $destNetwork -Force $true
            }
        }
        catch 
        {
            Write-Host -ForegroundColor "Red" "Failure creating $destVM $Error[0]"            
        }
    }
    else
    {
        Write-Host -ForegroundColor "Red" "$sourceVM is invalid"
    }
}
function Set-Network([string] $vmName, [string] $networkName, [boolean] $Force=$false, $index = $null)
{
    $networks = Get-VirtualNetwork -Name $networkName
    if($networks.Length -ne 1)
    {
        Write-Host -ForegroundColor Red "Refine Query so there is 1 Network"
    }
    $vms = searchvms -Name $vmName
    foreach($vm in $vms)
    {
        #if index is populated then just grab that interface, if not grab them all
        $interfaces=$Null
        if($index)

        {
            $interfaces = ($vm | Get-NetworkAdapter)[$index]
        }else
        {
            $interfaces = $vm | Get-NetworkAdapter
        }
        
        foreach($interface in $interfaces)
        {
            
            if(-Not $Force)
            {
                if( yesno -prompt "Do you wish to set $interface on $vm to $networkName")
                {
                    Write-Host "Setting Interface $interface on $vm.Name to: $networkName" -ForegroundColor "Green"
                    $result = $interface | Set-NetworkAdapter -NetworkName $networkName -Confirm:$false
                }
            }
            else 
            {
                $result = $interface | Set-NetworkAdapter -NetworkName $networkName -Confirm:$false                   
            }

        }

    }
}
