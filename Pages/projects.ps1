New-UDPage -Id 'page_projects' -Name 'projects' -DefaultHomePage -Endpoint {

    New-UDButton -Text "New Project" -OnClick {
        Show-UDModal -Content {
            New-UDInput -Title "New Project" -Id 'new_project' -Content {

                New-UDInputField -Type "textbox" -Name 'Name'
                New-UDInputField -Type "select" -Name 'Endpoint' -Values @('Search Tweets', 'User Timeline') -DefaultValue 'Search Tweets'
                New-UDInputField -Type "textbox" -Name 'Filter'
                New-UDInputField -Type "select" -Name 'Count' -Values @('15', '50', '100', '200', '500', '1000') -DefaultValue '100'
                
            } -Endpoint {
                param($Name, $Endpoint, $Filter, $Count)
            
                If (($Name) -and ($Filter)) {
            
                    [System.Collections.ArrayList]$Projects = @()
                    Get-Content "${global:DataPath}/_projects.json" -EA 0 | ConvertFrom-Json | ForEach-Object { [void]$Projects.Add($_) }

                    $project_id = [guid]::NewGuid().Guid -Replace "-"
                    $Project = [PSCustomObject]@{
                        project_id = $project_id
                        project_name = $Name
                        project_type = 'TwitterSearch'
                        project_filter = $Filter
                    }
                    [void]$Projects.Add($Project)
                    $Projects | ConvertTo-Json | Set-Content -Path "${global:DataPath}/_projects.json"

                    Import-Module PSTwitterAPI
                    Set-TwitterOAuthSettings @global:TwitterOAuthSettings
                    
                    [object[]]$Results = Switch ($Endpoint) {
                        'Search Tweets' { Get-TwitterSearch_Tweets -q $Filter -count $Count }
                        'User Timeline' { Get-TwitterStatuses_UserTimeline -screen_name $Filter -count $Count }
                    }
                    
                    Show-UDToast -Message "$($Results.Count) tweets."

                    If ($Results.Count) {
            
                        [object[]]$TwitterUsers = $Results.user | Group-Object id | ForEach-Object { $_.Group | Select-Object -First 1 } | Select-Object @{n='project_id';e={$project_id}}, *
                        [object[]]$TwitterStatuses = $Results | Select-Object @{n='project_id';e={$project_id}}, @{n='user_id';e={$_.user.id}}, * -Exclude user

                        $TwitterUsers | ForEach-Object { $_.created_at = (Get-Date -Date ("{0}-{1}-{2} {3}" -f ($_.created_at -Split "\s")[5,1,2,3])).ToString() }
                        $TwitterStatuses | ForEach-Object { $_.created_at = (Get-Date -Date ("{0}-{1}-{2} {3}" -f ($_.created_at -Split "\s")[5,1,2,3])).ToString() }

                        $TwitterUsers | ConvertTo-Json -Depth 5 | Set-Content -Path "${global:DataPath}/${project_id}_twitterusers.json"
                        $TwitterStatuses | ConvertTo-Json -Depth 5 | Set-Content -Path "${global:DataPath}/${project_id}_twitterstatuses.json"

                    }
            
                    Sync-UDElement -Id 'grid_projects'

                }

                Hide-UDModal

            }
            
        }
    }

    $headers = 'name', 'type', 'filter', '-'
    $Properties = 'project_name', 'project_type', 'project_filter', 'link'

    New-UDGrid -Id 'grid_projects' -Title 'Projects' -Headers $Headers -Properties $Properties -Endpoint {
        
        [System.Collections.ArrayList]$Projects = @()
        Get-Content "${global:DataPath}/_projects.json" -EA 0 | ConvertFrom-Json | ForEach-Object { [void]$Projects.Add($_) }

        $Projects | ForEach-Object {
            $UDLink = New-UDLink -Text 'Open' -Url "/twitter/$($_.project_id)"
            $_ | Add-Member -MemberType NoteProperty -Name 'link' -Value $UDLink -Force
        }

        $Projects | Out-UDGridData -TotalItems $Projects.Count

    }

}