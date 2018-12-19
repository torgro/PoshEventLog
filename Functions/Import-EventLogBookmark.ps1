function Import-EventLogBookmark
{
[cmdletbinding()]
Param(
    [Parameter(ValueFromPipelineByPropertyName)]
    [Alias('Channel')]
    [string]
    $LogName
    ,
    [Parameter(ValueFromPipelineByPropertyName)]
    [ValidateSet("backward","forward")]
    [string]
    $Direction
    ,
    [Parameter(ValueFromPipelineByPropertyName)]
    [bool]
    $IsCurrent
    ,
    [Parameter(ValueFromPipelineByPropertyName)]
    [int]
    [Alias('RecordId')]
    $EventRecordId
)
Begin
{
    $f = $MyInvocation.InvocationName
    Write-Verbose -Message "$f - START"
}

Process 
{
    $bookMarkXML = [System.Xml.XmlDocument]::new()
    $list = $bookMarkXML.CreateElement('BookmarkList')
    $null = $list.SetAttribute('Direction', $Direction)
    $null = $bookMarkXML.AppendChild($list)

    $bookmark = $bookMarkXML.CreateElement('Bookmark')
    $null = $bookmark.SetAttribute('Channel', $LogName)
    $null = $bookmark.SetAttribute('RecordId', $EventRecordId)
    $null = $bookmark.SetAttribute('IsCurrent', $IsCurrent)

    $null = $bookMarkXML.BookmarkList.AppendChild($bookmark)
    $constructors = [System.Diagnostics.Eventing.Reader.EventBookmark].UnderlyingSystemType.GetConstructors([System.Reflection.BindingFlags]"public,NonPublic,Instance")

    if ($null -eq $constructors)
    {
        Write-Error -Message "Unable to create Bookmark object, reflection returned null"
        break
    }
    
    $ctor = $constructors | Select-Object -First 1

    $bookmarkObject = [System.Diagnostics.Eventing.Reader.EventBookmark]$ctor.Invoke($bookMarkXML.OuterXml)

    $bookmarkObject
}

End
{
    Write-Verbose -Message "$f - END"
}

}