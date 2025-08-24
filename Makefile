
BUILD ?= build
TARGET ?= smplc

all: $(BUILD)/$(TARGET)

$(BUILD)/$(TARGET): src/main.asm src/* | $(BUILD)
	fasm $< $@

$(BUILD):
	mkdir -p $@

test: all FORCE
	$(BUILD)/$(TARGET) test/one.smpl test/one.bin
	-hexdump -X test/one.bin
	$(BUILD)/$(TARGET) test/two.smpl test/two.bin
	-hexdump -X test/two.bin

FORCE:
