ZIGBUILD=zig build-exe
ZIGFLAGS=-fno-strip -static

9ccz:
	$(ZIGBUILD) $(ZIGFLAGS) 9ccz.zig

test: 9ccz
	./test.sh

clean:
	rm -f 9ccz *.o *~ tmp*

.PHONY:	test clean
