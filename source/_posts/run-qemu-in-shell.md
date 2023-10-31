---
title: run-qemu-in-shell
date: 2023-10-31 15:39:07
tags:
---

	默认情况下，在远程的shell中是无法直接运行gui程序的，这是由于shell链接的过程中，无法使用x-windows，在某些情况下，如果需要通过shell启动gui程序的时候，一方面系统需要安装x-windows，另外一方面还需要设置当前shell链接的显示器程序，对于linux来说，可以通过设置`DISPLAY`变量的值得到。
	### 获取图形界面的DISPLAY值
	在图形窗口中打开一个新的shell窗口，使用`echo $DISPLAY`即可查看当前图形窗口的ID。

	### 设置shell使用的窗口
	修改~/.bashrc中的文件，新增DISPLAY环境变量
	```shell
	export DISPLAY=:11.0
	```
	后续新增的shell即可以直接操作图形界面中的图形界面了。以下以qemu为例。代码如下
	```asm
cpu 8086
org 0x7C00

mov al, 0x13
mov ah, 0
int 0x10

mov bx, 0                       ; counter
mov ah, 0x0E                    ; for teletype writing http://www.ctyme.com/intr/rb-0106.htm
.print_char:
    mov al, [string + bx]       ; character of string
    push bx                     ; storing counter in the stack
    mov bx, 0x0009              ; set page (no page) and color light blue (0x09) https://en.wikipedia.org/wiki/BIOS_color_attributes
    int 0x10
    cmp al, 0                   ; is this the end of the string?
    je .exit
    pop bx                      ; restoring from the stack
    inc bx
    jmp .print_char

.exit:
    ret
hlt
string db 'Wake up Neo...', 0

TIMES 510 - ($ - $$) db 0 ; Fill the rest of sector with 0
dw 0xaa55 ;  MBR (Master Boot Record) magic numbers

	```
	利用qemu启动上述的程序，用于在启动窗口中打印Wake up Neo。。。,在脚本中，可以看到的现象是程序hang住，在对应的图形界面中，可以看到qemu窗口被打开，并在窗口中打印了`Wake up Neo...`
```shell
nasm print_string.asm -o main.img
qemu-system-x86_64 -hda main.img
```
