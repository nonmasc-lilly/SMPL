all: test.SMPL
	python simulate.py test.SMPL -o test.asm 
	nasm -felf64 test.asm -o test.o
	ld test.o -o test

