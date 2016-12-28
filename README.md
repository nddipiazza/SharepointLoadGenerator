# Create test sites, subsites, sharepoint site groups, document libraries and upload file structure

Here we will create a bunch of test data files using a generator tool. Then we will use a powershell script to create Sites, Sub-Sites and Document libraries and it upload the generated test folders into these new document libraries. 

## Step 1: Generate the test files

There is a Visual Studio project created by Microsoft that can load a Wikipedia backup and can create PPT, DOC, HTML, Excel files from wikipedia content so that they have real content and images too.

Get the project from here: https://spbulkdocumentimport.codeplex.com/

You will need this downloaded and extracted to use this: https://dumps.wikimedia.org/enwiki/latest/enwiki-latest-pages-articles.xml.bz2

### How to build the Bulk Loader visual studio project:

Download this Visual Studio Project:
https://code.msdn.microsoft.com/Bulk-Loader-Create-Unique-eeb2d084

It is an app called "Bulk loader" – this will create a directory full of media files created using the actual Wikipedia content.

Download / install / launch Visual Studio 2015 community version
https://www.microsoft.com/en-us/download/details.aspx?displaylang=en&id=5124 install this as well

Make sure you have .NET framework 4 installed.

Open the .sln "Bulk Loader - Create Unique Documents based on Wikipedia Dump File\C#\BulkLoader.sln" file in visual studio

In Visual Studio, open the .sln file for BulkLoader

Go to Properties → Signing → Uncheck the clickonce signing.

Make sure Open XML SDK and log4net DLL references are added.

Install Open XML SDK 2.0 for Microsoft Office
http://www.microsoft.com/download/en/details.aspx?displaylang=en&id=5124

Download Apache log4net-1.2.15

On each project, add references to log4net and openxml DLLs.

Build the project, which will generate 4 project’s executables:

 * BulkLoader.Processor.Console
 * BulkLoader.Streamer.Console
 * BulkLoader.Controller.Console
 * BulkLoader.Monitor.Console

### How to run it: 

See video demo: https://www.youtube.com/watch?v=O2vX2kfK0mQ

## Step 2: Create Sites, Sub-Sites, Sharepoint site groups, Document Libraries and upload the generated test files using the powershell script

In step 1, we created a big bundle of test documents and subfolders. 

In this step we save the following script and edit the number of host, name prefixes, number of sites you want to create, number of sub-sites you want to create, and number of document libraries and the location of the generated test files from Step 1.

Note the docLibFileDumpFolder is the result of Step 1 and it must have at least (numSites * numSubSites * numDocumentLIbraries) folders in it. The tool will add each document library one folder at a time in that directory. 

Save the powershell script from this git repository `sharepoint-load-test-data-generator.ps1` and save it to the Sharepoint server. Edit the file and change the properties at the top to match your preferences. 

$sharepointHost = Your sharepoint hostname
$siteNamePrefix = The prefix it should give all of your sites. They will be testsiteprefix1, testsiteprefix2, etc.
$subsiteNamePrefix = The prefix it should give all of your sub-sites. They will be testsubsiteprefix1, testsubsiteprefix2, etc.
$siteGroupNamePrefix = The site group name prefix to give all sharepoint site groups created.
$documentLibraryNamePrefix = The document library prefix given to all sharepoint document libraries creatd.
$docLibFileDumpFolder = The folder containing the output of step 1 above.
$numSites = The number of sites to create.
$numSubSites = The number of sub-sites to create in each site.
$numDocumentLibraies = The number of document libraries to create in each site and sub-site.
$numSharepointSiteGroupsToCreate = The number of sharepoint site groups to create in each site. 
