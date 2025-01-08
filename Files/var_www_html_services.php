<!-- This file is most likely not a good idea, or necessarilly safe.  This is intended *only* for my lab environment. -->

<HEAD>
<TITLE> Kubernerdes Services | &#169 2024 </TITLE>
<meta http-equiv="refresh" content="10; url=./services.php">
</HEAD>
<BODY>
<TABLE BORDER=1>
<TH colspan=3> Kubernerdes Services and Endpoints</TH>
<TR><TD><font color=blue>Namespace</TD><TD><font color=blue>Service</TD><TD><font color=blue>Endpoint</TD></TR>

<?php
$kubeconfig="/var/www/html/kubernerdes-eksa-eks-a-cluster.kubeconfig";
putenv ("KUBECONFIG=$kubeconfig");

#$k_output = shell_exec('/usr/local/bin/kubectl get svc -A | grep LoadBalancer | awk \'{ split($6, ports, ":"); print $1 " | " $2 " | http://" $5":"ports[1] }\' ');
#$k_output = shell_exec('/usr/local/bin/kubectl get svc -A | grep LoadBalancer | awk \'{ split($6, ports, ":"); print $1 " | " $2 " | <A HREF=http://" $5":" ports[1] ">" $5":" ports[1] "</A>" }\' ');
$k_output = shell_exec('/usr/local/bin/kubectl get svc -A | grep LoadBalancer | awk \'{ split($6, ports, ":"); print "<TR><TD>" $1 "</TD> <TD>" $2 "</TD>  <TD><A HREF=http://" $5":" ports[1] " target=\""$2"\" >" $5":" ports[1] "</A></TD></TR><BR>" }\' ');
echo "<pre>$k_output</pre> \n";

echo "<TR><TD colspan=3><pre> \n";
$k_output = shell_exec('/usr/local/bin/kubectl top nodes');
echo "$k_output";
echo "</pre></TD></TR> \n";

echo "<TR><TD colspan=3> <pre> \n";
$k_output = shell_exec('/usr/local/bin/kubectl top pods -A');
echo "$k_output";
echo "</pre></TD></TR>";
?>

</TABLE>
<BR>
<TABLE BORDER=1>
<TH colspan=3> Kubernerdes.Lab Infrastructure Services and Endpoints</TH>
<TR><TD><font color=blue>Service</TD> <TD><font color=blue>Endpoint</TD></TR>
<TR> <TD>vSphere Console</TD> <TD><A HREF="https://10.10.12.30/">https://10.10.12.30/</A></TD> </TR>
<TR> <TD>ESXi Console (vmw-esx-01)</TD> <TD><A HREF="http://10.10.12.31">http://10.10.12.31</A></TD> </TR>
<TR> <TD></TD> <TD></TD> </TR>
</TABLE>
</TABLE>
</BODY>
</HTML>
