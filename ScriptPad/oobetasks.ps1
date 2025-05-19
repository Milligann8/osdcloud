[CmdletBinding()]
param()
#region Initialize

#Start the Transcript
$Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-OSDCloud.log"
$null = Start-Transcript -Path (Join-Path "$env:SystemRoot\Temp" $Transcript) -ErrorAction Ignore

#=================================================
#   oobeCloud Settings
#=================================================
$Global:oobeCloud = @{
    oobeSetDisplay = $false
    oobeSetRegionLanguage = $false
    oobeSetDateTime = $false
    oobeRemoveAppxPackage = $true
    oobeRemoveAppxPackageName = 'ActiproSoftwareLLC","AdobeSystemsIncorporated.AdobePhotoshopExpress","BubbleWitch3Saga","CandyCrush","DevHome","Disney","Dolby","Duolingo-LearnLanguagesforFree","EclipseManager","Facebook","Flipboard","gaming","Minecraft","Office","PandoraMediaInc","Royal Revolt","Speed Test","Spotify","Sway","Twitter","Wunderlist","AD2F1837.HPPrinterControl","AppUp.IntelGraphicsExperience","C27EB4BA.DropboxOEM*","Disney.37853FC22B2CE","DolbyLaboratories.DolbyAccess","DolbyLaboratories.DolbyAudio","E0469640.SmartAppearance","Microsoft.549981C3F5F10","Microsoft.AV1VideoExtension","Microsoft.BingNews","Microsoft.BingSearch","Microsoft.BingWeather","Microsoft.GetHelp","Microsoft.Getstarted","Microsoft.GamingApp","Microsoft.Messaging","Microsoft.Microsoft3DViewer","Microsoft.MicrosoftEdge.Stable","Microsoft.MicrosoftJournal","Microsoft.MicrosoftOfficeHub","Microsoft.MicrosoftSolitaireCollection","Microsoft.MixedReality.Portal","Microsoft.MPEG2VideoExtension","Microsoft.News","Microsoft.Office.Lens","Microsoft.Office.OneNote","Microsoft.Office.Sway","Microsoft.OneConnect","Microsoft.People","Microsoft.PowerAutomateDesktop","Microsoft.PowerAutomateDesktopCopilotPlugin","Microsoft.Print3D","Microsoft.RemoteDesktop","Microsoft.SkypeApp","Microsoft.SysinternalsSuite","Microsoft.Teams","Microsoft.Windows.DevHome","Microsoft.WindowsAlarms","Microsoft.windowscommunicationsapps","Microsoft.WindowsFeedbackHub","Microsoft.WindowsMaps","Microsoft.Xbox.TCUI","Microsoft.XboxApp","Microsoft.XboxGameOverlay","Microsoft.XboxGamingOverlay","Microsoft.XboxGamingOverlay_5.721.10202.0_neutral_~_8wekyb3d8bbwe","Microsoft.XboxIdentityProvider","Microsoft.XboxSpeechToTextOverlay","Microsoft.ZuneMusic","Microsoft.ZuneVideo","MicrosoftCorporationII.MicrosoftFamily","MicrosoftCorporationII.QuickAssist","MicrosoftWindows.CrossDevice","MirametrixInc.GlancebyMirametrix","RealtimeboardInc.RealtimeBoard","SpotifyAB.SpotifyMusic","5A894077.McAfeeSecurity","5A894077.McAfeeSecurity_2.1.27.0_x64__wafk5atnkzcwy'
    oobeAddCapability = $false
    oobeAddCapabilityName = 'GroupPolicy','ServerManager','VolumeActivation'
    oobeUpdateDrivers = $true
    oobeUpdateWindows = $true
    oobeRestartComputer = $true
    oobeStopComputer = $false
}


Stop-Transcript
#endregion


#=================================================
