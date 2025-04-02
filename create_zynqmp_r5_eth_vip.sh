#!/bin/sh

# check that this is a valid VxWorks dev shell
if [ -z "$WIND_RELEASE_ID" ]; then echo "WR Dev Shell Not detected, run \<install_dir\>/wrenv.sh -p vxworks/24.03 first";return -1; else echo "VxWorks Release $WIND_RELEASE_ID detected"; fi

export VXWORKS_VERSION=25.03
export PROJECT_NAME=zynqmp_r5
export BSP_NAME=amd_zynqmp_r5_2_0_5_1
export DTS_FILE=amd-zcu102-r5-rev-1.1.dts
export PATCH_FILE=zynqmp_r5_eth_dts.patch

# set current directory as workspace
export MY_WS_DIR=$(pwd)

# set project names
export VSB_NAME=${PROJECT_NAME}-vsb
export VIP_NAME=${PROJECT_NAME}_eth-vip

generate_patch_file()
{

cat << EOF > $1
--- amd-zcu102-r5-rev-1.1.dts
+++ amd-zcu102-r5-rev-1.1.dts.modified
@@ -30,10 +30,18 @@
         device_type = "memory";
         reg = <0x78000000 0x08000000>;
         };
+        
+        
+    generic_dev@0x76000000
+       {
+       compatible = "fdt,generic-dev";
+       reg = <0x76000000 0x02000000>;
+       status = "okay";
+       };
 
     chosen
         {
-        bootargs = "gem(0,0)host:vxWorks h=192.168.1.1 e=192.168.1.6:ffffff00 g=192.168.1.1 u=a pw=a";
+        bootargs = "gem(0,0)host:vxWorks h=10.10.15.52 e=10.10.15.30:ffffff00 g=10.10.15.1 u=a pw=a";
         stdout-path = "serial0";
         };
EOF

}

# use existing VSB
#vxprj vsb create -force -ilp32 -bsp $BSP_NAME -force -S $VSB_NAME
#cd $VSB_NAME
#vxprj vsb build -j


# create, configure and build VIP
cd $MY_WS_DIR
vxprj vip create -vsb $VSB_NAME $BSP_NAME -profile PROFILE_DEVELOPMENT $VIP_NAME
cd $MY_WS_DIR/$VIP_NAME
vxprj bundle add BUNDLE_STANDALONE_SHELL
vxprj vip component add $VIP_NAME INCLUDE_GETOPT 
vxprj vip component add $VIP_NAME INCLUDE_STANDALONE_DTB
vxprj vip component add $VIP_NAME INCLUDE_DEBUG_AGENT_START
vxprj vip component add $VIP_NAME INCLUDE_IPWRAP_IFCONFIG
vxprj vip component add $VIP_NAME INCLUDE_IFCONFIG
vxprj vip parameter set $VIP_NAME IFCONFIG_1 '"ifname gem0","devname gem","inet 10.10.15.30/24","gateway 10.10.15.1"'
vxprj vip component add $VIP_NAME INCLUDE_PING
vxprj vip component add $VIP_NAME INCLUDE_IPPING_CMD
vxprj vip component add $VIP_NAME INCLUDE_IPTELNETS
vxprj vip component add $VIP_NAME INCLUDE_ROUTECMD
vxprj vip component add $VIP_NAME INCLUDE_IPROUTE_CMD

vxprj vip component add $VIP_NAME INCLUDE_VXBUS_SHOW
vxprj vip component add $VIP_NAME DRV_TEMPLATE_FDT_MAP
vxprj vip component add $VIP_NAME INCLUDE_FDT_SHOW

# Debug
vxprj vip component add $VIP_NAME INCLUDE_ANALYSIS_AGENT
vxprj vip component add $VIP_NAME INCLUDE_ANALYSIS_DEBUG_SUPPORT
vxprj vip component add $VIP_NAME INCLUDE_DEBUG_AGENT INCLUDE_DEBUG_AGENT_START 
vxprj vip component add $VIP_NAME INCLUDE_WINDVIEW INCLUDE_WVUPLOAD_FILE
vxprj vip component add $VIP_NAME INCLUDE_VXBUS_SHOW
vxprj vip component add $VIP_NAME INCLUDE_VXEVENTS


# patch the dts file
cd ${BSP_NAME}
cp ${DTS_FILE} ${DTS_FILE}.orig
generate_patch_file ${PATCH_FILE}
patch -p0 < ${PATCH_FILE}
cd ..

vxprj vip build

cd $MY_WS_DIR


echo cp zynqmp_r5_eth-vip/default/vxWorks.bin /tftpboot/vxWorks_r5_eth.bin

