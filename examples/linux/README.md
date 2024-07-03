# Inject Shellcode for Linux

## 1. Disable ASLR

By default, the ASLR (Address Space Layout Randomization) is enabled as follow:

```sh
cat cat /proc/sys/kernel/randomize_va_space
2
```

We need to disable it by replacing this value (`2`) to `0`:

```sh
echo 0 | sudo tee cat /proc/sys/kernel/randomize_va_space
```

## 2. Generate Shellcode

```sh
shcgen -p linux/x64/exec --cmd whoami -f hex
```

Copy the generated shellcode (Hex encoded).

## 3. Paste Shellcode to C++ Code

Open `run.cpp` and paste the shellcode to the `shellcode` variable.

## 4. Compile C++ Program

```sh
# -z execstack: Turn off the NX protection to make the stack executable. (ref: https://cocomelonc.github.io/tutorial/2021/10/09/linux-shellcoding-1.html)
g++ -z execstack -o run run.cpp
```

## 5. Execute

Now execute the program.

```sh
./run
```

## 6. Enable ASLR 

After that, it's recommended to restore **ASLR** value for security reason.

```sh
echo 2 | sudo tee cat /proc/sys/kernel/randomize_va_space
```