$keyVaultName = "< >"
$secretName = "< >"
$organization = "< >"
$project = "< >"
$pipelineName = "< >"
$Secret = "< >"
$AppId = "< >"
$SubscriptionId = "< >"
$TenantId = "< >"

$SecuredPassword = ConvertTo-SecureString $Secret -AsPlainText -Force

$credential = New-Object -TypeName System.Management.Automation.PSCredential  -ArgumentList $AppId, $SecuredPassword
Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $credential
Set-AzContext -SubscriptionId $SubscriptionId


$kvSecret = Get-AzKeyVaultSecret -VaultName $keyvaultName -Name $secretName  -AsPlainText


Write-Output $kvSecret


$url = "https://dev.azure.com/$organization/$project/_apis/pipelines?api-version=6.1-preview.1& $filter=name eq '$pipelineName'"

$base64AuthInfo = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($kvSecret)"))

# Write-Output "Authorization header - $base64AuthInfo"
$headers = @{Authorization = "Basic $base64AuthInfo"}
$response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

$pipelineId = $response.value.id

Write-Output "Pipeline ID: $pipelineId"

$base64AuthInfo = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($kvSecret)"))


$url = "https://dev.azure.com/$organization/$project/_apis/pipelines/$pipelineId/runs?api-version=6.0-preview"

$body = @{
    resources = @{
        repositories = @{
            self = @{
                refName = "refs/heads/main"
            }
        }
    }
} | ConvertTo-Json

$response = Invoke-RestMethod -Method Post -Uri $url -Headers @{Authorization = "Basic $base64AuthInfo"} -ContentType "application/json" -Body $body


# Write-Output $response

$response1 = [PSCustomObject] @{
    
    status = "Pipeline triggered successfully."
}
# $response1 | ConvertTo-Json
Write-Output $response1
