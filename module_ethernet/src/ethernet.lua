  
function getIncludes()
    return "#include \"ethernet_server.h\"" ..
		   "#include \"ethernet_rx_client.h\"" ..
		   "#include \"ethernet_tx_client.h\""
end

function getGlobals()
	return "mii_interface_t mii_" .. component.id .. " = {\n" ..
			component.clockblock[0] .. ",\n" ..  
			component.clockblock[1] .. ",\n" ..
			component.port[0] .. ",\n" ..
			component.port[1] .. ",\n" ..
			component.port[2] .. ",\n" ..
			component.port[3] .. ",\n" ..
			component.port[4] .. ",\n" ..
			component.port[5] .. ",\n" ..
			component.port[6] .. ",\n" ..
			component.port[7] .. ",\n" ..
			"};\n\n" ..
			
			"smi_interface_t smi_" .. component.id .. " = { " ..
			component.port[7] .. "," .. component.port[8] .. ", 1 };\n\n" ..
			
			"clock clk_mii_ref_" .. component.id .. " = " .. component.clockblock[2] .. ";\n" ..
			"clock clk_smi_" .. component.id .. " = " .. component.clockblock[3] .. ";\n"

end

function getChannels()
	return "chan rx_chans_" .. component.id .. "[" .. component.params.numClients .. "];\n" ..
		   "chan tx_chans_" .. component.id .. "[" .. component.params.numClients .. "];\n"
end

function getLocals()
    return ""
end

function getCalls()

	return "{ int mac_address[2];\n" ..
		   "ethernet_getmac_otp((mac_address, char[]));\n" ..
		   "phy_init(clk_smi_" .. component.id .. ", clk_mii_ref_" .. component.id .. ", \n" ..
		   "null, \n" ..
		   "smi_" .. component.id .. ",\n" ..
		   "mii_" .. component.id .. ");\n\n" ..
		   
		   "ethernet_server(mii_" .. component.id .. ", clk_mii_ref_" .. component.id ..
		   "mac_address,\n" ..
		   "rx_chans_" .. component.id .. ", MAX_LINKS, \n" ..
		   "tx_chans_" .. component.id .. ", MAX_LINKS, \n" ..
		   "null, null);\n\n" ..
		   "}"
		   

    return "i2c(i2c_master_chan_" .. component.id .. 
           ", " .. component.params.numClients .. 
           ", i2c_master_sda_" .. component.id .. 
           ", i2c_master_scl_" .. component.id .. 
           ", " .. component.params.speed .. 
           ", i2c_master_data_buffer_" .. component.id .. ");" 
end

function getDatasheetSummary()
	return "Ethernet interface"
end

function getDatasheetDescription()
	return "The Inter-Integrated Circuit (I2C) single-master component suppports " ..
	IF (component.params.speed >= 100) "100kbit/sec standard mode" .. IF (component.params.speed > 100) " and arbitrary speeds of up to " .. component.params.speed .. ". "
	ELSE "arbitrary speeds of up to " ... component.params.speed .. ". " ..
	"No support is provided for multi-master, high-speed or 10-bit addressing modes. "
end

