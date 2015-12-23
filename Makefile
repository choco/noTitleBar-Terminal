CC=clang
LD=$(CC)

ARCH=
ARCHES=$(foreach arch,$(ARCH),-arch $(arch))
OSXVER=10.5
OSXVER64=10.5
ifneq ($(OSXVER),$(OSXVER64))
ARCHES+=-Xarch_x86_64 -mmacosx-version-min=$(OSXVER64)
endif

OPTLEVEL=2
CFLAGS+=-std=c99 -O$(OPTLEVEL) -Wall -mmacosx-version-min=$(OSXVER) $(ARCHES)
LDFLAGS+=-bundle -framework Cocoa
OBJS=noTitleBar-Terminal.m JRSwizzle/JRSwizzle.o
NAME=noTitleBar-Terminal
BUNDLE=$(NAME).bundle
TARGET=$(BUNDLE)/Contents/MacOS/$(NAME)
SIMBLDIR=$(HOME)/Library/Application\ Support/SIMBL/Plugins

default: all
%.o: %.m
	$(CC) -c $(CFLAGS) $< -o $@

$(TARGET): $(OBJS)
	mkdir -p $(BUNDLE)/Contents/MacOS
	$(LD) $(CFLAGS) $(LDFLAGS) -o $@ $^
	cp Info.plist $(BUNDLE)/Contents

all: $(TARGET)

clean:
	rm -f *.o
	rm -f JRSwizzle/*.o
	rm -rf $(BUNDLE) $(NAME)

install: $(TARGET) uninstall
	mkdir -p $(SIMBLDIR)
	cp -R $(BUNDLE) $(SIMBLDIR)

uninstall:
	rm -rf $(SIMBLDIR)/$(BUNDLE)
