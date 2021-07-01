#####################################################
# nu11secur1ty 2021
#
#.Parameter Zone
#	 The country code which you want to block.
#
#.Parameter InputFile
#    File containing IP addresses and ranges to block; IPv4 and IPv6 supported.
#
#.Parameter RuleName
#    (Optional) Override default firewall rule name; default based on file name.
#    When used with -DeleteOnly, just give the rule basename without the "-#1".
#
#.Parameter ProfileType
#    (Optional) Comma-delimited list of network profile types for which the
#    blocking rules will apply: public, private, domain, any (default = any).
#
#.Parameter InterfaceType
#    (Optional) Comma-delimited list of interface types for which the
#    blocking rules will apply: wireless, ras, lan, any (default = any).
#
#.Parameter DeleteOnly
#    (Switch) Matching firewall rules will be deleted, none will be created.
#    When used with -RuleName, leave off the "-#1" at the end of the rulename.
#
#.Example 
#    import-firewall-blocklist.ps1 -inputfile IpToBlock.txt
#
#.Example
#    import-firewall-blocklist.ps1 -inputfile iptoblock.txt -profiletype public
#
#.Example
#    import-firewall-blocklist.ps1 -inputfile iptoblock.txt -interfacetype wireless
#
#.Example 
#    import-firewall-blocklist.ps1 -inputfile IpToBlock.txt -deleteonly
#
#.Example 
#    import-firewall-blocklist.ps1 -rulename IpToBlock -deleteonly
#
#Requires -Version 1.0 
#
#.Notes 
#  Author: Jason Fossen (http://www.sans.org/windows-security/)  
# Version: Vinahost release
# Updated: 15.Aug.2017
#   LEGAL: PUBLIC DOMAIN.  SCRIPT PROVIDED "AS IS" WITH NO WARRANTIES OR GUARANTEES OF 
#          ANY KIND, INCLUDING BUT NOT LIMITED TO MERCHANTABILITY AND/OR FITNESS FOR
#          A PARTICULAR PURPOSE.  ALL RISKS OF DAMAGE REMAINS WITH THE USER, EVEN IF
#          THE AUTHOR, SUPPLIER OR DISTRIBUTOR HAS BEEN ADVISED OF THE POSSIBILITY OF
#          ANY SUCH DAMAGE.  IF YOUR STATE DOES NOT PERMIT THE COMPLETE LIMITATION OF
#          LIABILITY, THEN DELETE THIS FILE SINCE YOU ARE NOW PROHIBITED TO HAVE IT.
####################################################################################
    
param ($Zone, $InputFile, $RuleName, $ProfileType = "any", $InterfaceType = "any", [Switch] $DeleteOnly)

if (!$InputFile) 
{
	if (!$Zone -or $Zone.length -ne 2)
	{
		"`n$Zone not found, quitting...`n" ; exit
	}
	$zone = $Zone.ToLower() + ".zone";
	$InputFile = $zone + ".txt";
	if (-not $DeleteOnly) { (new-object System.Net.WebClient).Downloadfile("http://www.ipdeny.com/ipblocks/data/countries/$zone",$InputFile) }
}
else {}

# Look for some help arguments, show help, then quit.
if ($InputFile -match '/[?h]') { "`nPlease run 'get-help .\import-firewall-blocklist.ps1 -full' for help on PowerShell 2.0 and later, or just read the script's header in a text editor.`n" ; exit }  

# Get input file and set the name of the firewall rule.
$file = get-item $InputFile -ErrorAction SilentlyContinue # Sometimes rules will be deleted by name and there is no file.
if (-not $? -and -not $DeleteOnly) { "`nCannot find $InputFile, quitting...`n" ; exit } 
if (-not $rulename) { $rulename = $file.basename }  # The '-#1' will be appended later.

# Description will be seen in the properties of the firewall rules.
$description = "Rule created by script on $(get-date). Do not edit rule by hand, it will be overwritten when the script is run again. By default, the name of the rule is named after the input file."

# Any existing firewall rules which match the name are deleted every time the script runs.
"`nDeleting any inbound or outbound firewall rules named like '$rulename-#*'`n"
$currentrules = netsh.exe advfirewall firewall show rule name=all | select-string '^[Rule Name|Regelname]+:\s+(.+$)' | foreach { $_.matches[0].groups[1].value } 
if ($currentrules.count -lt 3) {"`nProblem getting a list of current firewall rules, quitting...`n" ; exit } 
# Note: If you are getting the above error, try editing the regex pattern two lines above to include the 'Rule Name' in your local language.
$currentrules | foreach { if ($_ -like "$rulename-#*"){ netsh.exe advfirewall firewall delete rule name="$_" | out-null } } 

# Don't create the firewall rules again if the -DeleteOnly switch was used.
if ($deleteonly -and $rulename) { "`nReminder: when deleting by name, leave off the '-#1' at the end of the rulename.`n" } 
if ($deleteonly) { exit } 

# Create array of IP ranges; any line that doesn't start like an IPv4/IPv6 address is ignored.
$ranges = get-content $file | where {($_.trim().length -ne 0) -and ($_ -match '^[0-9a-f]{1,4}[\.\:]')} 
if (-not $?) { "`nCould not parse $file, quitting...`n" ; exit } 
$linecount = $ranges.count
if ($linecount -eq 0) { "`nZero IP addresses to block, quitting...`n" ; exit } 

# Now start creating rules with hundreds of IP address ranges per rule.  Testing shows
# that netsh.exe errors begin to occur with more than 400 IPv4 ranges per rule, and 
# this number might still be too large when using IPv6 or the Start-to-End format, so 
# default to only 100 ranges per rule, but feel free to edit the following variable:
$MaxRangesPerRule = 100

$i = 1                     # Rule number counter, when more than one rule must be created, e.g., BlockList-#001.
$start = 1                 # For array slicing out of IP $ranges.
$end = $maxrangesperrule   # For array slicing out of IP $ranges.
do {
    $icount = $i.tostring().padleft(3,"0")  # Used in name of rule, e.g., BlockList-#042.
    
    if ($end -gt $linecount) { $end = $linecount } 
    $textranges = [System.String]::Join(",",$($ranges[$($start - 1)..$($end - 1)])) 

    "`nCreating an  inbound firewall rule named '$rulename-#$icount' for IP ranges $start - $end" 
    netsh.exe advfirewall firewall add rule name="$rulename-#$icount" dir=in action=block localip=any remoteip="$textranges" description="$description" profile="$profiletype" interfacetype="$interfacetype"
    if (-not $?) { "`nFailed to create '$rulename-#$icount' inbound rule for some reason, continuing anyway..."}
    
    "`nCreating an outbound firewall rule named '$rulename-#$icount' for IP ranges $start - $end" 
    netsh.exe advfirewall firewall add rule name="$rulename-#$icount" dir=out action=block localip=any remoteip="$textranges" description="$description" profile="$profiletype" interfacetype="$interfacetype"
    if (-not $?) { "`nFailed to create '$rulename-#$icount' outbound rule for some reason, continuing anyway..."}
    
    $i++
    $start += $maxrangesperrule
    $end += $maxrangesperrule
} while ($start -le $linecount)



# END-O-SCRIPT

# Incidentally, testing shows a delay of 2-5 seconds sometimes for the initial
# connection when there are more than 5000 IP address ranges total in the various
# outbound rules (once established, there is no delay).  However, it does not seem
# consistent.  Also, at 5000+ subnets in one's rules, it delays the opening of the
# Windows Firewall snap-in, and at 9000+ subnets it sometimes prevents the WF snap-in
# from opening successfully at all.  However, this behavior is not consistent either.
