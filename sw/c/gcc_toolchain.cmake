set(LINKER_SCRIPT "${CMAKE_CURRENT_LIST_DIR}/../common/link.ld")
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_C_COMPILER riscv64-unknown-elf-gcc)
set(CMAKE_ASM_COMPILER riscv64-unknown-elf-gcc)
set(CMAKE_OBJCOPY riscv64-unknown-elf-objcopy)
set(CMAKE_C_FLAGS_INIT
    "-march=rv32imc_zicsr_zifencei -mabi=ilp32 -mcmodel=medany -Wall -fvisibility=hidden -ffreestanding")
set(CMAKE_ASM_FLAGS "-march=rv32imc_zicsr_zifencei -mabi=ilp32" CACHE STRING "" FORCE)
set(CMAKE_EXE_LINKER_FLAGS_INIT "-march=rv32imc_zicsr_zifencei -mabi=ilp32 -nostartfiles -T \"${LINKER_SCRIPT}\"")
