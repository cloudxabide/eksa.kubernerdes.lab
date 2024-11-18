<!-- This file is most likely not a good idea, or necessarilly safe.  This is intended *only* for my lab environment. -->

<HTML>
<HEAD>
<TITLE> Kubernerdes Services | &#169 2024 </TITLE>
<meta http-equiv="refresh" content="10; url=./services.php">
</HEAD>
<BODY>
<TABLE>
<TH colspan=3> Kubernerdes Container Services and Endpoints</TH>
<TR><TD><font color=blue>Namespace</TD><TD><font color=blue>Service</TD><TD><font color=blue>Endpoint</TD></TR>

<?php
$i=0;
# You will need to copy the correct KUBECONFIG to the following location
$kubeconfig="/var/www/html/kubernerdes-eksa-eks-a-cluster.kubeconfig";
putenv ("KUBECONFIG=$kubeconfig");

## A few different renditions of the syntax and formatting
#$k_output = shell_exec('/usr/local/bin/kubectl get svc -A | grep LoadBalancer | awk \'{ split($6, ports, ":"); print $1 " | " $2 " | http://" $5":"ports[1] }\' ');
#$k_output = shell_exec('/usr/local/bin/kubectl get svc -A | grep LoadBalancer | awk \'{ split($6, ports, ":"); print $1 " | " $2 " | <A HREF=http://" $5":" ports[1] ">" $5":" ports[1] "</A>" }\' ');
#$k_output = shell_exec('/usr/local/bin/kubectl get svc -A | grep LoadBalancer | awk \'{ split($6, ports, ":"); print "<TR><TD>" $1 "</TD> <TD>" $2 "</TD>  <TD><A HREF=http://" $5":" ports[1] ">" $5":" ports[1] "</A></TD></TR>" }\' ');
$k_output = shell_exec('/usr/local/bin/kubectl get svc -A | grep LoadBalancer | awk \'{ split($6, ports, ":"); print "<TR><TD>" $1 "</TD> <TD>" $2 "</TD>  <TD><A HREF=http://" $5":" ports[1] " target=\""$2"\" >" $5":" ports[1] "</A></TD></TR>" }\' ');

echo "<pre>$k_output</pre>";

?>

<BR> <BR>

</TABLE>
<TABLE>
<TH colspan=3> Kubernerdes.Lab Infrastructure Services and Endpoints</TH>
<TR><TD><font color=blue>Service</TD> <TD><font color=blue>Endpoint</TD></TR>
<TR> <TD>vSphere Console</TD> <TD><A HREF="https://10.10.12.30/" target="vsphere">https://10.10.12.30/</A></TD> </TR>
<TR> <TD>ESXi Console (vmw-esx-01)</TD> <TD><A HREF="http://10.10.12.31" target="esxi1">http://10.10.12.31</A></TD> </TR>

<TR> <TD>vSphere Console</TD> <TD>https://10.10.12.30/</TD> </TR>
<TR> <TD>ESXi Console (vmw-esx-01)</TD> <TD>http://10.10.12.31</TD> </TR>
<TR> <TD></TD> <TD></TD> </TR>
</TABLE>

</BODY>
</HTML>
