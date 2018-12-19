function Export-EventLogBookMark
{
[cmdletbinding()]
Param(
    [Parameter(
        ParameterSetName = "byObject",
        ValueFromPipeline
    )]
    [System.Diagnostics.Eventing.Reader.EventBookmark]
    $Bookmark
    ,
    [Parameter(
        ParameterSetName = "byEventRecord",
        ValueFromPipeline
    )]
    [System.Diagnostics.Eventing.Reader.EventRecord]
    $Event
    ,
    [Parameter(
        ParameterSetName = "manual",
        Mandatory
    )]
    [string]
    $LogName
    ,
    [Parameter(
        ParameterSetName = "manual",
        Mandatory
    )]
    [int]
    $EventRecordID
)

Begin
{
    $f = $MyInvocation.InvocationName
    Write-Verbose -Message "$f - START"
}

Process 
{
    $processBookmark = $null

    $bookmarkHash = @{
        Direction = ""
        Channel = ""
        RecordId = ""
        IsCurrent = $false
    }

    if ($PSBoundParameters.ContainsKey("Event"))
    {
        $processBookmark = $event.Bookmark
    }

    if ($PSBoundParameters.ContainsKey("Bookmark"))
    {
        $processBookmark = $Bookmark
    }

    if ($null -ne $processBookmark)
    {
        Write-Verbose "bybookmark"
        $bookMarkReflection = $processBookmark.GetType().GetProperties([System.Reflection.BindingFlags]"public,NonPublic,Instance")
        $value = $bookMarkReflection[0].GetValue($processBookmark)
        if ($null -ne $value)
        {
            $bookMarkXML = [xml]$value
            
            $bookmarkHash.Direction = $bookMarkXML.BookmarkList.Direction
            $bookmarkHash.Channel = $bookMarkXML.BookmarkList.Bookmark.Channel
            $bookmarkHash.RecordId = $bookMarkXML.BookmarkList.Bookmark.RecordId
            $bookmarkHash.IsCurrent = [bool]::Parse($bookMarkXML.BookmarkList.Bookmark.IsCurrent)
        }
        else 
        {
            Write-Error -Message "Unable to get value from Bookmark object, reflection returned null"
        }
    }    

    if ($PSBoundParameters.ContainsKey("LogName"))
    {
        $bookmarkHash.Direction = "backward"
        $bookmarkHash.Channel = $LogName
        $bookmarkHash.RecordId = $EventRecordID
        $bookmarkHash.IsCurrent = $true
    }

    if ([string]::IsNullOrEmpty($bookmarkHash.Direction) -eq $false)
    {
        $bookmarkHash | ConvertTo-Json
    }
}

End
{
    Write-Verbose -Message "$f - END"
}

}