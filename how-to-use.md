# How to use

This guide aimed at explaining how to use the FPGA and how to test bare-metal code running of Cheshire. You should find the bitfile already flashed, so we will skip this step since it's a bit more complex and requires vivado and the build bitfile.

To test any program on Cheshire running on the FPGA we need 3 different terminals opened at the same time.

1. JTAG connection
2. riscv-gdb to load the executable
3. python script to read from the UART

All the steps are executed on Chen's PC, whose IP address is *130.192.163.9*. First we need to login into a shared account created for the FPGA.

```bash
ssh zcu102@imodium.polito.it
```

If it's the first time you login, it will ask you to validate the ssh-key, just write `yes`. Now you will be prompted to insert the password, that is `fpga-lab4`.

Now, you have to go in the `/home/zcu102/git` by running:

```bash
cd /home/zcu102/git
```

In this directory you will find many subdirectory. The one we are interested in are:

1. `riscv-openocd-commit`: this folder contains the executable and the configuration for openocd, which is used to communicate via JTAG
2. `uart_script`: this folder contains the python script to read the UART
3. `cheshire`: this folder contains the compiled programs

Let's now go step by step into the process.

## Compile your program

If you go to the folder `/home/zcu102/git/cheshire/sw/tests` with the command:

```bash
cd /home/zcu102/git/cheshire/sw/tests
```

you will notice that there are some `.c` programs. This are the one we are going to run on the FPGA. First we need to compile them. 

> [!WARNING]  
> To compile the programs you need to go back to cheshire parent folder, so just `cd /home/zcu102/git/cheshire`

When you are in `/home/zcu102/git/cheshire` you can run the command

```bash
make chs-sw-all
```

This make command will compile all the `.c` present in the `/home/zcu102/git/cheshire/sw/tests`. For instance, if you want to add a program, you can just add the `.c` file in that folder and it will automatically compile it. At the end of the compilation you should have all the necessary files needed to run it on the FPGA. 

## Open the JTAG connection

For this step we need to use openocd with a custom configuration. To do that just go into `/home/zcu102/git/riscv-openocd-commit/src` by running:

```bash
cd /home/zcu102/git/riscv-openocd-commit/src
```

When you are in that folder you can just run:

```bash
sudo ./openocd -f new_config.cfg
```

You will be prompted to insert the password, which is the same as the one already provided you are the beginning. Now, you should see something like this on the output of the terminal:

```
Open On-Chip Debugger 0.11.0+dev-01746-g3249d4155 (2024-01-19-11:43)
Licensed under GNU GPL v2
For bug reports, read
	http://openocd.org/doc/doxygen/bugs.html
DEPRECATED! use 'adapter speed' not 'adapter_khz'
DEPRECATED! use 'adapter driver' not 'interface'
Info : auto-selecting first available session transport "jtag". To override use 'transport select <transport>'.
Warn : `riscv set_prefer_sba` is deprecated. Please use `riscv set_mem_access` instead.
Info : clock speed 1000 kHz
Info : JTAG tap: riscv.cpu tap/device found: 0x1c5e5db3 (mfg: 0x6d9 (<unknown>), part: 0xc5e5, ver: 0x1)
Info : datacount=2 progbufsize=8
Info : Examined RISC-V core; found 1 harts
Info :  hart 0: XLEN=64, misa=0x80000000001411ad
Info : starting gdb server for riscv.cpu on 3333
Info : Listening on port 3333 for gdb connections
Info : JTAG tap: riscv.cpu tap/device found: 0x1c5e5db3 (mfg: 0x6d9 (<unknown>), part: 0xc5e5, ver: 0x1)
Ready for Remote Connections
Info : Listening on port 6666 for tcl connections
Info : Listening on port 4444 for telnet connections
```

The terminal will stay waiting like this, and this is correct. In caso you want to exit from openocd, just press `ctrl+c`. 

## Load the executable

Now that the JTAG connection is running, we can move on to the next step, in which we load the executable.
Let's move to the `/home/zcu102/git/cheshire/sw/tests` folder:

```bash
cd /home/zcu102/git/cheshire/sw/tests
```

From here let's run the following command:

```bash
riscv64-unknown-elf-gdb -ex "target extended-remote localhost:3333"
```

The terminal should now show the following content:

```
GNU gdb (GDB) 10.1
Copyright (C) 2020 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
Type "show copying" and "show warranty" for details.
This GDB was configured as "--host=x86_64-pc-linux-gnu --target=riscv64-unknown-elf".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<https://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
    <http://www.gnu.org/software/gdb/documentation/>.

For help, type "help".
Type "apropos word" to search for commands related to "word".
Remote debugging using localhost:3333
warning: No executable has been specified and target does not support
determining executable automatically.  Try using the "file" command.
0x000000001000018c in ?? ()
(gdb)
```

In addition to that, in the JTAG terminal, a line should have appeared with the following content:

```
Info : accepting 'gdb' connection on tcp/3333
```

This means that everything is working correctly. 

Let's simulate the loading of the `hello_world.c`. In the (gdb) terminal, let's run:

```
file helloworld.spm.elf
```

You should see an output like this:

```
(gdb) file helloworld.spm.elf
A program is being debugged already.
Are you sure you want to change the file? (y or n) y
Reading symbols from helloworld.spm.elf...
```

When prompted to insert y or no, just write y and press enter. The program should now be ready to be loaded. The following command is:

```bash
load
```

If you press enter you should see something like this:

```bash
Loading section .text, size 0x12f0 lma 0x10000000
Loading section .misc, size 0x2c8 lma 0x100012f0
Start address 0x0000000010000000, load size 5560
Transfer rate: 63 KB/sec, 2780 bytes/write.
```

This means that the program has been loaded correctly. Before running the program, we need to open the UART connection to see if the output is correct.

## Opening the UART connection

For the UART connection, due to some issues with the USB-to-UART-adapter, we opted for a python script using the pyserial library. 

First we need to create a virtual environment to avoid python packages conflicts. To do that just run:

```bash
python3 -m venv venv
```

Now let's activate the environment by running:

```bash
source venv/bin/activate
```

Now we can install packages by running:

```bash
pip3 install pyserial
```

This should install the library, and its dependencies, that we need. Now you can run the script by executing the command:

```bash
python3 script.py
```

You should something like this:

```bash
Serial connection opened. Listening for data...
```

Now just go back to the (gdb) terminal, and write `c` into the (gdb) console. On the python terminal you should see the `Hello World!` printed. This means everything is working properly. 
