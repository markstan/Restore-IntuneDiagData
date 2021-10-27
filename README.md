# Restore-IntuneDiagData.ps1

Restore-IntuneDiagData.ps1 is a stand-alone script to organize data collected by the [Intune collect diagnostics](https://docs.microsoft.com/en-us/mem/intune/remote-actions/collect-diagnostics) device action.

This script will organize the [collected data](https://docs.microsoft.com/en-us/mem/intune/remote-actions/collect-diagnostics#data-collected) in to a logical folder structure and renames the files to reflect their contents.


## Usage

Use these steps to run this utility:

1. Create a temporary folder, download [Restore-IntuneDiagData.ps1](https://raw.githubusercontent.com/markstan/Restore-IntuneDiagData/master/Restore-IntuneDiagData.ps1) from this repo and save the file to this folder.
1. Download the device diagnostics data from the [MEM portal](https://endpoint.microsoft.com/#blade/Microsoft_Intune_DeviceSettings/DevicesMenu/mDMDevicesPreview) (Home &gt; Devices &gt; All devices &gt; &lt;DeviceName&gt; &gt; Device diagnostics &gt; Download) and unzip the DiagLogs-*.zip file using Windows Explorer (right-click\Open with\Windows Explorer)
1. Open a PowerShell window and run **.\Restore-IntuneDiagData.ps1**.  If you launch the script from the folder where the data is extracted, no additional parameters are required.  Otherwise, specify the location of the extracted file structure using the **-sourcePath**  command-line switch.  
**Example:**
    ```powershell-interactive
     .\Restore-IntuneDiagData.ps1 -sourcePath c:\temp\DiagLogs-DeviceName
    ```
1. The script will copy data and rename files as appropriate.  Embedded CAB files (mpsupportfiles.cab and mdmlogs*.cab) will be extracted to a subfolder.  When the script completes, it will launch Windows Explorer in the folder where the  extracted data has been copied.



## Known issues and planned improvements

* Coming soon: auto-extraction of the Diaglogs zip file.
* Multiple copies of files may exist (for example, Event Viewer logs and registry keys).  A future improvement will consolidate the files to a single location.
* Some third-party file archiving tools may report "Headers Error:" and the name of the file when extracting data from Diaglogs*.zip.  To work around this limitation, open the zip using Windows Explorer.
* Ability to specify an output folder.
* Move rather than copy files to increase performance and reduce disk space used.
* Cleanup source file location by default (and add an option not to delete files).

## FAQ


Q: Why this tool?

A: The Intune collect diagnostics feature provides admins a simple way to collect data without having to log on to managed Windows devices.  This tool aims to allow admins to quickly locate the data they are looking for.

Q: Where is the data stored?

A: Files are copied from the extracted zip archive to %temp%\IntuneDeviceData.

Q:  I'd like to add addtional files to the collected data.  Where can I suggest changes to this feature?

A:  The best way to make this kind of request is through your Microsoft account team.  They can assist you with filing a design change request.




## Copyright
Copyright (c) 2017 Microsoft. All rights reserved.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
