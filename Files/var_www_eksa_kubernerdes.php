<?php

/**
 * @author      James Radtke <cloudxabide@gmail.com>
 * @version     1.0.1
 * @since       2025-04-20
 * @package     
 * @license     MIT
 *
 * @description:  This script was originally created to display the services exposed with 
 *                  type:LoadBalancer
 *                I then added top node and top pods
 *                Then, I opted to scan for available *.kubeconfig files and make them a selection
 *
 * Usage:         place this script in /var/www/html and your *.kubeconfig(s) in /var/www/.kube/
 *
 * Dependencies:  http server, php, php-yaml
 *                /var/www/html/, /var/www/.kube/ directory
 * 
 * Note/Warning:  This script is just intended for lab usage.  I would NOT do this on a 
 *                  production cluster, or in an environment with sensitive data. 
 *                Also, I am not nec. a "coder".  Use at your own risk.  I know that I do ;-)
 *
 * Change log:
 * 2025-04-20 - v1.0.1: All kinds of updates.  Added a section to allow selection of 
 *                        cluster (based on *.kubeconfig files)
 * 2025-01-29 - v1.0.0: Initial release
 */

$verboseTroubleshooting=0;
?>
<HTML>
<HEAD>
  <TITLE>Kubernerdes Clusters and Services | &#169 2025 </TITLE>
  <!-- <meta http-equiv="refresh" content="3" -->
  <LINK REL="stylesheet" HREF="./styles.css" TYPE="text/css">
<?php
// Directory containing kubeconfig files
$kubeconfig_directory = '/var/www/.kube';

// Holy carp this was tough to figure out... I had *assumed* that if a URL var was present and valid, that it was "set" 
//        - you have to implicitly set the var based on the $_GET call, apparently
if (isset($_GET['kubeconfig_filename_basename'])) {
  $kubeconfig_filename_basename = $_GET['kubeconfig_filename_basename'];
  $kubeconfig = $kubeconfig_directory . "/" . $kubeconfig_filename_basename;
  // echo "kubeconfig_filename_basename set to: $kubeconfig_filename_basename \n<BR>";
} else {
  $kubeconfig_filename_basename = "kubeconfig";
  $kubeconfig = $kubeconfig_directory . "/" . $kubeconfig_filename_basename;
  echo "kubeconfig_filename_basename was not set. Defaulting to \"kubeconfig\" <BR> \n";
}
echo "  <META http-equiv=\"refresh\" content=\"3; url=./kubernerdes.php?kubeconfig_filename_basename=$kubeconfig_filename_basename\">";
?> 
</HEAD>
<BODY>

<TABLE BORDER=1>
<TH colspan=2>Kubernerdes Clusters</TH>

<?php
// Find all files ending with .kubeconfig
$kubeconfig_files_fullpath = glob($kubeconfig_directory . '/*.kubeconfig');

// Cycle through all the *.kubeconfig files discovered (for-loop)
foreach ($kubeconfig_files_fullpath as $kubeconfig_file_fullpath) {
  $clusterName = '';
  $kubeconfig_filename_basename = basename($kubeconfig_file_fullpath);

  // Read the kubeconfig file
  $content = file_get_contents($kubeconfig_file_fullpath);
  if ($content === false) {
    // Could not read file, skip
    continue;
  }

  // Try to parse YAML using yaml_parse if available
  if (function_exists('yaml_parse')) {
    $parsed = @yaml_parse($content);
    if ($parsed && isset($parsed['clusters'][0]['name'])) {
      $clusterName = $parsed['clusters'][0]['name'];
    }
  } else {
    // Fallback: parse cluster name manually (very basic YAML parsing)
    // Look for the first occurrence of "name:" after a "clusters:" section
    $lines = explode("\n", $content);
    $inClusters = false;
    foreach ($lines as $line) {
      $trim = trim($line);
      if (strpos($trim, 'clusters:') === 0) {
        $inClusters = true;
        continue;
      }
      if ($inClusters && preg_match('/name:\s*(.+)/', $trim, $matches)) {
        $clusterName = $matches[1];
        break;
      }
    }
  }

  // ****************************
  if ($verboseTroubleshooting != 0) {
  // Troubleshooting
  echo "kubeconfig_file_fullpath $kubeconfig_file_fullpath \n <BR>";
  echo "kubeconfig_filename_basename $kubeconfig_filename_basename \n <BR>";
  echo "clusterName $clusterName \n <BR>";
  echo "<BR>";
  }
  // ****************************


  // Print the filename and cluster name
  echo "<TR>\n";
  echo "<TD> <A HREF=\"./kubernerdes.php?kubeconfig_filename_basename=" . $kubeconfig_filename_basename . "\">" . $clusterName . "</A></TD> <TD>" . basename($kubeconfig_filename_basename) . "</TD>";  
  echo "</TR>\n";

}
// End of cycle (for-loop)
?>
</TABLE>

<!-- INCLUDE THE SERVICES OVERVIEW HERE -->
<?php
echo "<BR>Fun starts here " . $kubeconfig . "<BR>\n";
putenv ("KUBECONFIG=$kubeconfig");
$services_output = shell_exec('kubectl get services -A -o jsonpath=\'{range .items[?(@.spec.type=="LoadBalancer")]}{.metadata.name}{"\t"}{.status.loadBalancer.ingress[0].ip}{"\t"}{.spec.ports[0].port}{"\n"}{end}\'');

$lines = explode("\n", $services_output);

// Initialize an array to store the parsed results
$parsed_hosts = array();

// Loop through each line
foreach ($lines as $line) {
    // Trim whitespace from the beginning and end of the line
    $line = trim($line);

    // Skip empty lines and comments
    if (empty($line) || $line[0] === '#') {
        continue;
    }

    // Split the line into parts
    $parts = preg_split('/\s+/', $line);

    // Ensure we have at least three parts (service, IP and port)
    if (count($parts) >= 3) {
        $service = $parts[0];
        $ip = $parts[1];
        $port = $parts[2];

        // Store the parsed values in the array
        $parsed_hosts[] = array(
            'service' => $service,
            'ip' => $ip,
            'port' => $port
        );
    }
}

echo "<TABLE border=1><TH COLSPAN=4>Kubernerdes Services and Endpoints </TH> \n";
// Print the parsed results
    echo "<TR>";
    echo "<TD><b>service name</TD>";
    echo "<TD><b>IP Address</TD> ";
    echo "<TD><b>port</TD>";
    echo "<TD><b>URL</TD>";
    echo "</TR>\n";

foreach ($parsed_hosts as $index => $host) {
    //echo "Entry " . ($index + 1) . ":\n";
    echo "<TR>";
    echo "<TD>" . $host['service'] . "</TD> ";
    echo "<TD>" . $host['ip'] . "</TD> ";
    echo "<TD>" . $host['port'] . "</TD> ";
    if ($host['port'] == '443') {
      $http_prefix="https";
    } else {
      $http_prefix="http";
    }
    // This next line would be for 80/443 (HTTP/HTTPS) URLs only
    //echo "<TD><A HREF=" . $http_prefix . "://" . $host['ip'] . "/  target=pane" . $index . ">" . $http_prefix . "://" . $host['ip'] . " </A></TD>" ;
    // I discovered I had to include the port number in the URL for non-standard ports (like 3000 for grafana)
    echo "<TD><A HREF=" . $http_prefix . "://" . $host['ip'] . ":" . $host['port'] . " target=pane" . $index . ">" . $http_prefix . "://" . $host['ip'] . ":" . $host['port'] . " </A></TD>" ;
    echo "</TR>\n";
}

echo "<TR><TD colspan=4><pre> \n";
$k_output = shell_exec('/usr/local/bin/kubectl top nodes');
echo "$k_output";
echo "</pre></TD></TR> \n";

echo "<TR><TD colspan=4> <pre> \n";
$k_output = shell_exec('/usr/local/bin/kubectl top pods -A');
echo "$k_output";
echo "</pre></TD></TR>";
echo "</TABLE>";
?>

</BODY>
</HTML>
