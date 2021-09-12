#  File Name:         StartUp.tcl
#  Purpose:           Scripts for running simulations
#  Revision:          OSVVM MODELS STANDARD VERSION
# 
#  Maintainer:        Jim Lewis      email:  jim@synthworks.com 
#  Contributor(s):            
#     Jim Lewis      email:  jim@synthworks.com   
# 
#  Description
#    StartUp for ActiveVSimSA
#    
#  Developed by: 
#        SynthWorks Design Inc. 
#        VHDL Training Classes
#        OSVVM Methodology and Model Library
#        11898 SW 128th Ave.  Tigard, Or  97223
#        http://www.SynthWorks.com
# 
#  Revision History:
#    Date      Version    Description
#    01/2022   2022.01    Initial
#
#
#  This file is part of OSVVM.
#  
#  Copyright (c) 2018 - 2021 by SynthWorks Design Inc.  
#  
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#  
#      https://www.apache.org/licenses/LICENSE-2.0
#  
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#


namespace eval ::osvvm {
  # Initial SCRIPT_DIR setup - revised by ActiveHDL VSimSA
#  variable SCRIPT_DIR  [file dirname [file normalize [info script]]]
  
  # 
  # Find the simulator
  #
  variable ToolExecutable [info nameofexecutable]
  variable ToolExecutableName [file rootname [file tail $ToolExecutable]]

  set SCRIPT_DIR [file dirname [string trim $argv0 ?{}?]]
  source ${SCRIPT_DIR}/VendorScripts_VSimSA.tcl
}
# OSVVM Project Scripts 
if {![catch {package require yaml}]} {
  source ${::osvvm::SCRIPT_DIR}/OsvvmYamlSupport.tcl
} else {
  source ${::osvvm::SCRIPT_DIR}/NoYamlPackage.tcl
}
source ${::osvvm::SCRIPT_DIR}/OsvvmProjectScripts.tcl
namespace import ::osvvm::*

# Set OSVVM Script Defaults - defaults may call scripts
source ${::osvvm::SCRIPT_DIR}/OsvvmScriptDefaults.tcl

if {[file exists ${::osvvm::SCRIPT_DIR}/LocalScriptDefaults.tcl]} {
  source ${::osvvm::SCRIPT_DIR}/LocalScriptDefaults.tcl
}