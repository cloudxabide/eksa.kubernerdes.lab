<?php

/**
 * @author      James Radtke <cloudxabide@gmail.com>
 * @version     1.0.0
 * @since       2025-01-29
 * @package     serviceListPhp
 * @license     MIT
 *
 * @description:  This script will display all the Kubernetes services exposed as 
 *                  type:LoadBalancer
 *
 * Usage:         place this script in /var/www/html and your kubeconfig in /var/www
 *
 * Dependencies:  http server, php
 * 
 * Note/Warning:  This script is just intended for lab usage.  I would NOT do this on a production cluster,
 *                  or in an environment with sensitive data. 
 *                Also, I am not nec. a "coder".  Use at your own risk.  I do ;-)
 *
 * Change log:
 * 2025-01-29 - v1.0.0: Initial release
 */

// PHP code starts here

$kubeconfig="/var/www/kubeconfig";
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
echo "<HTML><HEAD><TITLE>Kubernerdes Services | &#169 2025 </TITLE><meta http-equiv=\"refresh\" content=\"10; url=./services.php\"></HEAD> \n";
echo "<BODY> \n";
echo "<TABLE border=1><TH COLSPAN=4>Kubernerdes Services and Endpoints </TH> \n";
// Print the parsed results
    echo "<TR>";
    echo "<TD>service name</TD>";
    echo "<TD>IP Address</TD> ";
    echo "<TD>port</TD>"; 
    echo "<TD>URL</TD>"; 
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
<BR>
<TABLE BORDER=1>
<TH colspan=3> Kubernerdes.Lab Infrastructure Services and Endpoints</TH>
<TR><TD><font color=blue>Service</TD> <TD><font color=blue>Endpoint</TD></TR>
<TR> <TD>vSphere Console</TD> <TD><A HREF="https://10.10.12.30/">https://10.10.12.30/</A></TD> </TR>
<TR> <TD>ESXi Console (vmw-esx-01)</TD> <TD><A HREF="http://10.10.12.31">http://10.10.12.31</A></TD> </TR>
<TR> <TD>
</BODY>
</HTML>
