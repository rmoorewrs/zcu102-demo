# zcu102-demo
vxworks demo script for zcu102

How to use it:
- prerequisite: VxWorks installation
- edit the set_wrenv_2403.sh or set_wrenv_2503.sh to match your installation

### 1) Change directory into the `ws` workspace

```
cd zcu102-demo/ws
```

### 2) Set up the environment variables for VxWorks

```
. ../set_wrenv_2503.sh
```

 Alternately, run 
 ```
 <path-to-vxworks-install>/wrenv.sh -p vxworks/25.03     # use your path, your version
 ```

### 3) Run the A53 creation script
```
../create_zynqmp_a53.sh
```

### 4) Run the R5 creation script
```
../create_zynqmp_r5.sh
```

### 5) Optional: import the VSB and VIP projects into Workbench. Import the VSBs first. 

Import 4 projects: 
- zynqmp_r5-vsb
- zynqmp_r5-vip
- zynqmp_a53-vsb
- zynqmp_a53-vip

In order to import in workbench do the following:
```
File->Import->VxWorks->VxWorks VSB
```