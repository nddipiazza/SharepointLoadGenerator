Add-PSSnapin Microsoft.SharePoint.PowerShell
$sharepointHost = "http://win-od8k4mkm92n"
$siteNamePrefix = "test4site"
$subsiteNamePrefix = "test4subsite"
$siteGroupNamePrefix = "test4spsitegroup"
$documentLibraryNamePrefix = "test4doclib"
$docLibFileDumpFolder = "C:\outdir\document-library-dumps"
$numSites = 2
$numSubSites = 2
$numDocumentLibraies = 2
$numSharepointSiteGroupsToCreate = 5
function New-SPList {
    <#
    .Synopsis
	    Use New-SPList to create a new SharePoint List or Library.
    .Description
	    This advanced PowerShell function uses the Add method of a SPWeb object to create new lists and libraries in a SharePoint Web
	    specified in the -Web parameter.
    .Example
	    C:\PS>New-SPList -Web http://intranet -ListTitle "My Documents" -ListUrl "MyDocuments" -Description "This is my library" -Template "Document Library"
	    This example creates a standard Document Library in the http://intranet site.
    .Example
	    C:\PS>New-SPList -Web http://intranet -ListTitle "My Announcements" -ListUrl "MyAnnouncements" -Description "These are company-wide announcements." -Template "Announcements"
	    This example creates an Announcements list in the http://intranet site.
    .Notes
	    You must use the 'friendly' name for the type of list or library.  To retrieve the available Library Templates, use Get-SPListTemplates.
    .Link
	    http://www.iccblogs.com/blogs/rdennis
 		    http://twitter.com/SharePointRyan
    .Inputs
	    None
    .Outputs
	    None
    #>    
	[CmdletBinding()]
	Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
	    [string]$Web,
        [Parameter(Mandatory=$true)]
	    [string]$ListTitle,
        [Parameter(Mandatory=$true)]
	    [string]$ListUrl,
	    [Parameter(Mandatory=$false)]
	    [string]$Description,
	    [Parameter(Mandatory=$true)]
	    [string]$Template
    )
    Start-SPAssignment -Global
    $SPWeb = Get-SPWeb -Identity $Web
    $listTemplate = $SPWeb.ListTemplates[$Template]
    $SPWeb.Lists.Add($ListUrl,$Description,$listTemplate)
    $list = $SPWeb.Lists[$ListUrl]
    $list.Title = $ListTitle
    $list.Update()
    $newListRootFolder = $list.RootFolder.Name
    Write-Host "Created new list $Web/$newListRootFolder" -foregroundcolor Green
    $SPWeb.Dispose()
    Stop-SPAssignment -Global
}
function Upload-Files-To-SPDocumentList {
    <#
    .Synopsis
	    Use to upload a bunch of files in a directory to a SPList
    #>    
	[CmdletBinding()]
	Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
	    [string]$Web,
        [Parameter(Mandatory=$true)]
	    [string]$DocLibraryGuid,
        [Parameter(Mandatory=$true)]
	    [string]$ListUrl,
	    [Parameter(Mandatory=$true)]
	    [string]$DocLibraryUrlName,
	    [Parameter(Mandatory=$true)]
	    [string]$LocalFolderPath,
	    [Parameter(Mandatory=$false)]
	    [string]$RelativeParentFileName
    )
    Start-SPAssignment -Global
    $SPWeb = Get-SPWeb $Web
    $docLibrary = $SPWeb.Lists[[GUID]($DocLibraryGuid)]
    $files = ([System.IO.DirectoryInfo] (Get-Item $localFolderPath)).GetFiles()
    ForEach($file in $files)
    {
        $newFileUrl = $docLibrary.RootFolder.Name
        if ($RelativeParentFileName) 
        {
            $newFileUrl += $RelativeParentFileName
        }
        $folder = $SPWeb.GetFolder($newFileUrl)
        $fileStream = ([System.IO.FileInfo] (Get-Item $file.FullName)).OpenRead()
        $newRelativeFilePath = $newFileUrl + "/" + $file.Name
        $spFile = $folder.Files.Add($newRelativeFilePath, [System.IO.Stream]$fileStream, $true)
        write-host "Uploaded new file $Web/$newRelativeFilePath" -foregroundcolor Green
        $fileStream.Close();
    }
    $dirs = ([System.IO.DirectoryInfo] (Get-Item $localFolderPath)).GetDirectories()
    ForEach($dir in $dirs)
    {
        $newFolderUrl = $docLibrary.RootFolder.Name
        if ($RelativeParentFileName) 
        {
            $newFolderUrl += $RelativeParentFileName
        }
        $parentFolder = $newFolderUrl
        $newFolderUrl += "/" + $dir.Name
        $folder = $SPWeb.GetFolder($newFolderUrl)
        $parentFolder = $SPWeb.GetFolder($parentFolder).ServerRelativeUrl
        if (-Not $folder.Exists)
        {
            $folder = $docLibrary.AddItem($parentFolder, [Microsoft.SharePoint.SPFileSystemObjectType]::Folder, $dir.Name)
            $folder["Title"] = $dir.Name
            $folder.Update();
            write-host "Created new folder $Web/$newFolderUrl" -foregroundcolor Green
            $groupToAssign = $siteGroupNamePrefix + "1"
            $group = $SPWeb.SiteGroups[$groupToAssign]
            $roleAssignment = new-object Microsoft.SharePoint.SPRoleAssignment($group)
            $roleDefinition = $SPWeb.RoleDefinitions["Read"];
            $roleAssignment.RoleDefinitionBindings.Add($roleDefinition);
            $folder = $SPWeb.GetFolder($newFolderUrl)
            $folder.Item.BreakRoleInheritance($true);
            $folder.Item.RoleAssignments.Add($roleAssignment);
            $folder.Item.Update();
            write-host "Assigned group $siteGroupNamePrefix1 to folder" -foregroundcolor Green
        }
        $newRelUrl = $RelativeParentFileName + "/" + $dir.Name
        Upload-Files-To-SPDocumentList -Web $Web -DocLibraryGuid $DocLibraryGuid -DocLibraryUrlName $DocLibraryUrlName -ListUrl $ListUrl -LocalFolderPath $dir.FullName -RelativeParentFileName $newRelUrl
    }
    $SPWeb.Dispose() 
    Stop-SPAssignment -Global
}
function Create-SPGroupInWeb
{
    param ($Url, $GroupName, $PermissionLevel, $Description)
    $web = Get-SPWeb -Identity $Url
    if ($web.SiteGroups[$GroupName] -ne $null)
    {
        Write-Host "Group $GroupName already exists!" -foregroundcolor Red
    }
    else
    {
        $web.SiteGroups.Add($GroupName, $web.Site.Owner, $web.Site.Owner, $Description)
        $group = $web.SiteGroups[$GroupName]
        $roleAssignment = new-object Microsoft.SharePoint.SPRoleAssignment($group)
        $roleDefinition = $web.Site.RootWeb.RoleDefinitions[$PermissionLevel]
        $roleAssignment.RoleDefinitionBindings.Add($roleDefinition)
        $web.RoleAssignments.Add($roleAssignment)
        $web.Update()
        Write-Host "Group $GroupName created successfully" -foregroundcolor Green
    }

    $web.Dispose()
}
function ProcessSite {
    <#
    .Synopsis
	   Add doc libs to a site, then adds groups to the site, then adds files to the document libraries.
    #>    
	[CmdletBinding()]
	Param(
        [Parameter(Mandatory=$true)]
	    [string]$siteUrl
    )
    for ($k=1; $k -le $numSharepointSiteGroupsToCreate; $k++)
    {
        Create-SPGroupInWeb -Url $siteUrl -GroupName "$siteGroupNamePrefix$k" -PermissionLevel "Read" -Description "My group description"
    }
    for ($k=1; $k -le $numDocumentLibraies; $k++)
    {
        $listUrl = "$documentLibraryNamePrefix$k"
        $listTitle = "Document Library $docLibraryIdx"
        $docLibraryUrlName = "$documentLibraryNamePrefix$j"
        $spNewList = New-SPList -Web $siteUrl -ListTitle "Document Library $docLibraryIdx" -ListUrl $listUrl -Description "This is my library" -Template "Document Library"
        Upload-Files-To-SPDocumentList -Web $siteUrl -DocLibraryGuid $spNewList.Guid -ListUrl $listUrl -localFolderPath $docLibFolders[$docLibFolderIndex].FullName -DocLibraryUrlName $docLibraryUrlName
        $docLibFolderIndex += 1
    }
}
$docLibFolderIndex = 0
$docLibFolders = ([System.IO.DirectoryInfo] (Get-Item $docLibFileDumpFolder)).GetDirectories()
for ($i=1; $i -le $numSites; $i++)
{
  write-host "Creating site $sharepointHost/sites/$siteNamePrefix$i which is $i out of $numSites to create" -foregroundcolor Green
  New-SPSite $sharepointHost/sites/$siteNamePrefix$i -OwnerAlias "lucidworks\administrator" -Name "$siteNamePrefix-$i" -Template "STS#2"
  ProcessSite $sharepointHost/sites/$siteNamePrefix$i
  for ($j=1; $j -le $numSubSites; $j++)
  {
    write-host "Creating sub-site $sharepointHost/sites/$siteNamePrefix$i/$subsiteNamePrefix$j which is $j out of $numSubSites to create." -foregroundcolor Green
    New-SPWeb $sharepointHost/sites/$siteNamePrefix$i/$subsiteNamePrefix$j -Template "STS#2"
    ProcessSite $sharepointHost/sites/$siteNamePrefix$i/$subsiteNamePrefix$j
  }
}
