function New-EventLogFilter
{
[cmdletbinding(
    DefaultParameterSetName='byEventID'
)]
Param(
    [string]
    $LogName
    ,
    [System.Diagnostics.Eventing.Reader.StandardEventLevel]
    $Level
    ,
    [switch]
    $LevelError
    ,
    [switch]
    $LevelInformation
    ,
    [switch]
    $LevelWarning
    ,
    [switch]
    $LevelCritical
    ,
    [Parameter(ParameterSetName='byEventID')]
    [string]
    $EventID
    ,
    [Parameter(ParameterSetName='byEventRecordID')]
    [string]
    $RecordID
    ,
    [string]
    $Provider
)

    $f = $MyInvocation.InvocationName
    #Write-Verbose -Message "$f - START"

    $logLevelLookup = @{
        Critical = 1
        Error = 2
        Warning = 3
        Information = @(0,4)
        Verbose = 5
    }

    $logLevels = [System.Collections.Generic.List[int]]::new()

    if ($PSBoundParameters.ContainsKey("Level"))
    {
        if ($Level -eq [System.Diagnostics.Eventing.Reader.StandardEventLevel]::Informational)
        {        
            $logLevels.Add([int]$Level.value__)
            $logLevels.Add(0)
        }
        else 
        {
            $logLevels.Add($Level.value__)
        }    
    }

    if ($LevelError.IsPresent)
    {
        $logLevels.Add($logLevelLookup.Error)
    }

    if ($LevelInformation.IsPresent)
    {
        $logLevels.AddRange($logLevelLookup.Information)
    }

    if ($LevelWarning.IsPresent)
    {
        $logLevels.Add($logLevelLookup.Warning)
    }

    if ($LevelCritical.IsPresent)
    {
        $logLevels.Add($logLevelLookup.Critical)
    }

    $query = [System.Text.StringBuilder]::new()
    $null = $query.Append('*')

    if (-not [string]::IsNullOrEmpty($Provider))
    {
        $null = $query.Append('[System[')
        $null = $query.Append('Provider[$Name=')
        $null = $query.Append("'$Provider']")
    }

    if ($logLevels.Count -gt 0)
    {   
        if ($PSBoundParameters.ContainsKey('Provider'))
        {
            $null = $query.Append(' and ')        
        }
        else
        {
            $null = $query.Append('[System[')
        }
        
        $counter = 0
        $null = $query.Append('(')
        foreach ($int in $logLevels)
        {        
            $null = $query.Append('Level=')
            $null = $query.Append($int)
            $counter++
            if ($logLevels.Count -ne $counter)
            {
                $null = $query.Append(' or ')
            }        
        }
        $null = $query.Append(')')
    }

    $eventIds = [System.Collections.Generic.List[int]]::new()

    if (-not ([string]::IsNullOrEmpty($EventID)))
    {
        if ($logLevels.Count -eq 0 -and [string]::IsNullOrEmpty($Provider))
        {
            $null = $query.Append('[System[')
        }

        $split = $EventID.Split(',')

        foreach ($id in $split)
        {
            if ($id.Contains('-'))
            {
                $start = $id.split('-')[0]
                $end = $id.split('-')[1]
                $range = ($start..$end)

                foreach ($i in $range)
                {
                    $eventIds.Add($i)
                }
            }
            else 
            {
                $eventIds.Add($id)
            }
        }
    }

    if ($eventIds.Count -ne 0)
    {
        if ($logLevels.Count -gt 0 -or [string]::IsNullOrEmpty($Provider) -eq $false)
        {
            $null = $query.Append(' and ')
        }

        $null = $query.Append('(')
        $counter = 0
        foreach ($i in $eventIds)
        {
            $null = $query.Append('EventID=')
            $null = $query.Append($i)
            $counter++
            if ($counter -ne $eventIds.Count)
            {
                $null = $query.Append(' or ')
            }        
        }
        $null = $query.Append(')')
    }

    $eventRecordIDs = [System.Collections.Generic.List[int]]::new()

    if (-not ([string]::IsNullOrEmpty($RecordID)))
    {
        if ($logLevels.Count -eq 0 -and [string]::IsNullOrEmpty($Provider) -and $eventIds.Count -eq 0)
        {
            $null = $query.Append('[System[')
        }

        $split = $RecordID.Split(',')

        foreach ($id in $split)
        {
            if ($id.Contains('-'))
            {
                $start = $id.split('-')[0]
                $end = $id.split('-')[1]
                $range = ($start..$end)

                foreach ($i in $range)
                {
                    $eventRecordIDs.Add($i)
                }
            }
            else 
            {
                $eventRecordIDs.Add($id)
            }
        }
    }

    if ($eventRecordIDs.Count -ne 0)
    {
        if ($logLevels.Count -gt 0 -or [string]::IsNullOrEmpty($Provider) -eq $false -or $eventIds.Count -gt 0)
        {
            $null = $query.Append(' and ')
        }

        $null = $query.Append('(')
        $counter = 0
        foreach ($i in $eventRecordIDs)
        {
            $null = $query.Append('EventRecordID=')
            $null = $query.Append($i)
            $counter++
            if ($counter -ne $eventRecordIDs.Count)
            {
                $null = $query.Append(' or ')
            }        
        }
        $null = $query.Append(')')
    }


    if ($logLevels.Count -gt 0 -or [string]::IsNullOrEmpty($Provider) -eq $false -or $eventIds.Count -gt 0 -or $eventRecordIDs.Count -gt 0)
    {
        $null = $query.Append(']]')
    }

    $xml = [System.Xml.XmlDocument]::new()

    $queryList = $xml.CreateElement('QueryList')
    $queryList.SetAttribute("foobar","")
    $null = $xml.AppendChild($queryList)

    $queryElement = $xml.CreateElement('Query')
    $queryElement.SetAttribute('Id', 0)
    $queryElement.SetAttribute('Path', $LogName)
    $null = $xml.QueryList.AppendChild($queryElement)
    $queryList.RemoveAllAttributes()

    $select = $xml.CreateElement('Select')
    $select.SetAttribute('Path', $LogName)
    $select.InnerText = $query.ToString()
    $null = $xml.QueryList.Query.AppendChild($select)

    #Write-Verbose -Message "query=$($xml.OuterXml)"
    $xml.OuterXml
    #Write-Verbose -Message "$f - END"
}

