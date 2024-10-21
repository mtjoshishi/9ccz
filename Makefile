CC=zig
ZIGFLAGS=-fno-strip -static

9ccz: 9ccz.zig
	$(CC) build-exe $(ZIGFLAGS) $<

test: 9ccz
	./test.sh

clean:
	rm -f 9ccz *.o *~ tmp*

.PHONY:	test clean
