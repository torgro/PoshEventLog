function Get-FastEventLog
{
[cmdletbinding(
    DefaultParameterSetName='byEventID'
)]
Param(
    [int]
    [Parameter(ParameterSetName="byEventID")]
    $EventID
    ,
    [Parameter(ParameterSetName="byEventID")]
    [int]
    $RecordID
    ,
    [System.Diagnostics.Eventing.Reader.EventBookmark]
    $Bookmark
    ,
    [string]
    $LogName
    ,
    [Parameter(ParameterSetName="byFilterXML")]
    [string]
    $FilterXML
    ,
    [string[]]
    $Computer
    ,
    [pscredential]
    $Credential
    ,
    [int]
    $MaxEvents = 1000
    ,
    [switch]
    $ResolveMessage
)

$sessionList = [System.Collections.Generic.List[System.Diagnostics.Eventing.Reader.EventLogSession]]::new()

if ($PSBoundParameters.ContainsKey("Computer"))
{
    foreach ($host in $Computer)
    {
        if ($PSBoundParameters.ContainsKey('Credential'))
        {
            $netCred = $Credential.GetNetworkCredential()
            $domain = $netCred.Domain
            $user = $netCred.UserName
            $netCred.Password = [string]::Empty
        }
    
        if (-not [string]::IsNullOrEmpty($user))
        {
            $session = [System.Diagnostics.Eventing.Reader.EventLogSession]::new(
                $host,
                $domain,
                $user,
                $Credential.Password,
                [System.Diagnostics.Eventing.Reader.SessionAuthentication]::Default
            )
        }
        else 
        {
            $session = System.Diagnostics.Eventing.Reader.EventLogSession]::new($host)
        }

        $sessionList.Add($session)
    }    
}
else 
{
    $session = [System.Diagnostics.Eventing.Reader.EventLogSession]::new()
    $null = $sessionList.Add($session)
}

if ($PSBoundParameters.ContainsKey("EventID"))
{
    $query = New-EventLogFilter -LogName $LogName -EventID $EventID
}

if ($PSBoundParameters.ContainsKey("RecordID"))
{
    $query = New-EventLogFilter -LogName $LogName -RecordID $RecordID
}

if ([string]::IsNullOrEmpty($query))
{
    $query = New-EventLogFilter -LogName $LogName -Verbose
}

if ($PSBoundParameters.ContainsKey("FilterXML"))
{
    $query = $FilterXML
}

#Write-Verbose -Message "Query=$query"

$queryType = [System.Diagnostics.Eventing.Reader.PathType]::LogName

foreach ($eventSession in $sessionList)
{
    $eventQuery = [System.Diagnostics.Eventing.Reader.EventLogQuery]::new($LogName, $queryType, $query)
    $eventQuery.Session = $eventSession
    $eventQuery.TolerateQueryErrors = $true
    $eventQuery.ReverseDirection = $false
    if ($PSBoundParameters.ContainsKey($Bookmark))
    {
        $eventReader = [System.Diagnostics.Eventing.Reader.EventLogReader]::new($eventQuery, $Bookmark)
    }
    else 
    {
        $eventReader = [System.Diagnostics.Eventing.Reader.EventLogReader]::new($eventQuery)
    }

    foreach ($i in (1..$MaxEvents))
    {
        $event = $eventReader.ReadEvent()

        if ($null -eq $event)
        {
            break
        }
        
        if ($ResolveMessage.IsPresent)
        {
            #$msg = $event.FormatDescription()
            $event | Get-EventMessage
        }
        else 
        {
            $event
        }
    }
    
}

}