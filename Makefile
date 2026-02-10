all: build install

build:
	@bash build.sh build
install:
	@bash build.sh package
clean:
	rm -rf work
