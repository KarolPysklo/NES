FLAGS =
LDFLAGS = -C/usr/share/cc65/cfg/nes.cfg

AS65 = ca65
LD65 = ld65

.PHONY: all clean

all: $(NAME).nes
clean:
	-rm -v %.o

%.nes: %.o /usr/share/cc65/cfg/nes.cfg
	$(LD65) $(LDFLAGS) $(FLAGS) -o$@ $<

%.o: %.asm
	$(AS65) $(FLAGS) -o$@ $<