cd /Users/preluminance/Desktop/Main/Coding/CelestineOS/x86_64
nasm -f bin boot.asm -o boot.bin
nasm -f bin stage2.asm -o stage2.bin
# Write boot sector
dd if=boot.bin of=disk.img bs=512 count=1 conv=notrunc
# Write second-stage bootloader
dd if=stage2.bin of=disk.img bs=512 seek=1 count=2 conv=notrunc
qemu-system-x86_64 -drive format=raw,file=disk.img -nographic