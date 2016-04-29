﻿function Backup-NAVApplicationObjects
{
    <#
    .Synopsis
       Creates Delta's, fob, txt files by providing Original and Modified databases, and path
    .DESCRIPTION
       To create every single possible export of your developments
    .NOTES
       <TODO: Some tips>
    .PREREQUISITES
       <TODO: like positioning the prompt and such>
    .EXAMPLE
        $CreatedITems = Backup-NAVApplicationObjects `                    -BackupOption OnlyModified `                    -ServerInstance $DEVInstance `                    -BackupPath $BackupPath `                    -Name $Name `                    -NavAppOriginalServerInstance $ORIGInstance `                    -NavAppWorkingFolder $WorkingFolder 
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
        [Object] $ServerInstance,
        [Parameter(Mandatory=$False)]
        [ValidateSet('AllObjects','OnlyModified','CustomFilter')]
        [String] $BackupOption,
        [Parameter(Mandatory=$False)]
        [String] $CustomFilter,
        [Parameter(Mandatory=$true)]
        [String] $BackupPath,
        [Parameter(Mandatory=$false)]
        [Object] $NavAppOriginalServerInstance,
        [Parameter(Mandatory=$false)]
        [String] $NavAppWorkingFolder,
        [Parameter(Mandatory=$false)]
        [Object] $ExportPermissionSetId,
        [Parameter(Mandatory=$False)]
        [String] $Name
        

    )
    Process{
        $ServerInstanceObject = (Get-NAVServerInstanceDetails -ServerInstance $ServerInstance)
        
        switch($BackupOption){
            'AllObjects' {
                $ObjectFilter = ''
            }
            'OnlyModified' {
                $ObjectFilter = 'Modified=1'
            }
            'CustomFilter'{
                $ObjectFilter = $CustomFilter
            }
        }
        $BackupFiles = @()
        
        if ([String]::IsNullOrEmpty($Name)){$Name = $ServerInstance}
        $Backupfiletxt = join-path $BackupPath "$($Name)_$($BackupOption).txt"
        $Backupfilefob = join-path $BackupPath "$($Name)_$($BackupOption).fob"     
        
        if ([String]::IsNullOrEmpty($ObjectFilter)){
            Write-host -ForegroundColor Green "Creating $Backupfiletxt"
            Export-NAVApplicationObject -DatabaseServer "$($ServerInstanceObject.DatabaseServer)\$($ServerInstanceObject.DatabaseInstance)" -DatabaseName $ServerInstanceObject.DatabaseName -Path $Backupfiletxt -Force
            Write-host -ForegroundColor Green "Creating $Backupfilefob"
            Export-NAVApplicationObject -DatabaseServer "$($ServerInstanceObject.DatabaseServer)\$($ServerInstanceObject.DatabaseInstance)" -DatabaseName $ServerInstanceObject.DatabaseName -Path $Backupfilefob -Force        
        }
        Else {
            Write-host -ForegroundColor Green "Creating $Backupfiletxt"
            Export-NAVApplicationObject -Filter $ObjectFilter -DatabaseServer "$($ServerInstanceObject.DatabaseServer)\$($ServerInstanceObject.DatabaseInstance)" -DatabaseName $ServerInstanceObject.DatabaseName -Path $Backupfiletxt -Force
            Write-host -ForegroundColor Green "Creating $Backupfilefob"
            Export-NAVApplicationObject -Filter $ObjectFilter -DatabaseServer "$($ServerInstanceObject.DatabaseServer)\$($ServerInstanceObject.DatabaseInstance)" -DatabaseName $ServerInstanceObject.DatabaseName -Path $Backupfilefob -Force
        
        }
        
        Get-Item $Backupfiletxt  | Split-NAVApplicationObjectFile -Destination "$BackupPath\Split\" -Force
      
        if(!([String]::IsNullOrEmpty($NavAppOriginalServerInstance))) {
            if ([string]::IsNullOrEmpty(($NavAppWorkingFolder))){
                Write-Error 'Please provide a workingfolder if you want to create delta''s'
                break
            }

            $Folders =                 Create-NAVDelta `                    -OriginalServerInstance $NavAppOriginalServerInstance `                    -ModifiedServerInstance $ServerInstance `                    -WorkingFolder $NavAppWorkingFolder `                    -CreateReverseDeltas

            foreach($Folder in $Folders){
                $null = Copy-Item -Path $Folder -Destination $BackupPath -Recurse -Force
            }
            
            Get-childitem $BackupPath
        } else {
            write-warning 'No delta''s were created!'
        }
    }
    
}

