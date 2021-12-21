#include <cstdlib>

#include "iss.h"
#include "elf_loader.h"


int main(int argc, char **argv) {
    if (argc != 2) {
        std::cout << "ERROR: input program expected" << std::endl;
        return -1;
    }

    enum {
        MEM_SIZE = 1024*1024*8,  // 8 MB ram
    };

    ISS sim;
    Memory mem(MEM_SIZE);
    ELFLoader loader(argv[1]);

    loader.load_executable_image(mem.data, mem.size);
    sim.init(&mem, loader.get_entrypoint(), MEM_SIZE-4);

    sim.run();
    sim.show();

	return 0;
}
