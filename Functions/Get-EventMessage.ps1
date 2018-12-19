function Get-EventMessage
{
[cmdletbinding()]
Param(
    [parameter(ValueFromPipeline)]
    [System.Diagnostics.Eventing.Reader.EventLogRecord[]]
    $Event
)
Begin
{
    $f = $MyInvocation.InvocationName
    #Write-Verbose -Message "$f - START"
}

Process 
{
    foreach ($e in $Event)
    {
        $sb = [System.Text.StringBuilder]::new()
        $xml = [xml]($e.ToXml())
        foreach ($prop in $xml.Event.EventData.Data)
        {
            if (-not ([string]::IsNullOrEmpty($prop.Name)))
            {
                $null = $sb.Append($prop.Name)
                $null = $sb.Append(": ")
                $null = $sb.AppendLine($prop.'#text') 
            }
            else
            {
                if ($prop -is [string])
                {                   
                    $null = $sb.AppendLine($prop)
                }
                else 
                {
                    $null = $sb.AppendLine($prop.'#text')
                }
            }
                       
        }
        $e | Add-Member -MemberType NoteProperty -Name Message -Value $sb.ToString() -PassThru -Force
    }
}
}