function main {
	parameter vessel.
	parameter desiredApoapsis.
	parameter desiredHeading.
	
	clearscreen.
	wait until vessel:unpacked.
	suborbit(vessel,desiredApoapsis,desiredHeading).
	toggle ag4. //extend solar panels, antennas, etc
	circularizeOrbit(vessel).
	
}

function suborbit {
	parameter vessel.
	parameter desiredApoapsis.
	parameter desiredHeading.
	local currentBody is getCurrentBody(vessel).
	local atmoHeight is currentBody:atm:height.
	
	set steering to heading(desiredHeading,90). //specify vessel
	set throttle to 1. //specify vessel
	gravityTurn(vessel,desiredApoapsis,desiredHeading).
	lock throttle to 0.
	wait until vessel:altitude > atmoHeight.
	correctAtmosphereDecay(vessel,desiredApoapsis).
	wait 0.1.
}

function gravityTurn {
	parameter vessel.
	parameter desiredApoapsis.
	parameter desiredHeading.
	
	until vessel:orbit:apoapsis > desiredApoapsis {
		lock steering to heading(desiredHeading,90-(90*(vessel:orbit:apoapsis/desiredApoapsis))).
		if stage:liquidfuel = 0 {stage.}
		if abort {shutdown.}
		wait 0.01.
	}
}

function correctAtmosphereDecay {
	parameter vessel.
	parameter desiredApoapsis.
	
	lock steering to prograde.
	wait 5. //this is dumb idk how to fix this
	until vessel:orbit:apoapsis >= desiredApoapsis {
		lock throttle to 0.05.
	}
	lock throttle to 0.
}

function circularizeOrbit {
	parameter vessel.
	
	local circNode is calculateNode(vessel).
	local isp is calculateISP(vessel).
	add circNode.
	local burnTime is calculateBurnTime(vessel,circNode,isp).
	executeNode(vessel,circNode,burnTime).
}

function executeNode {
	parameter vessel. //redundant but would like to implement vessel specific later
	parameter node.
	parameter burnTime.
	
	lock steering to node:burnvector.
	wait until node:eta <= burnTime / 2.
	lock throttle to 1.
	wait burnTime.
	lock throttle to 0.
}

function calculateNode { //currently only works for circular orbit
	parameter vessel.
	
	local currentBody is getCurrentBody(vessel).
	local acceleration is constant:g*(currentBody:mass/(currentBody:radius + vessel:orbit:apoapsis)^2).
	local orbitPeriod is (sqrt(4*(constant:pi)^2*(currentBody:radius + vessel:orbit:apoapsis)) / sqrt(acceleration)).
	local dv is (2*constant:pi*(currentBody:radius + vessel:orbit:apoapsis) / orbitPeriod) - velocityat(vessel,timestamp(time:seconds + vessel:orbit:eta:apoapsis)):orbit:mag.
	local node is node(TimeSpan(0,0,0,0,vessel:orbit:eta:apoapsis),0,0,dv).
	return node.
}


function calculateISP {
	parameter vessel. //redundant but would like to implement vessel specific later
	local isp is 0.
	local k is 0.
	local engList is list().
	
	list engines in engList.
	for eng in engList { //find isp function
		if eng:ignition {
			set isp to isp + eng:isp.
			set k to k+1.
		}
	}
	local isp is isp / k.
	return isp.
}


function calculateBurnTime {
	parameter vessel.
	parameter node.
	parameter isp.
	local currentBody is getCurrentBody(vessel).
	
	local exhaustVelocity is isp * constant:g * (currentBody:mass / currentBody:radius ^ 2).
	local massOriginal is vessel:mass.
	local massFinal is vessel:mass / (constant:e ^ (node:deltav:mag / exhaustVelocity)).
	local fuelBurned is massOriginal - massFinal.
	local burnRate is vessel:availablethrust / exhaustVelocity.
	local burnTime is fuelBurned / burnRate.
	return burnTime.
}

function getCurrentBody{
	parameter vessel.
	return vessel:body.
}

main(ship,100000,90).
