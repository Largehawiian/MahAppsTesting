#========================================================================
# Author 	: Kevin RAHETILAHY                                          #
#========================================================================
##############################################################
#                      LOAD ASSEMBLY                         #
##############################################################
$Assemblyfolder = "G:\My Drive\Work\Artemis\Powershell\MahAppsTesting"
[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')  				| out-null
[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') 				| out-null
[System.Reflection.Assembly]::LoadWithPartialName('PresentationCore')      				| out-null
[System.Reflection.Assembly]::LoadFrom('{0}\assembly\MahApps.Metro.dll' -f $Assemblyfolder)       				| out-null
[System.Reflection.Assembly]::LoadFrom('{0}\assembly\System.Windows.Interactivity.dll' -f $Assemblyfolder) 	| out-null
[System.Windows.Forms.Application]::EnableVisualStyles()
##############################################################
#                      LOAD FUNCTION                         #
##############################################################
function LoadXml ($Global:filename) {
    $XamlLoader = (New-Object System.Xml.XmlDocument)
    $XamlLoader.Load($filename)
    return $XamlLoader
}
# Load MainWindow
$XamlMainWindow = LoadXml("{0}\Main.xaml" -f $Assemblyfolder)
$Reader = [System.Xml.XmlNodeReader]::new($XamlMainWindow)
$Form = [Windows.Markup.XamlReader]::Load($Reader)
[xml]$xml = $XamlMainWindow
$xml.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name $_.Name -Value $Form.FindName($_.Name) }
# ===============================================
# ======== Load TemplateWindow ==================
# ===============================================
$xamlDialog = LoadXml("{0}\template\Dialog.xaml" -f $Assemblyfolder)
$read = [System.Xml.XmlNodeReader]::new($xamlDialog)
$DialogForm = [Windows.Markup.XamlReader]::Load( $read )
[xml]$xml = $xamlDialog
$xml.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name $_.Name -Value $DialogForm.FindName($_.Name) }
# Create a new Dialog attached to Main Form
$CustomDialog = [MahApps.Metro.Controls.Dialogs.CustomDialog]::new($Form)
# Specifiy the content of the Custom dialog with the new
# dialog form created.
$CustomDialog.AddChild($DialogForm)
# ===============================================
# ======== Load Sample Window ===================
# ===============================================
$xamlDialog = LoadXml("{0}\template\Sample.xaml" -f $Assemblyfolder)
$read = [System.Xml.XmlNodeReader]::new($xamlDialog)
$SampleForm = [Windows.Markup.XamlReader]::Load( $read )
[xml]$xml = $xamlDialog
$xml.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name $_.Name -Value $SampleForm.FindName($_.Name) }
# Create another Dialog attached to Main Form
$SampleDialog = [MahApps.Metro.Controls.Dialogs.CustomDialog]::new($Form)
# Specifiy the content of the Sample dialog
$SampleDialog.AddChild($SampleForm)
# ===============================================
# ===  Metro Dialog Settings                  ===
# ===============================================
$settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()
$settings.ColorScheme = [MahApps.Metro.Controls.Dialogs.MetroDialogColorScheme]::Theme

##############################################################
#                CONTROL INITIALIZATION                      #
##############################################################

function Set-DialogText ($InputObject) {
    $dialgName.Text = $InputObject.Name
    $dialgNumCPU.Text = $InputObject.NumCPU
    $dialgMemoryGB.Text = $InputObject.MemoryGB
    $dialgProvisionedSpaceGB.Text = $InputObject.ProvisionedSpaceGB
    $dialgUsedSpaceGB.Text = $InputObject.UsedSpaceGB
    $dialgGuest.Text = $InputObject.Guest
    $dialgPowerState.Text = $InputObject.PowerState
    $dialgVMhost.Text = $InputObject.VMhost
}
# === Inside sample Dialog ===
$closeMe = $SampleForm.FindName("closeMe")
# ===  Window Resources   ====
$ApplicationResources = $Form.Resources.MergedDictionaries
$VisualBrush = $iconDialog.Child.OpacityMask.Visual.Children

##############################################################
#                DATAS EXAMPLE                               #
##############################################################
# observablCollection is easier to handle :)
$script:observableCollection = [System.Collections.ObjectModel.ObservableCollection[Object]]::new()
$vms | % { $script:observableCollection.add($_) }

# Add datas to the datagrid
$Gridlogs.ItemsSource = $Script:observableCollection
##############################################################
#                FUNCTIONS                                   #
##############################################################
# Function view a row
Function viewRow($rowObj) {
    # ==== VIEW ICON  ===
    $iconDialog.Background.Color = "#FF44AFE3"
    $VisualBrush.RemoveAt(0)
    $VisualBrush.Add($ApplicationResources[0].Item("appbar_magnify"))
    # Disable inputs
    $dialgName.IsEnabled = $false
    $dialgNumCPU.IsEnabled = $false
    $dialgMemoryGB.IsEnabled = $false
    $dialgProvisionedSpaceGB.IsEnabled = $false
    $dialgUsedSpaceGB.IsEnabled = $false
    $dialgGuest.IsEnabled = $false
    $dialgPowerState.IsEnabled = $false
    $dialgVMhost.IsEnabled = $false

    # Fill inputs with selected object

    # Show custom dialog form
    [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowMetroDialogAsync($Form, $CustomDialog, $settings)

}
# Function to view a row
Function editRow($rowObj) {
    # ==== EDIT ICON  ===
    $iconDialog.Background.Color = "#198C19"
    $VisualBrush.RemoveAt(0)
    $VisualBrush.Add($ApplicationResources[0].Item("appbar_edit"))
    # Enable inputs
    $dialgName.IsEnabled = $true
    $dialgNumCPU.IsEnabled = $true
    $dialgMemoryGB.IsEnabled = $true
    $dialgProvisionedSpaceGB.IsEnabled = $true
    $dialgUsedSpaceGB.IsEnabled = $true
    $dialgGuest.IsEnabled = $true
    $dialgPowerState.IsEnabled = $true
    $dialgVMhost.IsEnabled = $true

    # Show custom dialog form
    [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowMetroDialogAsync($Form, $CustomDialog, $settings)
}
# Function to remove row
Function removeRow($rowObj) {
    $script:observableCollection.Remove($rowObj)
}
##############################################################
#                MANAGE EVENT ON PANEL                       #
##############################################################
# close the sample dialog
$closeMe.add_Click({
        # Close the Custom Dialog
        $SampleDialog.RequestCloseAsync()
    })
# show the sample dialog
$showSample.add_Click({
        [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowMetroDialogAsync($Form, $SampleDialog, $settings)
    })
# Close the dialog from within the dialog
$DialogClose.add_Click({
        # Update and refresh the content of the datagrid
        $index = $observableCollection.IndexOf($resultObj)
        $script:observableCollection[$index].Name = $dialgName.Text
        $script:observableCollection[$index].NumCPU = $dialgNumCPU.Text
        $script:observableCollection[$index].MemoryGB = $dialgMemoryGB.Text
        $script:observableCollection[$index].ProvisionedSpaceGB = $dialgProvisionedSpaceGB.Text
        $script:observableCollection[$index].UsedSpaceGB = $dialgUsedSpaceGB.Text
        $script:observableCollection[$index].Guest = $dialgGuest.Text
        $script:observableCollection[$index].PowerState = $dialgPowerState.Text
        $script:observableCollection[$index].VMhost = $dialgVMhost.Text
        $Gridlogs.Items.Refresh()
        # Close the Custom Dialog
        $CustomDialog.RequestCloseAsync()
    })

[System.Windows.RoutedEventHandler]$EventonDataGrid = {
    # GET THE NAME OF EVENT SOURCE
    $button = $_.OriginalSource.Name
    # THIS RETURN THE ROW DATA AVAILABLE
    # resultObj scope is the whole script because we need
    # it to update values when the dialog is closed.
    $Script:resultObj = $Gridlogs.CurrentItem
    # CHOOSE THE CORRESPONDING ACTION
    If ( $button -match "View" ) {
        Write-Host "View row"
        Set-DialogText $resultObj
        viewRow -rowObj $resultObj
    }
    ElseIf ($button -match "Edit" ) {
        Write-Host "Edit row"
        Set-DialogText $resultObj
        editRow -rowObj $resultObj
    }
    ElseIf ($button -match "Delete" ) {
        Write-Host "Remove row"
        removeRow -rowObj $resultObj
    }
}
$Gridlogs.AddHandler([System.Windows.Controls.Button]::ClickEvent, $EventonDataGrid)

##############################################################
#                SHOW WINDOW                                 #
##############################################################
$Form.ShowDialog() | Out-Null
