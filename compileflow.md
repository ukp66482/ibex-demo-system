# Ibex Demo System 完整編譯與燒錄流程（Arty A7-100T / Nexys A7-100T）

## 前置環境

```bash
# 1. RISC-V GCC toolchain（riscv64-unknown-elf-gcc）
# 2. Vivado 2025.2
# 3. FuseSoC（lowRISC fork）
pip install fusesoc

# 4. OpenOCD（建議從 source 編譯最新版）
git clone https://github.com/openocd-org/openocd.git
cd openocd && ./bootstrap && ./configure && make && sudo make install
```

---

## Step 1：編譯軟體

```bash
mkdir -p sw/c/build && cd sw/c/build
cmake -DCMAKE_TOOLCHAIN_FILE=../gcc_toolchain.cmake ..
make -j$(nproc)
cd ../../..
```

產出在 `sw/c/build/demo/hello_world/demo`（ELF 格式）

---

## Step 2：合成 FPGA Bitstream

```bash
# Arty A7
fusesoc --cores-root=. run --target=synth --setup --build lowrisc:ibex:demo_system

# Nexys A7
fusesoc --cores-root=. run --target=synth_nexysa7 --setup --build lowrisc:ibex:demo_system
```

大概跑 10-20 分鐘，bitstream 產出在 `build/` 目錄下。

---

## Step 3：燒錄 FPGA

用 Vivado batch mode (Nexysa7)： 

```bash
vivado -mode batch -source ./programtcl/program_fpga.tcl
```

`program_fpga.tcl` 範例（Arty A7）：

```tcl
open_hw_manager
connect_hw_server
open_hw_target
set device [lindex [get_hw_devices] 0]
current_hw_device $device
set_property PROGRAM.FILE {build/lowrisc_ibex_demo_system_0/synth-vivado/lowrisc_ibex_demo_system_0.runs/impl_1/top_artya7.bit} $device
program_hw_devices $device
close_hw_manager
```

Nexys A7 改成：

```tcl
set_property PROGRAM.FILE {build/lowrisc_ibex_demo_system_0/synth_nexysa7-vivado/lowrisc_ibex_demo_system_0.runs/impl_1/top_nexysa7.bit} $device
```

或直接開 Vivado GUI → Hardware Manager → Program Device。

---

## Step 4：開 UART Terminal

```bash
# 找 serial port
ls /dev/ttyUSB*

# 開 screen（115200 baud）
screen /dev/ttyUSB1 115200
```

---

## Step 5：OpenOCD 載入並執行程式

### 5.1 啟動 OpenOCD（Terminal 1）

```bash
# 先確認沒有殘留的 OpenOCD process
pkill -9 openocd

# Arty A7
openocd -f util/arty-a7-openocd-cfg.tcl

# Nexys A7
openocd -f util/nexysa7-openocd-cfg.tcl
```

看到以下輸出代表連線成功：

```
Info : JTAG tap: riscv.cpu tap/device found: 0x13631093
Info : [riscv.cpu] Examined RISC-V core
Info : [riscv.cpu]  XLEN=32, misa=0x40101104
riscv.cpu halted due to debug-request.
Info : Listening on port 4444 for telnet connections
```

如果出現 `Address already in use`，代表上一次的 OpenOCD 還沒關，先 `pkill -9 openocd` 再重試。

### 5.2 載入 ELF 並執行（Terminal 2）

開另一個 terminal，用 telnet 連進 OpenOCD：

```bash
telnet localhost 4444
```

連上後會看到 `>` 提示符，依序輸入：

```
> load_image sw/c/build/demo/hello_world/demo
 3044 bytes written at address 0x00100000

> resume 0x00100080
```

其他可用的 demo 程式（同樣在 telnet 裡輸入）：

```
> halt
> load_image sw/c/build/demo/led_walk/led_walk
> resume 0x00100080

> halt
> load_image sw/c/build/demo/lcd_st7735/lcd_st7735
> resume 0x00100080
```

### 5.3 常用 OpenOCD 指令

透過 `nc localhost 4444` 或 `telnet localhost 4444` 發送：

| 指令 | 功能 |
|------|------|
| `halt` | 暫停 CPU |
| `resume` | 繼續執行 |
| `resume 0x00100080` | 從指定位址開始執行 |
| `load_image <elf_path>` | 載入 ELF 到記憶體 |
| `reg` | 查看所有暫存器 |
| `reg pc` | 查看 PC |
| `mdw 0x00100000 16` | 讀記憶體（16 個 word） |
| `step` | 單步執行 |
| `reset halt` | 重置並暫停 |

### 5.4 重新載入程式

修改程式碼後重新編譯，不需要重啟 OpenOCD：

```bash
# 1. 重新編譯（在一般 terminal）
cd sw/c/build && make -j$(nproc) && cd ../../..
```

```
# 2. 在 telnet session 裡依序輸入
> halt
> load_image sw/c/build/demo/hello_world/demo
> resume 0x00100080
```

也不需要重新燒錄 FPGA，只要板子沒有斷電，bitstream 就還在。

然後回去看 UART terminal，就會看到程式的輸出。

---

## 架構總覽

```
PC (USB) ──FTDI──┬── Channel 0: JTAG ── BSCANE2 ── RISC-V Debug Module ── Ibex CPU
                 └── Channel 1: UART ── 115200 baud ── printf 輸出
```

OpenOCD 透過 FTDI Channel 0 走 JTAG，利用 Xilinx BSCANE2 接入 FPGA 內部的 PULP RISC-V Debug Module，不需要外接 JTAG pins。UART 輸出走 FTDI Channel 1，在電腦上顯示為 `/dev/ttyUSB1`。
