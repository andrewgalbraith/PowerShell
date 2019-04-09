<#
.SYNOPSIS 
    NetApp and Hyper-V support report
.DESCRIPTION 
    Collects information from NetApp filers and Hyper-V hosts and outputs
    them in HTML format for easy viewing.
#>

# Define path for and create temporary html file for attaching to email.
$temp_html_file = Join-Path $PSSCriptRoot ("storage-report.html")
New-Item $temp_html_file -Force -ItemType File | Out-Null

# Specify Host Groups in VMM for locating Clusters
$rdc_host_groups = [ordered]@{
	"EMEA" = "GB-SiteA";
	"HK" = "HK";
	"India" = "IN";
	"US" = "US-SiteD"
}
# Specify prefix (e.g. country code) to use for locating filers in AD.
$rdc_filer_name_prefix = @{
    "EMEA" = "GB";
    "HK" = "HK";
    "India" = "IN";
    "US" = "US"
}

# Output content to the temporary HTML file
function Out-Content {
	param ([string]$content)
	$content | Out-File -FilePath $temp_html_file -Append
}

# Create a Graph.JS graph with the given data and labels
# NOTE: $name must be a valid JavaScript identifier
function Out-HTMLGraph {
    param($name,$button_id,$labels,$data)

   Out-Content @"
                        <canvas id="$name-Graph" width="800" height="400"></canvas>
                        <script>
	                        `$(function() {
                            "use strict";
		                    var $name`_Data =	{
                                "labels":  [
"@
    Out-Content $labels
    Out-Content @"

                                ],
                                "datasets":  [{
 							        label: "Volume Percentage Used",
							        fillColor: "rgba(0,220,0,0.5)",
							        strokeColor: "rgba(0,220,0,0.8)",
							        highlightFill: "rgba(0,220,0,0.75)",
							        highlightStroke: "rgba(0,220,0,1)",
							        data:  [ 
"@

    Out-Content $data
    Out-Content @"

                                           ]
                                    }]
		                        }
		
		                        `$("#$button_id").on("shown.bs.tab", function(e) {
			                        var ctx = `$("#$name-Graph").get(0).getContext("2d")
			                        new Chart(ctx).Bar($name`_Data, {
		                                scaleOverride : true,
                                        scaleSteps : 10,
                                        scaleStepWidth : 10,
                                        scaleStartValue : 0 	
		                            })
		                        });
	                        });
			
	                    </script>
"@
}


# Output the content for a specific RDC
function Out-RDCTab {
	param($Name)
    
    # If the current iteration is for the EMEA tabs, mark as active
    if($Name -eq "EMEA") { $active = "active" } 

	# Output RDC tabs
	Out-Content @"
			<div role="tabpanel" class="tab-pane $active" id="$name-Tab">
				<ul class="nav nav-tabs $active" id="$name-Tabs">
					<li role="presentation" class="$active"><a role="tab" data-toggle="tab" aria-controls="$name-Host-Status-Tab" id="$name-Host-Status-Button" href="#$name-Host-Status-Tab">Hyper-V Host Status</a></li>
					<li role="presentation"><a role="tab" data-toggle="tab" aria-controls="$name-Cluster-Disk-Tab" id="$name-ClusterDisk-Usage-Button" href="#$name-Cluster-Disk-Tab">Cluster Shared Volumes</a></li>
					<li role="presentation"><a role="tab" data-toggle="tab" aria-controls="$name-NetApp-Volumes-Tab" id="$name-NetApp-Volumes-Button" href="#$name-NetApp-Volumes-Tab">NetApp Volume Usage</a></li>
					<li role="presentation"><a role="tab" data-toggle="tab" aria-controls="$name-NetApp-Snapmirror-Tab" id="$name-NetApp-Snapmirror-Button" href="#$name-NetApp-Snapmirror-Tab">NetApp SnapMirror Status </a></li>
				</ul>
				<div class="tab-content">
"@
    
    # Generate the Hyper-V Host Status tab for this RDC
    Out-Content (Out-HyperVHostStatusHTML -RDC $Name)
    # Generate the CSV Status tab for this RDC
    Out-Content (Out-CSVStatusHTML -RDC $Name)
    # Generate the NetApp Volume Status tab for this RDC
    Out-Content (Get-NetAppVolumeStatus -RDC $Name)
    # Generate the NetApp SnapMirror Status tab for this RDC
    Out-Content (Out-NetAppSnapmirrorHTML -RDC $Name)

	# Output closing tags for RDC section
	Out-Content @"
		        </div>
            </div>

"@
}

# Collect Hyper-V hosts status for the specified RDC
function Out-HyperVHostStatusHTML {
	param($RDC)

	Out-Content @"
					<div role="tabpanel" class="tab-pane active" id="$RDC-Host-Status-Tab">
						<h2>Hyper-V Host Status</h2>
"@						

    $html = Get-SCVMHost |
			Where-Object { $_.VMHostGroup -like ("*\" + $rdc_host_groups[$RDC] + "*") } |
			Select-Object  @{Name="Name";Expression={$_.ComputerName}},
					@{Name="State";Expression={$_.ComputerState}},
					@{Name="Cluster Status";Expression={$_.ClusterNodeStatus}},
					@{Name="Available Memory (GB)";Expression={($_.AvailableMemory/1KB).toString("N2")}},
					@{Name="Host Group";Expression={$_.VMHostGroup}} |
			Sort-Object "Available Memory (GB)" -Descending | 
			ConvertTo-Html -Fragment |
				Foreach-Object { 
					switch -Regex ($_) {
						"\D0?[0-9]\.[0-9]{2}"
						{
							$_.replace("<tr>",'<tr class="danger">')
							break
						}
						"\D1[0-9]\.[0-9]{2}"
						{
							$_.replace("<tr>",'<tr class="warning">')
							break
						}
						default 
						{
							$_.replace("<table>", '<table class="table table-striped">')
							break
						}
					}
				}
	
	Out-Content $html.replace("<table>", '<table class="table table-striped">')
	Out-Content @"
					</div>
"@
}

# Collect the Volume information from the NetApp filers for the specified RDC
function Get-NetAppVolumeStatus {
    param($RDC)
    
	Out-Content @"
					<div role="tabpanel" class="tab-pane" id="$RDC-NetApp-Volumes-Tab">
						<h2>Netapp Volume Status</h2>
"@	
    
    $filter_name = $rdc_filer_name_prefix[$RDC] + "FILER*"
    Get-ADComputer -Filter { samAccountName -like $filter_name -and Enabled -eq $true } | 
	    Select-Object -ExpandProperty name | 
        ForEach-Object {
			Out-Content @"
					<h3>$_</h3>
"@	

			Connect-NaController $_ | Out-Null;  

			$data = Get-NaVol |
				Select-Object Name,State,
					@{Name="Used (%)";Expression={($_.Used/100).toString("P0")}},
					@{Name="Available (GB)";Expression={($_.Available/1GB).toString("N0")}},
					@{Name="Total Size (GB)";Expression={($_.TotalSize/1GB).toString("N0")}},Aggregate |
				Sort-Object "Used (%)" -Descending

			Out-HTMLGraph -name ($RDC + "_NetAppVolumes" + $_) `
				-button_id ($RDC + "-NetApp-Volumes-Button") `
				-labels ('"' + (($data | Foreach-Object -MemberName "Name") -join '","') + '"') `
				-data (($data | Foreach-Object { $_."Used (%)".replace("%","") }) -join ',')

			$html = $data | ConvertTo-HTML -Fragment |
				Foreach-Object { 
					switch -Regex ($_) {
						"(9[0-9]|100).%"
						{
							$_.replace("<tr>",'<tr class="danger">')
							break
						}
						"(8[0-9]|100).%"
						{
							$_.replace("<tr>",'<tr class="warning">')
							break
						}
						default 
						{
							$_.replace("<table>", '<table class="table table-striped">')
							break
						}
					}
				}
			Out-Content $html.replace("<table>", '<table class="table table-striped">')
        }

    Out-Content @"
					</div>
"@
   
}

# Collect the NetApp SnapMirror status (if used) for the specified RDC
function Out-NetAppSnapmirrorHTML {
    param($RDC)

	Out-Content @"
					<div role="tabpanel" class="tab-pane" id="$RDC-NetApp-Snapmirror-Tab">
						<h2>Netapp SnapMirror Status</h2>
"@	

    $filter_name = $rdc_filer_name_prefix[$RDC] + "FILER*"
    Get-ADComputer -Filter { samAccountName -like $filter_name -and Enabled -eq $true } | 
	    Select-Object -ExpandProperty name |
        ForEach-Object{
            Connect-NaController $_ | Out-Null; 
            
            $html = Get-NaSnapmirror | Where-Object State -eq "source" | 
                Select-Object Source,Destination,Status,
                    @{Name="Lag Time";Expression={[timespan]::fromseconds($_.lagtime)}} |
                ConvertTo-Html -Fragment |
				Foreach-Object {
					switch -Regex ($_) {
						"[0-9][0-9]:[1-9][0-9]:[0-9][0-9]"
						{
							$_.replace("<tr>",'<tr class="warning">')
							break
						}
						"[0-9][1-9]:[0-9][0-9]:[0-9][0-9]"
						{
							$_.replace("<tr>",'<tr class="danger">')
							break
						}
						default 
						{
							$_.replace("<table>", '<table class="table table-striped">')
							break
						}
					}
				}

            if($html) 
            {
                Out-Content $html.replace("<table>", '<table class="table table-striped">')
            }
            else
            {
                Out-Content "Snapmirror not in use"
            }
            
        }

    Out-Content @"
					</div>
"@

}

# Collect the Cluster Shared Volume status for the specified RDC
function Out-CSVStatusHTML {
    param($RDC)
    
    Out-Content @"
					<div role="tabpanel" class="tab-pane" id="$RDC-Cluster-Disk-Tab">
						<h2>Cluster Shared Volumes</h2>                   
"@	

    $data = Get-SCStorageDisk |
        Where-Object { $_.ClusterDisk -match "hv.*|clu.*" -and $_.ClusterDisk.OwnerNode -like ($rdc_filer_name_prefix[$RDC] + "*") } |
        Select-Object @{Name="Cluster Disk";Expression={$_.ClusterDisk.Name}},
            @{Name="Owner Node";Expression={$_.ClusterDisk.OwnerNode}},
            @{Name="Percent Used";Expression={"{0:P0}" -f (1-($_.AvailableCapacity/$_.Capacity))}},
            @{Name="Free Space (GB)";Expression={"{0:N2}" -f ($_.AvailableCapacity/1GB)}},
            @{Name="Capacity (TB)";Expression={"{0:N2}" -f ($_.Capacity/1TB)}} -Unique |
		Sort-Object "Percent Used" -Descending

    Out-HTMLGraph -name ($RDC + "_ClusterDisk") `
        -button_id ($RDC + "-ClusterDisk-Usage-Button") `
        -labels ('"' + (($data | Foreach-Object -MemberName "Cluster Disk") -join '","') + '"') `
        -data (($data | Foreach-Object { $_."Percent Used".replace("%","") }) -join ',')
    
    $html = $data | 
		ConvertTo-Html -Fragment |
		Foreach-Object { 
			switch -Regex ($_) {
				"(9[0-9]|100).%"
				{
					$_.replace("<tr>",'<tr class="danger">')
					break
				}
				"(8[0-9]|100).%"
				{
					$_.replace("<tr>",'<tr class="warning">')
					break
				}
				default 
				{
					$_.replace("<table>", '<table class="table table-striped">')
					break
				}
			}
		}
    Out-Content $html
    Out-Content @"
					</div>
"@

}

# Output Header and Menu
Out-Content @'
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<title>Storage Report</title>
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<meta name="description" content="">
	<link rel="shortcut icon" href="favicon.ico">

	<!-- Twitter Bootstrap -->
    <!-- Latest compiled and minified CSS -->
	<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css">

	<!-- Optional theme -->
	<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap-theme.min.css">

	<!--[if lt IE 9]>
			<script src="http://cdnjs.cloudflare.com/ajax/libs/html5shiv/r29/html5.js"></script>
	<![endif]-->
	<style>
		#contoso-logo, #contoso-logo-zh {
			height: 36px;
			width: 126px;
			margin-top: 5px;
			margin-right: 10px;
			display: block;
			float: left; 
			background-image: url(http://static.contoso.com/images/logo.png);
			background-size: 126px 65px;
		}
	</style>
</head>
<body>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/1.0.2/Chart.min.js"></script>
	<script src="https://code.jquery.com/jquery-2.1.4.min.js"></script>
	<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js"></script>
	<script src=https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.0.0-alpha/js/umd/tab.js></script>
	
    <style>
	<!--
		body { padding-top: 70px; }
	-->
	</style>
	<nav class="navbar navbar-default navbar-fixed-top">
		<div class="container-fluid">
			<!-- Brand and toggle get grouped for better mobile display -->
			<div class="navbar-header">
				<button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1" aria-expanded="false">
					<span class="sr-only">Toggle navigation</span>
					<span class="icon-bar"></span>
					<span class="icon-bar"></span>
					<span class="icon-bar"></span>
				</button>
				<a id="contoso-logo"></a>
				<a class="navbar-brand" href="#">Storage Report</a>
			</div>

			<!-- Collect the nav links, forms, and other content for toggling -->
			<div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1">
				<ul class="nav navbar-nav" role="tablist" id="RDCTabs">
					<li role="presentation" class="active"><a role="tab" data-toggle="tab" aria-controls="EMEA-Tab" href="#EMEA-Tab">EMEA</a></li>
					<li role="presentation"><a role="tab" data-toggle="tab" aria-controls="HK-Tab" href="#HK-Tab">Hong Kong</a></li>
					<li role="presentation"><a role="tab" data-toggle="tab" aria-controls="India-Tab" href="#India-Tab">India</a></li>
					<li role="presentation"><a role="tab" data-toggle="tab" aria-controls="US-Tab" href="#US-Tab">United States</a></li>
					<!--<li role="presentation"><a role="tab" data-toggle="tab" aria-controls="Other-Tab" href="#Other-Tab">Other</a></li>-->
				</ul>
			</div><!-- /.navbar-collapse -->
		</div><!-- /.container-fluid -->
	</nav>
    <div class="container-fluid">
		<div class="tab-content">   
'@

# Display info for each RDC
$rdc_host_groups.Keys | ForEach-Object {
    Out-RDCTab -Name $_
}

# Output HTML footer
Out-Content @'
    </div>
</div>
</body>
</html>
'@

$recipients = "ops.shift@contoso.com","ops_storage_and_virtualisation_team@contoso.com"
# $recipients = "it.admin@contoso.com"

# Email report to recipients
Send-MailMessage -To $recipients `
    -CC "it.admin@contoso.com" `
    -Subject "OPS NetApp and Hyper-V report" `
    -Body "Please find attached the latest NetApp and Hyper-V report. It must be opened in the browser to display correctly." `
    -Attachments $temp_html_file `
    -From "ops.automation@contoso.com" `
    -SMTPServer (Get-ConfigItem Defaults.SMTP.ServerAddress) `
    -Port 25
