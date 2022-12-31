# 11/7/2022 Renamed from OpenRange to RangeControl
Import-Module RangeControlUtils
class RangeControl
{
  $conf
  $users
    RangeControl ([string] $configuration_file, [string]$roster_path)
    {
        
        #read in the configuration
        $this.conf = (Get-Content -Raw -Path $configuration_file | ConvertFrom-Json)
        #make sure we are connected to vcenter
        connect_vcenter($this.conf.vcenter_server)

        #read in the roster, skipping commented out lines
        $this.users = Get-Content $roster_path | Select-String -Pattern "^#" -NotMatch
    }
    InitializeUserNetworks()
    {
        $course_networks_folder_name = "{0}-NETWORKS" -f $this.conf.course_name 
        $cnf = Get-Folder $course_networks_folder_name
        $folder = $null
        #for each user in the roster
          #determine group or user
        foreach($user in $this.users)
        {
            if(isUser -domain $this.conf.domain -Name $user)
            {
                $folder = Get-Folder -Name $this.conf.student_networks_folder -Location $cnf
            }
            elseif(isGroup -domain $this.conf.domain -Name $user)
            {
                $folder = Get-Folder -Name $this.conf.group_networks_folder -Location $cnf
            }
            else 
            {
                $msg = "{0} is not a valid user or group" -f $user
                throw $msg
            }
            #create the folders
            $userFolder = GetExistingOrCreateFolder -FolderName $user -ParentFolder $folder -folderType "network"
            addPermissionToFolder -folder $userFolder -principalName $user -domain $this.conf.domain -role $this.conf.student_role
            #create the networks
            foreach($network in $this.conf.networks)
            {
                $netname = "{0}-{1}-{2}" -f $this.conf.course_name, $network, $user
                createNetwork -destination_folder $userFolder -name $netname -esxi_host $this.conf.esxi_host

            }
        }
    }
    [System.Object[]]DeployClone([string] $source, [string] $destination, [string] $user)
    {
        $folder = $null
        $course_folder = Get-Folder -Name $this.conf.course_name
        $newvm = $null
        if(isUser -domain $this.conf.domain -Name $user)
        {
            $folder = Get-Folder -Name $this.conf.student_vms_folder -Location $course_folder
        }
        elseif(isGroup -domain $this.conf.domain -Name $user)
        {
            $folder = Get-Folder -Name $this.conf.student_vms_folder -Location $course_folder
        }
        else 
        {
            throw "error condition, user is not a user or group"
        }
        $userFolder = GetExistingOrCreateFolder -FolderName $user -ParentFolder $folder -folderType "vm"
        #TODO, when we give a professor spares, the instructor permissions get overwritten with the student role.
        addPermissionToFolder -folder $userFolder -principalName $user -domain $this.conf.domain -role $this.conf.student_role

        #get the source virtual machine
        $source_vm = Get-VM -Name $source -Location $this.conf.baseline_folder
        $snapshot = Get-Snapshot -VM $source_vm -Name "Base"

        $checkvm = Get-VM -name $destination -Location $userFolder -ErrorAction SilentlyContinue
        if($checkvm)
        {
            Write-Host $destination, "Found" -ForegroundColor Yellow

        }
        else
        {
            $vmhost = Get-VMHost -Name $this.conf.esxi_host
            $datastore=Get-Datastore $this.conf.data_store_name
            $newvm = New-VM -Name $destination -VM $source_vm -LinkedClone -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $datastore -Location $userFolder
            $newvm | Get-NetworkAdapter| Set-NetworkAdapter -NetworkName $this.conf.default_network -Confirm:$false
            SetMaxSnapShots -vm $newvm -count $this.conf.snapshots
            Write-Host $destination, "Created" -ForegroundColor Green
        }
        return $newvm
    }
    DeployClones([string] $sourceName, [string] $destinationPrefix){
        foreach($user in $this.users){
            $destination='{0}-{1}-{2}' -f $destinationPrefix,$this.conf.course_name, $user
            $this.DeployClone($sourceName,$destination,$user)
        }
    }

}