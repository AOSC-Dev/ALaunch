ALaunch: main.vala
	valac main.vala -o ALaunch --pkg gtk+-3.0

all: clean ALaunch

clean:
	rm -f ALaunch
	
install: all
	./install.sh
