New-UDPage -Id 'page_twitter' -Url "/twitter/:project_id" -Endpoint {

    Param($project_id)

    If (!($project_id)) { Invoke-UDRedirect -Url '/' }

    [System.Collections.ArrayList]$Projects = @()
    Get-Content "${global:DataPath}/_projects.json" -EA 0 | ConvertFrom-Json | ForEach-Object { [void]$Projects.Add($_) }
    $Project = $Projects.Where({$_.project_id -eq $project_id})

    If (!($Project)) { Break }

    New-UDCard -Title $Project.project_name -Text $Project.project_filter

    [object[]]$TwitterUsers = Get-Content "${global:DataPath}/${project_id}_twitterusers.json" | ConvertFrom-Json
    [object[]]$TwitterStatuses = Get-Content "${global:DataPath}/${project_id}_twitterstatuses.json" | ConvertFrom-Json

    New-UDRow -Endpoint {
        New-UDLayout -Columns 6 -Content {

            New-UDCard -Title "Tweets" -Id "total_tweets" -Content { 
                [string]::Format('{0:N0}',$TwitterStatuses.Count) 
            } -Watermark twitter 

            New-UDCard -Title "Users" -Id "total_users" -Content { 
                [string]::Format('{0:N0}',$TwitterUsers.Count) 
            } -Watermark user 

            New-UDCard -Title "Timespan" -Id "total_timespan" -Content { 

                Try {
                    $MeasuredObject = $TwitterStatuses | Measure-Object -Property created_at -Minimum -Maximum
                    $TimeSpan = New-TimeSpan -Start $MeasuredObject.Minimum -End $MeasuredObject.Maximum
                    $d = $TimeSpan.Days; $h = $TimeSpan.Hours; $m = $TimeSpan.Minutes; $as = "","s"
                    $(
                    if ($d) { "{0} day{1}" -f $d, $as[$d -gt 1] }
                    if ($h) { "{0} hour{1}" -f $h, $as[$h -gt 1] }
                    if ($m) { "{0} minute{1}" -f $m, $as[$m -gt 1] }
                    # "{0}.{1}s" -f $TimeSpan.Seconds, $TimeSpan.Milliseconds.ToString('D3')
                    ) -join ", "
                } Catch { 0 }

            } -Watermark calendar 
            
            New-UDCard -Title "Impressions" -Id "total_impressions" -Content { 
                $total_impressions = ($TwitterUsers.followers_count | Measure-Object -Sum).Sum
                [string]::Format('{0:N0}',$total_impressions) 
            } -Watermark chart_line

            New-UDCard -Title "Retweets" -Id "total_retweets" -Content { 
                $total_retweets = ($TwitterStatuses.retweet_count | Measure-Object -Sum).Sum
                [string]::Format('{0:N0}',$total_retweets) 
            } -Watermark handshake

            New-UDCard -Title "Liked" -Id "total_liked" -Content { 
                $total_liked = ($TwitterStatuses.favorite_count | Measure-Object -Sum).Sum
                [string]::Format('{0:N0}',$total_liked) 
            } -Watermark thumbs_up

        }
    }

    New-UDRow -Endpoint {
        New-UDLayout -Columns 4 -Content {
            New-UDChart -Type 'HorizontalBar' -Title 'Top Influencer' -Endpoint {
                $Data = $TwitterUsers | Sort-Object followers_count -Descending | Select-Object * -First 15
                ForEach ($TwitterUser in $Data) { 
                    $tweet_count = $TwitterStatuses.Where({$_.user_id -eq $TwitterUser.id}).Count
                    $TwitterUser | Add-Member -MemberType NoteProperty -Name 'tweet_count' -Value $tweet_count
                }
                $Data | Out-UDChartData -LabelProperty screen_name -DataSet @(
                    New-UdChartDataset -DataProperty "followers_count" -Label "Followers" -BackgroundColor $global:ChartPalette[7]
                    New-UdChartDataset -DataProperty "friends_count" -Label "Following" -BackgroundColor $global:ChartPalette[6]
                    New-UdChartDataset -DataProperty "tweet_count" -Label "Tweets" -BackgroundColor $global:ChartPalette[5]
                )
            }
            New-UDChart -Type 'HorizontalBar' -Title 'Top Mentions' -Endpoint {
                $Data = $TwitterStatuses.entities.user_mentions.screen_name | Group-Object -NoElement | Sort-Object Count -Descending | Select-Object * -First 15
                $Data | Out-UDChartData -LabelProperty Name -DataProperty Count -BackgroundColor $global:ChartPalette[7]
            } -Options @{ legend = @{ display = $false } }
            New-UDChart -Type 'HorizontalBar' -Title 'Top Hastags' -Endpoint {
                $Data = $TwitterStatuses.entities.hashtags.text | Group-Object -NoElement | Sort-Object Count -Descending | Select-Object * -First 15
                $Data | Out-UDChartData -LabelProperty Name -DataProperty Count -BackgroundColor $global:ChartPalette[7]
            } -Options @{ legend = @{ display = $false } }
            New-UDChart -Type 'HorizontalBar' -Title 'Top Url' -Endpoint {
                $Data = $TwitterStatuses.entities.urls | Group-Object -Property expanded_url | Sort-Object Count -Descending | Select-Object *, @{n='display_url'; e={ $_.Group[0].display_url }} -First 15
                $Data | Out-UDChartData -LabelProperty display_url -DataProperty Count -BackgroundColor $global:ChartPalette[7]
            } -Options @{ legend = @{ display = $false } }
        }
        New-UDLayout -Columns 4 -Content {
            New-UDChart -Type 'HorizontalBar' -Title 'Top Retweeted' -Endpoint {
                $Data = $TwitterStatuses.retweeted_status.user.screen_name | Group-Object -NoElement | Sort-Object Count -Descending | Select-Object * -First 15
                $Data | Out-UDChartData -LabelProperty Name -DataProperty Count -BackgroundColor $global:ChartPalette[7]
            } -Options @{ legend = @{ display = $false } }
            New-UDChart -Type 'HorizontalBar' -Title 'Top RepliedTo' -Endpoint {
                $Data = $TwitterStatuses.in_reply_to_screen_name | Group-Object -NoElement | Sort-Object Count -Descending | Select-Object * -First 15
                $Data | Out-UDChartData -LabelProperty Name -DataProperty Count -BackgroundColor $global:ChartPalette[7]
            } -Options @{ legend = @{ display = $false } }
            New-UDChart -Type 'HorizontalBar' -Title 'Top Device' -Endpoint {
                $Data = $TwitterStatuses | % { ($_.source -Split ">|<")[-3] } | Group-Object -NoElement | Sort-Object Count -Descending | Select-Object * -First 15
                $Data | Out-UDChartData -LabelProperty Name -DataProperty Count -BackgroundColor $global:ChartPalette[7]
            } -Options @{ legend = @{ display = $false } }
            New-UDChart -Type 'HorizontalBar' -Title 'Top Language' -Endpoint {
                $Data = $TwitterStatuses.lang | Group-Object -NoElement | Sort-Object Count -Descending | Select-Object * -First 15
                $Data | Out-UDChartData -LabelProperty Name -DataProperty Count -BackgroundColor $global:ChartPalette[7]
            } -Options @{ legend = @{ display = $false } }
        }
    }
}