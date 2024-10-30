Write-Host "Loading..."
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
Add-Type -AssemblyName System.Drawing, System.Windows.Forms, WindowsFormsIntegration
function Remove-CompleteThreads {
    param (
    )
    $purged = [System.Collections.ArrayList]::new()
    foreach($thread in $syncHash.threads){
        if ($thread.invoke.isCompleted) {
            [void]$thread.ps.EndInvoke($thread.invoke)
            [void]$thread.ps.runspace.close()
			[void]$thread.ps.runspace.dispose()
            [void]$purged.Add($thread)
        } else {
            Write-Host "NONE!"
        }
    }
    if($purged.Count -gt 0){
        foreach($item in $purged){
            $syncHash.threads.Remove($item)
        }
    }
}
$script:syncHash = [hashtable]::Synchronized(@{ })
$syncHash.threads = [System.Collections.ArrayList]::new()
$syncHash.ConnectionStatus = @{
    url = $false
    token = $false
}
function Start-Async {
    param (
        [scriptblock]$block,
        [array]$funcs,
        [array]$Values
    )
    Remove-CompleteThreads
    $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

    foreach($func in $funcs){
        $funcContent = Get-Content ("Function:\$func")
        $funcObj = New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList $func , $funcContent
        $InitialSessionState.Commands.Add($funcObj)
    }

    $runspace = [runspacefactory]::CreateRunspace($InitialSessionState)
    $powerShell = [powershell]::Create()
    $powerShell.runspace = $runspace
    $runspace.ThreadOptions = "ReuseThread"
    $runspace.ApartmentState = "STA"
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("syncHash",$syncHash)
    
    [void]$PowerShell.AddScript($block)
    [void]$syncHash.threads.add([PSCustomObject]@{
        ps = $PowerShell
        invoke = $PowerShell.BeginInvoke()
    })
}


$inputXML = @"
<Window x:Class="tagCannon.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:tagCannon"
        mc:Ignorable="d"
        Title="Tag Cannon - www.Chuco.com v1.9" Height="583" Width="800"
        ResizeMode="NoResize">
        <Window.TaskbarItemInfo>
         <TaskbarItemInfo/>
        </Window.TaskbarItemInfo>
    <Grid>
        
        <TabControl Name="hnTab" Margin="428,91,6,0" Height="414" VerticalAlignment="Top">
            <TabItem Header="Unformatted" FontSize="16" ToolTip="Hostnames to be formatted into a regex string">
                <Grid Background="#FFE5E5E5" Height="382">
                    <TextBox x:Name="hostInput" HorizontalAlignment="Center" TextWrapping="Wrap" Text="Enter one hostname per line and/or comma seperated" VerticalAlignment="Center" Width="340" Height="362" FontSize="14" AcceptsReturn="True" VerticalScrollBarVisibility="Visible"/>
                </Grid>
            </TabItem>
            <TabItem Header="Formatted" FontSize="16" ToolTip="Hostnames regex string from the Unformatted tab">
                <Grid Background="#FFE5E5E5">
                    <TextBox x:Name="formatted" HorizontalAlignment="Center" TextWrapping="Wrap" VerticalAlignment="Top" Width="320" Height="317" IsReadOnly="True" Margin="0,10,0,0" VerticalScrollBarVisibility="Visible"/>
                    <Button x:Name="copyBtn" Content="Copy To Clipboard" HorizontalAlignment="Center" Margin="0,336,0,0" VerticalAlignment="Top" Width="164"/>
                </Grid>
            </TabItem>
        </TabControl>

        <Label Content="Tag Cannon" HorizontalAlignment="Left" Margin="6,-2,0,0" VerticalAlignment="Top" Height="70" Width="548" FontSize="48" FontFamily="Rockwell Extra Bold"/>
        <TextBox x:Name="tanSrvURL" HorizontalAlignment="Left" Margin="137,93,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="251" Text="https://&lt;instance&gt;.cloud.tanium.com" FontSize="14"/>
        <Label Content="Tanium Server URL" HorizontalAlignment="Left" Margin="11,89,0,0" VerticalAlignment="Top" Width="124" FontSize="14"/>
        <Label Content="Tanium Token" HorizontalAlignment="Left" Margin="11,115,0,0" VerticalAlignment="Top" FontSize="14"/>
        <PasswordBox x:Name="tanToken" HorizontalAlignment="Left" Margin="137,118,0,0" VerticalAlignment="Top" Width="251" FontSize="14"/>
        <Label x:Name="tanSrvStat" Content="" HorizontalAlignment="Center" Margin="10,89,0,0" VerticalAlignment="Top" RenderTransformOrigin="-4.645,-4.009" Foreground="#FFFD0707"/>
        <Label x:Name="tanTokenStat" Content="" HorizontalAlignment="Center" Margin="10,113,0,0" VerticalAlignment="Top" RenderTransformOrigin="-4.645,-4.009" Foreground="#FF36B124"/>
        <Label Content="Tags to apply" HorizontalAlignment="Left" Margin="10,139,0,0" VerticalAlignment="Top" Width="110" FontSize="14"/>
        <TextBox x:Name="tags" HorizontalAlignment="Left" Margin="137,146,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="251" FontSize="14" ToolTip="Space seperated tags to deploy to supplied hosts"/>
        <Label Content="Hostnames" HorizontalAlignment="Left" Margin="430,64,0,0" VerticalAlignment="Top" Width="97" FontSize="16" FontWeight="Bold"/>
        <Label x:Name="chucoWeb" Content="www.Chuco.com" HorizontalAlignment="Left" Margin="520,17,0,0" VerticalAlignment="Top" FontSize="18" FontWeight="Bold" ToolTip="Tanium consultants who get sh!t done."/>
        <RadioButton x:Name="plat_win" Content="Windows" HorizontalAlignment="Left" Margin="133,172,0,0" VerticalAlignment="Top" GroupName="platforms" IsChecked="True" FontSize="14" ToolTip="Tags will be deployed using the Windows package"/>
        <Label Content="Host Platforms" HorizontalAlignment="Left" Margin="12,165,0,0" VerticalAlignment="Top" Width="110" FontSize="14"/>
        <RadioButton x:Name="plat_non" Content="Non-Windows" HorizontalAlignment="Left" Margin="225,173,0,0" VerticalAlignment="Top" GroupName="platforms" FontSize="14" ToolTip="Tags will be deployed using the Non-Windows package"/>
        <RadioButton x:Name="plat_both" Content="Both" HorizontalAlignment="Left" Margin="345,173,0,0" VerticalAlignment="Top" GroupName="platforms" FontSize="14" ToolTip="Tags will be deployed using the Windows and Non-Windows packages"/>
        <Button x:Name="sendBtn" Content="Deploy Tags" HorizontalAlignment="Left" Margin="224,288,0,0" VerticalAlignment="Top" Height="29" Width="92" FontSize="14" ToolTip="Click to deploy the configured tag to supplied endpoints"/>
        <TextBox x:Name="log" VerticalScrollBarVisibility="Visible" HorizontalAlignment="Left" Margin="18,339,0,0" TextWrapping="Wrap" IsReadOnly="True" Text="Enter Tanium server information..." VerticalAlignment="Top" Width="395" Height="166" ToolTip="App actions will be displayed here"/>
        <Label Content="Status" HorizontalAlignment="Left" Margin="18,306,0,0" VerticalAlignment="Top" Width="56" FontSize="16" RenderTransformOrigin="0.508,1.208" FontWeight="Bold"/>
        <Label x:Name="hnCount" Content="Count: 000" HorizontalAlignment="Left" Margin="685,514,0,0" VerticalAlignment="Top" RenderTransformOrigin="0.316,12.736" FontSize="14" ToolTip="Number of hostnames found after formatting"/>
        <Button x:Name="formatOnly" Content="Format Only" HorizontalAlignment="Left" Margin="655,92,0,0" VerticalAlignment="Top" Width="120" FontSize="14" ToolTip="Click to format the supplied hostnames into a regex string"/>
        <CheckBox x:Name="save" Content="Save Configuration" HorizontalAlignment="Left" Margin="60,293,0,0" VerticalAlignment="Top" IsChecked="True" FontSize="14" ToolTip="Check to have your current configurations load on next start"/>
        <Label Content="Configurations" HorizontalAlignment="Left" Margin="9,64,0,0" VerticalAlignment="Top" Width="128" FontSize="16" FontWeight="Bold"/>
        <TextBlock HorizontalAlignment="Left" Margin="18,516,0,0" TextWrapping="Wrap" Text="Last action url:" VerticalAlignment="Top" FontSize="14" Width="102" FontWeight="Bold"/>
        <ComboBox x:Name="reissue_type" HorizontalAlignment="Left" Margin="100,242,0,0" VerticalAlignment="Top" Width="102">
            <ComboBoxItem Content="Minutes"></ComboBoxItem>
            <ComboBoxItem Content="Hours" IsSelected="True"></ComboBoxItem>
            <ComboBoxItem Content="Days"></ComboBoxItem>
        </ComboBox>
        <TextBlock HorizontalAlignment="Left" Margin="125,516,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" RenderTransformOrigin="0.234,-0.552" FontSize="14" Width="557">
            <Hyperlink Name="actionURL" NavigateUri="https://chuco.com" ToolTip="URL for the last generated actions"><TextBlock Name="actionURLDisplay" Text="www.Chuco.com" /></Hyperlink>
        </TextBlock>
        <CheckBox x:Name="recurring" Content="Recurring Action" HorizontalAlignment="Left" Margin="18,195,0,0" VerticalAlignment="Top" FontSize="14" FontWeight="Bold" IsChecked="True" ToolTip="Set the actions to recurring. Helpful if machines are offline."/>
        <Label Content="Reissue Every" HorizontalAlignment="Left" Margin="65,213,0,0" VerticalAlignment="Top" FontSize="14" ToolTip="How often the tag package should run. Every 3 hours works well."/>
        <TextBox x:Name="reissue_num" HorizontalAlignment="Left" Margin="43,242,0,0" TextWrapping="Wrap" Text="3" VerticalAlignment="Top" Width="40" FontSize="14" ToolTip="Numbers only"/>
        <Label Content="End After" HorizontalAlignment="Left" Margin="285,213,0,0" VerticalAlignment="Top" FontSize="14" ToolTip="How far in the furutre actions will stop running."/>
        <ComboBox x:Name="end_type" HorizontalAlignment="Left" Margin="293,242,0,0" VerticalAlignment="Top" Width="102">
            <ComboBoxItem Content="Minutes"></ComboBoxItem>
            <ComboBoxItem Content="Hours"></ComboBoxItem>
            <ComboBoxItem Content="Days" IsSelected="True"></ComboBoxItem>
        </ComboBox>
        <TextBox x:Name="end_num" HorizontalAlignment="Left" Margin="236,242,0,0" TextWrapping="Wrap" Text="3" VerticalAlignment="Top" Width="40" FontSize="14" ToolTip="Numbers only"/>
    </Grid>
</Window>

"@ 
$chucoC = "iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAIAAABt+uBvAAAA0GVYSWZJSSoACAAAAAoAAAEEAAEA
AABgAAAAAQEEAAEAAABgAAAAAgEDAAMAAACGAAAAEgEDAAEAAAABAAAAGgEFAAEAAACMAAAAGwEF
AAEAAACUAAAAKAEDAAEAAAADAAAAMQECAA0AAACcAAAAMgECABQAAACqAAAAaYcEAAEAAAC+AAAA
AAAAAAgACAAIAL0AAAAFAAAAvQAAAAUAAABHSU1QIDIuMTAuMzgAADIwMjQ6MTA6MDUgMDA6MjQ6
NTEAAQABoAMAAQAAAAEAAAAAAAAAYQXjtAAAAYRpQ0NQSUNDIHByb2ZpbGUAAHicfZE9SMNAHMVf
U0ulVBwsIuKQoTrZpYo41ioUoUKoFVp1MLn0C5q0JCkujoJrwcGPxaqDi7OuDq6CIPgB4uzgpOgi
Jf4vKbSI8eC4H+/uPe7eAUKryjSzLwFoumVkUkkxl18Vg68IIQA/4hiWmVmfk6Q0PMfXPXx8vYvx
LO9zf44BtWAywCcSJ1jdsIg3iGc2rTrnfeIIK8sq8TnxpEEXJH7kuuLyG+eSwwLPjBjZzDxxhFgs
9bDSw6xsaMTTxFFV0ylfyLmsct7irFUbrHNP/sJwQV9Z5jrNMaSwiCVIEKGggQqqsBCjVSfFRIb2
kx7+UccvkUshVwWMHAuoQYPs+MH/4He3ZnEq7iaFk0DgxbY/xoHgLtBu2vb3sW23TwD/M3Cld/21
FjD7SXqzq0WPgMFt4OK6qyl7wOUOMPJUlw3Zkfw0hWIReD+jb8oDQ7dAaM3trbOP0wcgS12lb4CD
Q2CiRNnrHu/u7+3t3zOd/n4Afntyqxj7ja8AAA14aVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8
P3hwYWNrZXQgYmVnaW49Iu+7vyIgaWQ9Ilc1TTBNcENlaGlIenJlU3pOVGN6a2M5ZCI/Pgo8eDp4
bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA0LjQuMC1F
eGl2MiI+CiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjIt
cmRmLXN5bnRheC1ucyMiPgogIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICB4bWxu
czp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIKICAgIHhtbG5zOnN0RXZ0
PSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VFdmVudCMiCiAgICB4
bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iCiAgICB4bWxuczpHSU1Q
PSJodHRwOi8vd3d3LmdpbXAub3JnL3htcC8iCiAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRv
YmUuY29tL3RpZmYvMS4wLyIKICAgIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAv
MS4wLyIKICAgeG1wTU06RG9jdW1lbnRJRD0iZ2ltcDpkb2NpZDpnaW1wOmIxNjE5OGM0LThhZGMt
NGE2ZC1iOWVkLTIzMzI4MGIxYTA2NiIKICAgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDo3MmZl
OWFiNC0xYWZlLTQ0NjMtODk2NC02YjU3ZWEwMTljMzQiCiAgIHhtcE1NOk9yaWdpbmFsRG9jdW1l
bnRJRD0ieG1wLmRpZDpiNWE0Y2E3My05YmUwLTQ1NWYtYTY1Ni05OGE5MDdjMTJmYjkiCiAgIGRj
OkZvcm1hdD0iaW1hZ2UvcG5nIgogICBHSU1QOkFQST0iMi4wIgogICBHSU1QOlBsYXRmb3JtPSJM
aW51eCIKICAgR0lNUDpUaW1lU3RhbXA9IjE3MjgxMDIyOTgxMTI1NzciCiAgIEdJTVA6VmVyc2lv
bj0iMi4xMC4zOCIKICAgdGlmZjpPcmllbnRhdGlvbj0iMSIKICAgeG1wOkNyZWF0b3JUb29sPSJH
SU1QIDIuMTAiCiAgIHhtcDpNZXRhZGF0YURhdGU9IjIwMjQ6MTA6MDVUMDA6MjQ6NTEtMDQ6MDAi
CiAgIHhtcDpNb2RpZnlEYXRlPSIyMDI0OjEwOjA1VDAwOjI0OjUxLTA0OjAwIj4KICAgPHhtcE1N
Okhpc3Rvcnk+CiAgICA8cmRmOlNlcT4KICAgICA8cmRmOmxpCiAgICAgIHN0RXZ0OmFjdGlvbj0i
c2F2ZWQiCiAgICAgIHN0RXZ0OmNoYW5nZWQ9Ii8iCiAgICAgIHN0RXZ0Omluc3RhbmNlSUQ9Inht
cC5paWQ6NzQ4MmRhNTktZWIwMC00MDQ3LThmNDYtMzYxNjYyZDk0NTNlIgogICAgICBzdEV2dDpz
b2Z0d2FyZUFnZW50PSJHaW1wIDIuMTAgKExpbnV4KSIKICAgICAgc3RFdnQ6d2hlbj0iMjAyNC0x
MC0wNVQwMDoyNDo1OC0wNDowMCIvPgogICAgPC9yZGY6U2VxPgogICA8L3htcE1NOkhpc3Rvcnk+
CiAgPC9yZGY6RGVzY3JpcHRpb24+CiA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgogICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAK
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgCjw/eHBhY2tldCBlbmQ9
InciPz6R+iNbAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAAB3RJTUUH6AoFBBg6CLMy6wAAFn9JREFU
eNrVXXl4VOW5f79zZstMJtuE7BsJSUgAQQhbIS5AFQGLFvVi61YLXWyxrV2tj9Z7ba+32rpVab29
ohW1FqnWBbVVoUViEAg7YUJC9j2TZCaZfTnv/eOsc+bMZGYyJOn38ISTk5k55/udd/297/cNQUSI
OBCREBLumH27cDL0XewBwzBur9865h4YsfdbHL0WR8+Iq2vE1Wn1tjn9DgYBoFhHl6RoCtK0Baak
PJM+LzM522TITNMb9FoVTck+nL2o9H4u0SATAhT3QMRAgLFYnY2tQw0XLEfbbWar1+ILgBRRBCDS
twAh4jkNgTK9+vI8w9LyjIXlWUW5aVqNiqIuLSJTARDD4OCI/WRT//5T/XuaR30MQUBCCAIQBAQQ
njqPhfA/AhAkSIAIt0UAEJAAWWHSblqYvXxebllhhlajmlKAwulRrMPrC7R2j7z3Wdsbpy3d7gAQ
bubIX0muoTxkPBAARBQpRAReUYFwn2UgcFVB8tba4iVVuanGpKkAKCGa7PcHzrQMvPGv1r1mqwPZ
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
V6BvWRayAAAAAElFTkSuQmCC"
$icon = New-Object System.Windows.Media.Imaging.BitmapImage
$icon.BeginInit()
$icon.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($chucoC)
$icon.EndInit()
$icon.Freeze()
$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window'
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
Add-Type -AssemblyName System.Drawing, System.Windows.Forms, WindowsFormsIntegration
[xml]$XAML = $inputXML
$reader=(New-Object System.Xml.XmlNodeReader $xaml)
$syncHash.Form=[Windows.Markup.XamlReader]::Load( $reader )
$syncHash.Form.Icon = $icon
$syncHash.Form.TaskbarItemInfo.Overlay = $icon
$syncHash.Form.TaskbarItemInfo.Description = $syncHash.Form.Title
$xaml.SelectNodes("//*[@Name]") | Foreach-Object {[void]$syncHash.add($_.Name,$syncHash.Form.FindName($_.Name))}
 
function Set-ButtonsToDisabled {
    $syncHash.sendBtn.IsEnabled = $false
    $syncHash.formatOnly.IsEnabled = $false
}
function Set-ButtonsToEnabled {
    $syncHash.Form.Dispatcher.Invoke([action]{
        $syncHash.sendBtn.IsEnabled = $true
        $syncHash.formatOnly.IsEnabled = $true
    })
    
}

function Format-TaniumURL {
    $url = $syncHash.Values.tanURL
    if(-not [uri]::IsWellFormedUriString($url, 'Absolute')){
        Set-CannonLog "The supplied URL is not a well formatted URL"
        return $false
    }
    if(([uri] $url).Scheme -eq 'http'){
        $syncHash.Values.tanURL = $syncHash.Values.tanURL.replace('http','https')
        $syncHash.Form.Dispatcher.Invoke([action]{
            $syncHash.tanSrvURL.Text = $syncHash.Values.tanURL
        })
        Set-CannonLog -msg "Tanium URL must be HTTPS.`n...This was updated for you"
    }
    if($url -match "cloud.tanium.com" -and $url -notmatch "-api"){
        $split = $url.split(".")
        $split[0] = $split[0] + "-api"
        $url = $split -join "."
        $syncHash.Values.tanURL = $url
        $syncHash.Form.Dispatcher.Invoke([action]{
            $syncHash.tanSrvURL.Text = $syncHash.Values.tanURL
        })
        Set-CannonLog -msg "Tanium cloud API must contain `"-api`"`n...This was updated for you"
    }
    if($url -match "^.*/$"){
        $url = $url.Substring(0, $url.Length - 1)
        $syncHash.Values.tanURL = $url
        $syncHash.Form.Dispatcher.Invoke([action]{
            $syncHash.tanSrvURL.Text = $syncHash.Values.tanURL
        })
        Set-CannonLog -msg "Removed trailing `"/`" from url"
    }
    if($url -match "^.*/api$"){
        $url = $url.replace("/api","")
        $syncHash.Values.tanURL = $url
        $syncHash.Form.Dispatcher.Invoke([action]{
            $syncHash.tanSrvURL.Text = $syncHash.Values.tanURL
        })
        Set-CannonLog -msg "Removed trailing `"/api`" from url"
    }
    if($url -match "https://.*/.*"){
        Set-CannonLog -msg "Found additional `"/`" in url.`nPlease check the url and try again."
        return $false
    }
    return $true
}
function Test-TaniumServerConnection {
    param(
        [bool]$ServerOnly = $false,
        [bool]$TokenOnly = $false,
        [bool]$Silent = $false
    )
    $configStatus = @{
        pass = @{
            text = "0x00002705"
            color = "#FF36B124"
        }
         fail = @{
            text = "0x0001F6C7"
            color = "#FFFD0707"
        }
    }
    if(-not (Format-TaniumURL)){
        $syncHash.Form.Dispatcher.Invoke([action]{
            $syncHash.tanSrvStat.Content = [char]::ConvertFromUtf32($configStatus.fail.text)
            $syncHash.tanSrvStat.Foreground = $configStatus.fail.color
        })
        $syncHash.ConnectionStatus.url = $false
        return $False
    }
    $url = $syncHash.Values.tanURL
    $token = $syncHash.Values.tanToken
    if(-not $Silent){Set-CannonLog -msg "Connecting to Tanium"}
    if(-not $TokenOnly){
        if(Test-NetConnection ($url.replace("https://","")) -Port 443 -InformationLevel Quiet){
            $syncHash.Form.Dispatcher.Invoke([action]{
                $syncHash.tanSrvStat.Content = [char]::ConvertFromUtf32($configStatus.pass.text)
                $syncHash.tanSrvStat.Foreground = $configStatus.pass.color
            })
            $syncHash.ConnectionStatus.url = $true
            if(-not $Silent){Set-CannonLog -msg "...Success"}else{Set-CannonLog -msg "URL is VALID"}

        }else{
            $syncHash.Form.Dispatcher.Invoke([action]{
                $syncHash.tanSrvStat.Content = [char]::ConvertFromUtf32($configStatus.fail.text)
                $syncHash.tanSrvStat.Foreground = $configStatus.fail.color
            })
            $syncHash.ConnectionStatus.url = $false
            if(-not $Silent){Set-CannonLog -msg "...FAILED"}else{Set-CannonLog -msg "URL NOT valid"}

            return $false
        }
    }
    if(-not $ServerOnly){
        try{
            if(-not $Silent){Set-CannonLog -msg "Validating Token"}

            $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $headers.Add("session", $token)
            $headers.Add("Content-Type", "application/json")

            $body = @{
                session = $token
            }
            $body = $body | ConvertTo-Json
            try{
                $response = Invoke-RestMethod "$url/api/v2/session/validate" -Method 'POST' -Headers $headers -Body $body
            }catch [System.Security.Authentication.AuthenticationException] {
                if($_.Exception -match "The remote certificate is invalid according to the validation procedure"){
                    $turnSSLVerifOff = [System.Windows.MessageBox]::Show("Unable to validate the Tanium server SSL certificate`n`nWould you like to turn off SSL verification for this session?","Chuco Tag Cannon - SSL ERROR",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Error)        
                }
                if($turnSSLVerifOff -eq "Yes"){
                    $syncHash.Form.Dispatcher.Invoke([action]{
                        add-type @"
                         using System.Net;
                         using System.Security.Cryptography.X509Certificates;
                         public class TrustAllCertsPolicy : ICertificatePolicy {
                             public bool CheckValidationResult(
                                 ServicePoint srvPoint, X509Certificate certificate,
                                 WebRequest request, int certificateProblem) {
                                 return true;
                             }
                        }
"@    
                    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
                    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Ssl3, [Net.SecurityProtocolType]::Tls, [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::Tls12
                    })
                    [System.Windows.MessageBox]::Show("SSL validation has been disabled.`n`nTo enable restart Tag Cannon","Chuco Tag Cannon - SSL Validation",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning)
                    Set-CannonLog -msg "SSL verification disabled"    
                }
                return $false
            }
            $syncHash.Form.Dispatcher.Invoke([action]{
                $syncHash.tanTokenStat.Content = [char]::ConvertFromUtf32($configStatus.pass.text)
                $syncHash.tanTokenStat.Foreground = $configStatus.pass.color
            })
            $syncHash.ConnectionStatus.token = $true
            if(-not $Silent){Set-CannonLog -msg "...Success"}else{Set-CannonLog -msg "Token is VALID"}


        }catch{
            $syncHash.Form.Dispatcher.Invoke([action]{
                $syncHash.tanTokenStat.Content = [char]::ConvertFromUtf32($configStatus.fail.text)
                $syncHash.tanTokenStat.Foreground = $configStatus.fail.color
            })
            $syncHash.ConnectionStatus.token = $false
            if(-not $Silent){Set-CannonLog -msg "...FAILED"}else{Set-CannonLog -msg "Token is NOT valid"}

            return $false
        }
    }
    return $true
}

function Set-Config {
    $cryptToken = ConvertTo-SecureString $syncHash.Values.tanToken -AsPlainText -Force | ConvertFrom-SecureString
    @{
        url=$syncHash.Values.tanURL
        token=$cryptToken
        host=$syncHash.Values.hostInput
        platform=$syncHash.Values.platform

    } | Export-Clixml -Path (Join-Path $syncHash.Values.path cannon.config)
}

function Import-Config {
    $configPath = Join-Path $PSScriptRoot "cannon.config"
    if(Test-Path $configPath){
        $config = Import-Clixml $configPath 
        $syncHash.tanSrvURL.Text = $config.url
        $sTokenString =  $config.token | ConvertTo-SecureString
        $syncHash.tanToken.Password = [System.Net.NetworkCredential]::new("", $sTokenString).Password
        $syncHash.hostInput.Text = $config.host
        switch ($config.platform) {#No need to check for Windows. This is the form default.
            "Non" { $syncHash.plat_non.IsChecked = $true }
            "Both" { $syncHash.plat_both.IsChecked = $true }
        }
    }
}
function Set-CannonLog {
    param(
        [string]$msg
    )
    $syncHash.Form.Dispatcher.Invoke([action]{
        $syncHash.log.Text = $syncHash.log.Text + "`r`n" + $msg
        $syncHash.log.ScrollToEnd()
    })
}
function Format-HostList {
    param (
        [string]$hostNames
    )
    $illChars = ([regex]::Matches($hostNames,"[^\w\r\n\.\-,]") | ForEach-Object {$_.value}|Select-Object -Unique) -join " "
	if($illChars.Length -gt 0){
		Set-CannonLog -msg "Illegal character(s) in hostnames: $illChars"
		return
	}
    $domains = @{
        None = [System.Collections.ArrayList]::new()
    }
    $hnCount = 0
    $splitVals = ($hostNames.Split("`n") -join ",").split(",")
    foreach($name in $splitVals){
        $cleanName = $name.trim().toLower()
        if($cleanName.Length -gt 0){
			$hnCount++
            if($cleanName -match "\."){
                $splits = $cleanName.Split(".")
                $hn = $splits[0]
                $dn = "\." + ($splits[1..($splits.Count)] -join "\.")
                if(-not $domains.ContainsKey($dn)){
                    $domains.Add($dn,[System.Collections.ArrayList]::new())
                }
                [void]$domains[$dn].add($hn)
            }else{
                [void]$domains.none.Add($cleanName)
            }
        }
    }
    
    $noDomainReg = "(\..*)*"
    
    $regTxt = ""
    
    if($domains.None.Count -gt 0){
        $regTxt = "($($domains.None -join "|"))$noDomainReg"
    }
    
    if($domains.Count -gt 1){
        foreach($dn in $domains.Keys){
            if($dn -eq "None"){continue}
        }
        $compList = "($($domains[$dn] -join '|'))$dn"
        if($regTxt.Length -gt 0){
            $regTxt += "|$compList"
        } else {
            $regTxt = $compList
        }
    }
	$syncHash.Values.Add("hnCount",$hnCount)
    Start-Async -block {
		Set-HostCount
	} -func @("Set-HostCount")
	
    return $regTxt
}

function Set-HostCount {
	$Count = $syncHash.Values.hnCount
	if($Count -lt 10){
		$countLine = "Count: 00$Count"
	}elseif($Count -lt 100){
		$countLine = "Count: 0$Count"
	}else{
		$countLine = "Count: $Count"
	}
	$syncHash.Form.Dispatcher.Invoke([action]{
        $syncHash.hnCount.Content = $countLine
    })
}

function Set-FormattedHost {
    param (
        [string]$hostRegex
    )
    $syncHash.Form.Dispatcher.Invoke([action]{
        $syncHash.formatted.Text = $hostRegex
        if($hostRegex.Length -gt 0){
            $syncHash.hnTab.SelectedIndex = 1
        }
    })

}

function Get-Tags {
    $tagList = [System.Collections.ArrayList]::new()
    foreach($tag in $syncHash.tags.text.split(" ")){
        $thisTag = $tag.Trim()
        if($thisTag.Length -gt 0){
            [void]$tagList.add($thisTag)
        }
    }
    return $tagList
}

function Get-HashValues {
    if($syncHash.plat_win.IsChecked){
		$Platform = "Win"
	}elseif($syncHash.plat_non.IsChecked){
		$Platform = "Non"
	}else{
		$Platform = "Both"
	}
    
    $syncHash.Values = @{
        tanURL = $syncHash.tanSrvURL.Text
        tanToken = $syncHash.tanToken.Password.ToString()
        hostInput = $syncHash.hostInput.Text
		platform = $Platform
        path = $PSScriptRoot
        save = $syncHash.save.IsChecked
        tags = Get-Tags
        recurring = $syncHash.recurring.IsChecked
        reissue_num = $syncHash.reissue_num.Text
        reissue_type = $syncHash.reissue_type.SelectedItem.Content
        end_num = $syncHash.end_num.Text
        end_type = $syncHash.end_type.SelectedItem.Content
    }

    #Wait-Debugger
}

function Set-CustomTags {
    $url = $syncHash.Values.tanUrl
    $token = $syncHash.Values.tanToken
    $tags =  $syncHash.Values.tags
    $hnRegex = $syncHash.Values.formattedHosts
    $plat =  $syncHash.Values.platform

    
        
    $recurring = $syncHash.Values.recurring
    [int]$reissue_num = $syncHash.Values.reissue_num
    $reissue_unit = $syncHash.Values.reissue_type
    [int]$end_num = $syncHash.Values.end_num
    $end_unit = $syncHash.Values.end_type

    #Wait-Debugger
    if($recurring){
        $secondsToEnd = switch($end_unit){
            "Minutes" { $end_num * 60 }
            "Hours" { $end_num * 3600 }
            "Days" { $end_num * 86400}
        }
        $endTime = ([System.DateTime]::UtcNow + [System.TimeSpan]::FromSeconds($secondsToEnd)).ToString("o")
        $reissueSeconds = switch($reissue_unit){
            "Minutes" { $reissue_num * 60 }
            "Hours" { $reissue_num * 3600 }
            "Days" { $reissue_num * 86400}
        }
    } else {
        $reissueSeconds = $null
        $endTime = $null
    }

    $package = switch($plat){
        "win" {"Custom Tagging - Add Tags"}
        "non" {"Custom Tagging - Add Tags (Non-Windows)"}
    }

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("session", $token)
    $headers.Add("Content-Type", "application/json")

    $queries = [System.Collections.ArrayList]::new()
    
    $query_both = @'
    mutation ActionPerform(
  $reissueSeconds: Int
  $endTime: Time
  $actionName: String!
  $tag: [String!]!
  $tagStr: String!
  $hostnameRegex: String!
) {
  actionPerform(
    input: {
      targets: {
        targetGroup: {
          filter: {
            filters: [
              {
                sensor: { name: "Computer Name" }
                op: MATCHES
                value: $hostnameRegex
              }
              {
                sensor: {
                  name: "Custom Tag Exists"
                  params: [{ name: "tag", value: $tagStr }]
                }
                op: EQ
                value: "False"
              }
            ]
          }
        }
        actionGroup: { name: "Default - All Computers" }
      }
      schedule: { reissueSeconds: $reissueSeconds, endTime: $endTime }
      comment: "Action created by Chuco Tag Cannon www.Chuco.com"
      name: $actionName
      operation: { addTags: $tag }
    }
  ) {
    error {
      message
      retryable
      timedOut
    }
    scheduledActions {
      scheduledAction {
        id
        lastAction {
          id
        }
      }
    }
  }
}
'@
    $query_single = @'
     mutation ActionPerform(
    $reissueSeconds: Int
    $endTime: Time
    $actionName : String!
    $tag:[String!]!
    $tagStr:String!
    $hostnameRegex:String!
    $package:String!
 ){
    actionPerform(
        input: {
            targets: {
                targetGroup: {
                    filter: {
                        filters: [
                            {
                                sensor: { name: "Computer Name" }
                                op: MATCHES
                                value: $hostnameRegex
                            }
                            {
                                sensor: {
                                    name: "Custom Tag Exists"
                                    params: [{ name: "tag", value: $tagStr }]
                                }
                                op: EQ
                                value: "False"
                            }
                        ]
                    }
                }
                actionGroup: { name: "Default - All Computers" }
            }
            schedule: { reissueSeconds: $reissueSeconds, endTime: $endTime }
            comment: "Action created by Chuco Tag Cannon www.Chuco.com"
            name: $actionName
            package: { name: $package, params: $tag }
        }
    ) {
        error {
            message
            retryable
            timedOut
        }
        scheduledActions {
            scheduledAction {
                id
                lastAction {
                    id
                }
            }
        }
    }
}
'@
    
    foreach($tag in $tags){
        $thisQry = @{}
        if($plat -eq "both"){
            Add-Member -InputObject $thisQry -MemberType NoteProperty -Name "qry" -Value $query_both
        } else {
            Add-Member -InputObject $thisQry -MemberType NoteProperty -Name "qry" -Value $query_single
        }
        Add-Member -InputObject $thisQry -MemberType NoteProperty -Name "var" -Value @{
            reissueSeconds = $reissueSeconds
            endTime = $endTime
            actionName = "Chuco - Tag Cannon [$tag]"
            tag = @($tag)
            tagStr = $tag
            hostnameRegex = $hnRegex
            package = $package
        }
        $queries.Add($thisQry)
    }
    Start-Async -block {
        Set-CannonLog -msg "Creating Tanium action"
    } -funcs @("Set-CannonLog")
    $responses = [System.Collections.ArrayList]::new()
    foreach($query in $queries){
       
        $body = @{"query" = $query.qry
        "variables" = $query.var} | ConvertTo-Json -Depth 20
        try{
            $responses.add((Invoke-RestMethod "$url/plugin/products/gateway/graphql" -Method 'POST' -Headers $headers -Body $body))
        }catch{
            Set-CannonLog -msg "Failed to create Tanium action"
            return
        }
    }
    $actionIds = [System.Collections.ArrayList]::new()
    foreach($response in $responses){
        foreach($action in $response.data.actionPerform.scheduledActions.scheduledAction){
            if($recurring){
                $lastActionID = $action.id
                $query = @"
                    query ScheduledAction {
    scheduledAction(ref: { id: "$lastActionId" }) {
        lastAction {
            id
            stopped
        }
        id
    }
}
"@
            $scheduledActionResponse = Invoke-RestMethod "$url/plugin/products/gateway/graphql" -Method 'POST' -Headers $headers -Body (@{query =$query}|ConvertTo-Json -Depth 20)
            $actionIds.add($scheduledActionResponse.data.scheduledAction.LastAction.id)
            } else {
                $actionIds.add($action.lastAction.id)
            }
        }
    }


    if($null -eq $responses[0].error){
       $actionId = $actionIds -Join ","
       $reportUrl = $url.replace("-api","")
       $actionURL = "$reportUrl/ui/console/actions/status/$actionId"
       if($actionURL.Length -gt 85){
        $displayURL = $actionURL.Substring(0,82) + "..."
       } else {
        $displayURL = $actionURL
       }
       Set-CannonLog -msg "Tagging action created`n...Action ID = $actionId"
       $syncHash.Form.Dispatcher.Invoke([action]{
        $syncHash.actionURL.NavigateUri = $actionURL
        $syncHash.actionURLDisplay.Text = $displayURL
    })
    }else{
       Set-CannonLog -msg "Failed to create Tanium action"
    }
    

}

function Set-Recurring {
    $status = $syncHash.recurring.IsChecked
    $syncHash.reissue_num.IsEnabled = $status
    $syncHash.reissue_type.IsEnabled = $status
    $syncHash.end_num.IsEnabled = $status
    $syncHash.end_type.IsEnabled = $status
}

$syncHash.recurring.Add_Checked({
    Set-Recurring
})
$syncHash.recurring.Add_UnChecked({
    Set-Recurring
})

$syncHash.tanSrvURL.Add_LostFocus({
    Get-HashValues
    Start-Async -block {
        Test-TaniumServerConnection -Silent $true -ServerOnly $true
        
    } -funcs @("Set-CannonLog","Test-TaniumServerConnection","Format-TaniumURL")
})
$syncHash.tanToken.Add_LostFocus({
    if($syncHash.ConnectionStatus.url){
        Get-HashValues
        Start-Async -block {
            Test-TaniumServerConnection -Silent $true -TokenOnly $true

        } -funcs @("Set-CannonLog","Test-TaniumServerConnection","Format-TaniumURL")
    }
})

$syncHash.sendBtn.Add_Click({
    Set-ButtonsToDisabled
    $input = $syncHash.hostInput.Text
    if($input.Length -eq 0 -or $input -eq "Enter one hostname per line and/or comma seperated"){
        Set-CannonLog -msg "Must supply target hostname(s)"
        Set-ButtonsToEnabled
        return
    }
    Get-HashValues
    if($syncHash.Values.tags.count -eq 0){
        Set-CannonLog -msg "No tags supplied"
        Set-ButtonsToEnabled
        return
    }
    
    Start-Async -block {
        if($syncHash.Values.save){
            Start-Async -block {
                Set-Config
            } -funcs @("Set-Config")
        }
        if(-not $syncHash.ConnectionStatus.token -or -not $syncHash.ConnectionStatus.url){
            Test-TaniumServerConnection 
        }

        if($syncHash.ConnectionStatus.token -and $syncHash.ConnectionStatus.url){
            $formattedHosts = Format-HostList -hostNames $syncHash.Values.hostInput
            Set-FormattedHost $formattedHosts
            $syncHash.Values.formattedHosts = $formattedHosts
        }

        if($syncHash.Values.hnCount -gt 0){
            $tagCount = $syncHash.Values.tags.count
            $Confirm = [System.Windows.MessageBox]::Show("You are deploying $tagCount tag(s) to $($syncHash.Values.hnCount) system(s)","Chuco Tag Cannon - Confirm Deployment",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Warning)
        }

        if($Confirm -eq "Yes"){
            Set-CustomTags
        } else {
            Set-CannonLog -msg "Tag deployment not created."
        }

        Set-ButtonsToEnabled
    } -funcs @("Set-ButtonsToEnabled","Test-TaniumServerConnection","Format-TaniumURL","Set-CannonLog","Format-HostList","Set-FormattedHost",
        "Start-Async","Remove-CompleteThreads","Set-HostCount","Set-Config","Set-CustomTags")
})
$syncHash.formatOnly.Add_Click({
    Set-ButtonsToDisabled
    Get-HashValues
    Start-Async -block {
        if($syncHash.Values.save){
            Start-Async -block {
                Set-Config
            } -funcs @("Set-Config")
        }
        $formattedHosts = Format-HostList -hostNames $syncHash.Values.hostInput
        if($formattedHosts.Length -gt 0){
			Set-FormattedHost $formattedHosts
			try{
				Set-Clipboard -Value $formattedHosts
				Set-CannonLog -msg "Format complete and sent to clipboard"
			}catch{
				Set-CannonLog -msg "Failed to copy hostnames to the clipboard.`nPlease manually copy them from the Formatted tab."
			}
		}
        Set-ButtonsToEnabled
    } -funcs @("Set-ButtonsToEnabled","Set-CannonLog","Format-HostList","Set-FormattedHost","Start-Async","Remove-CompleteThreads",
        "Set-HostCount","Set-Config")
})
$syncHash.copyBtn.Add_Click({
    if($syncHash.formatted.text.Length -lt 3){return}
    try{
        Set-Clipboard -Value $syncHash.formatted.text
        Set-CannonLog -msg "Copied formatted string to clipboard"
    }catch{
        Set-CannonLog -msg "Failed to copy formatted string to clipboard.`n...Please manually copy them from the Formatted tab.`n...CTRL + A then CTRL + C"
    }
})

$syncHash.actionURL.Add_Click({
    $url = $syncHash.actionURL.NavigateUri
    Start-Process $url
})
Clear-Host
Write-Host @"
  _______       _____    _____          _   _ _   _  ____  _   _ 
 |__   __|/\   / ____|  / ____|   /\   | \ | | \ | |/ __ \| \ | |
    | |  /  \ | |  __  | |       /  \  |  \| |  \| | |  | |  \| |
    | | / /\ \| | |_ | | |      / /\ \ | .  ` | .  ` | |  | | .  ` |
    | |/ ____ \ |__| | | |____ / ____ \| |\  | |\  | |__| | |\  |
    |_/_/    \_\_____|  \_____/_/    \_\_| \_|_| \_|\____/|_| \_|
                                                                                                         
"@

Write-Host "                          www.Chuco.com                            		" -Foreground Blue -Background White
Write-Host "                      Trusted" -Foreground Blue -Background White -NoNewLine
Write-Host " Tanium " -Foreground Red -Background White -NoNewLine
Write-Host "Experts                       		" -Foreground Blue -Background White
Write-Host "`n`nTag Cannon (c) 2024 by Chuco is licensed under Creative Commons`nAttribution-NonCommercial-NoDerivatives 4.0 International`n`n"
Import-Config
Read-Host "Press enter to accept EULA and launch GUI"
try{
	Add-Type -Name Window -Namespace Console -MemberDefinition '
	[DllImport("Kernel32.dll")]
	public static extern IntPtr GetConsoleWindow();
	
	[DllImport("user32.dll")]
	public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
	'
	
	$console = [Console.Window]::GetConsoleWindow()
	[Console.Window]::ShowWindow($console, 0) | Out-Null
	Write-Host "GUI opened"
}catch{
	Write-Host "Failed to put the console away. GUI opened"
}
	
try{
	[void]$syncHash.Form.ShowDialog()

}catch{
	Write-Output "Faild to launch GUI. Time to update PowerShell?"
	pause
}
 
 
 