Phy/WirelessPhy set RXThresh_ 2.28289e-11 ;# set valid wirless connection distance is 500m
set val(chan) Channel/WirelessChannel ;# channel type
set val(prop) Propagation/TwoRayGround ;# radio-propagation model
set val(netif) Phy/WirelessPhy ;# network interface type
set val(mac) Mac/802_11 ;# MAC type
set val(ifq) CMUPriQueue ;# interface queue type
set val(ll) LL ;# link layer type
set val(ant) Antenna/OmniAntenna ;# antenna model
set val(ifqlen) 50 ;# max packet in ifq
set val(nn) 50 ;# number of mobile nodes
set val(bhn) 10;# !!!!!!!!!!set the number of hole
set val(rp) DSR ;# routing protocol
set val(x) 1000 ;# X dimensions of the topography
set val(y) 1000 ;# X dimensions of the topography
set val(ncbr) 25 ;# number of cbr streams
#set up a global instance of Simulator
set ns_ [new Simulator]
#open files to record the simulation results
set tracefd [open RandomScen.tr w]
$ns_ trace-all $tracefd
set namtracefd [open RandomScen.nam w]
$ns_ namtrace-all-wireless $namtracefd $val(x) $val(y)
#a function called in proc finish to analyse trace and print result
proc analysis {} {
	puts "-----------analysis--------"
	set analysis [exec gawk -f analysis.awk RandomScen.tr]
	puts "analysis report:"
	puts $analysis
}

#a function called at the end of the simulation to close the recording files and show the animation
proc finish {} {
	global ns_ tracefd namtracefd
	$ns_ flush-trace
	close $tracefd
	close $namtracefd
	exec nam RandomScen.nam &
	analysis
	exit 0
}
#set up the topography of the scene
set topo [new Topography]
$topo load_flatgrid $val(x) $val(y)
#set up a global instance of God
set god_ [create-god $val(nn)]
#configure all the nodes in the simulation using variables initialized at the beginning
$ns_ node-config -addressType def \
-adhocRouting $val(rp) \
-llType $val(ll) \
-macType $val(mac) \
-ifqType $val(ifq) \
-ifqLen $val(ifqlen) \
-antType $val(ant) \
-propType $val(prop) \
-phyType $val(netif) \
-channelType $val(chan) \
-topoInstance $topo \
-agentTrace ON \
-routerTrace ON \
-macTrace OFF \
-movementTrace OFF
#set up nodes and disable their functions of random motion
for {set i 0} {$i<$val(nn)} {incr i} {
set node_($i) [$ns_ node]
$node_($i) random-motion 0
}
#set the type of blackhole
for {set i 0} {$i<$val(bhn)} {incr i} {
$ns_ at 0.01 "$node_($i) label \"BLACKhole node\""
$ns_ at 0.01 "[$node_($i) set ragent_] startBlackholeAttackA"
$node_($i) color "black";
$ns_ at 0.01 "$node_($i) color \"red\"";
}
source RandomDest.txt
source RandomCbr.txt
#stop all the cbr streams from generating packets
for {set i 0} {$i < $val(ncbr)} {incr i} {
$ns_ at 50.0 "$cbr_($i) stop"
}
#reset all the nodes
for {set i 0} {$i<$val(nn)} {incr i} {
$ns_ at 50.0 "$node_($i) reset"
}
#call function "finish" to close files and show the animation
$ns_ at 60.0 "finish"
#run the simulation
$ns_ run

