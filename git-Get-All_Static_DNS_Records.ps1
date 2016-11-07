<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.127
	 Created on:   	9/28/2016 2:44 PM
	 Created by:   	dverbern via rsmith
	 Organization: 	
	 Filename:     	Get-All_Static_DNS_Records.ps1
	===========================================================================
	.DESCRIPTION
		Get list of Static A records in DNS Zone of your choice.
		Does NOT run from Win7, Must be newer OS
#>

Clear-Host
$PathToReport = "C:\"
$To = "EMAIL ADDRESS"
$From = "GetAllStaticDNSRecords@savers.com"
$SMTPServer = "SMTP SERVER"
$ZoneName = "DOMAIN"
$DomainController = "DOMAIN CONTROLLER FQDN"


#Get Current date for input into report
$CurrentDate = Get-Date -Format "MMMM, yyyy"

#region Functions
Function Set-AlternatingRows
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $True, ValueFromPipeline = $True)]
		[object[]]$HTMLDocument,
		[Parameter(Mandatory = $True)]
		[string]$CSSEvenClass,
		[Parameter(Mandatory = $True)]
		[string]$CSSOddClass
	)
	Begin
	{
		$ClassName = $CSSEvenClass
	}
	Process
	{
		[string]$Line = $HTMLDocument
		$Line = $Line.Replace("<tr>", "<tr class=""$ClassName"">")
		If ($ClassName -eq $CSSEvenClass)
		{
			$ClassName = $CSSOddClass
		}
		Else
		{
			$ClassName = $CSSEvenClass
		}
		$Line = $Line.Replace("<table>", "<table width=""20%"">")
		Return $Line
	}
}
#endregion

$Header = @"
<style>
TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #D8E4FA;}
TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
.odd  { background-color:#ffffff; }
.even { background-color:#dddddd; }
</style>
<title>Static DNS A Records across all Nodes of $ZoneName Domain for $CurrentDate</title>
"@

$Report = Get-DnsServerResourceRecord -ZoneName $ZoneName -ComputerName $DomainController -RRType A | Where Timestamp -eq $Null | Select -Property HostName, RecordType -ExpandProperty RecordData
$NumberOfRecords = $Report | Measure-Object HostName | Select-Object -Property Count
$Report = $Report | Select HostName, RecordType, IPv4Address |
ConvertTo-Html -Head $Header -PreContent "<p><h2>Static DNS A Records across all Nodes of $ZoneName Domain for $CurrentDate</h2></p><br><p><h3>$NumberOfRecords Records listed</h3></p>" |
Set-AlternatingRows -CSSEvenClass even -CSSOddClass odd
$Report | Out-File $PathToReport\Output_AD_GetListStaticARecords.html
Send-MailMessage -To $To -From $From -Subject "Static DNS A Records across all Nodes of $ZoneName Domain for $CurrentDate" -Body ($Report | Out-String) -BodyAsHtml -SmtpServer $SMTPServer

Write-Host "Script completed!" -ForegroundColor Green

