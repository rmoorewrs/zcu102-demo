#!/bin/sh

# Uncomment exports for one version
# set this for your network
export DEV_IP=10.10.11.30
export SERVER_IP=10.10.11.52
export GATEWAY_IP=10.10.11.1
export NETMASK=255.255.255.0
export NETMASKHEX=ffffff00
export NETMASKCIDR=24

# VxWorks 24.03
export VXWORKS_VERSION=24.03
export PROJECT_NAME=zynqmp_r5
export BSP_NAME=xlnx_zynqmp_r5_2_0_5_0
export DTS_FILE=xlnx-zcu102-r5-rev-1.1.dts

# VxWorks 25.03
#export VXWORKS_VERSION=25.03
#export PROJECT_NAME=zynqmp_r5
#export BSP_NAME=amd_zynqmp_r5_2_0_5_1
#export DTS_FILE=amd-zcu102-r5-rev-1.1.dts

# check that this is a valid VxWorks dev shell
if [ -z "$WIND_RELEASE_ID" ]; then echo "WR Dev Shell Not detected, run \<install_dir\>/wrenv.sh -p vxworks/${VXWORKS_VERSION} first";return -1; else echo "VxWorks Release $WIND_RELEASE_ID detected"; fi


export PATCH_FILE=zynqmp_r5_dts.patch

# set current directory as workspace
export MY_WS_DIR=$(pwd)

# set project names
export VSB_NAME=${PROJECT_NAME}-vsb
export VIP_NAME=${PROJECT_NAME}-vip

generate_patch_file()
{

cat << EOF > $1
--- ${DTS_FILE}
+++ dontcare.dts.modified
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
+        bootargs = "gem(0,0)host:vxWorks h=${SERVER_IP} e=${DEV_IP}:${NETMASKHEX} g=${GATEWAY_IP} u=a pw=a";
         stdout-path = "serial0";
         };
EOF

}

# build the VSB
vxprj vsb create -force -ilp32 -bsp $BSP_NAME -force -S $VSB_NAME
cd $VSB_NAME
vxprj vsb build -j


# create, configure and build VIP
cd $MY_WS_DIR
vxprj vip create -vsb $VSB_NAME $BSP_NAME -profile PROFILE_DEVELOPMENT $VIP_NAME
cd $MY_WS_DIR/$VIP_NAME
vxprj bundle add BUNDLE_STANDALONE_SHELL
vxprj vip component remove $VIP_NAME INCLUDE_NETWORK
vxprj vip component add $VIP_NAME INCLUDE_STANDALONE_DTB
vxprj vip component add $VIP_NAME INCLUDE_FDT_SHOW
vxprj vip component add $VIP_NAME DRV_TEMPLATE_FDT_MAP

# patch the dts file
cd ${BSP_NAME}
cp ${DTS_FILE} ${DTS_FILE}.orig
generate_patch_file ${PATCH_FILE}
patch -p0 < ${PATCH_FILE}
cd ..

vxprj vip build

cd $MY_WS_DIR

echo Done. Remember to copy this to your tftpboot directory
echo cp zynqmp_r5-vip/default/vxWorks.bin /tftpboot/vxWorks_r5.bin

