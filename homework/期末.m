# 第 6 章：Hack Assembler

本章的目標是實作一個 **組譯器（Assembler）**，負責將具符號化的 Hack 組合語言（Assembly）轉換為電腦可直接執行的二進位機器語言（Binary Code）。

---

## 1. 核心概念

組譯器是軟體系統中的基礎元件，其主要功能是在 **人類可讀的符號化指令** 與 **硬體可執行的機器碼** 之間進行轉換。

* **輸入**：`Prog.asm` (Hack Assembly)
* **輸出**：`Prog.hack` (Binary Code)



---

## 2. 翻譯流程 (Translation)

組譯器需逐行讀取組合語言程式，並處理以下兩種類型的指令。

### A 指令 (A-Instruction)

* **語法格式**：`@value`
* **翻譯說明**：
    * 當 `value` 為數值（如 `@100`）時，轉換為 15 位元二進位，前方補 `0`。
    * 當 `value` 為符號（如 `@LOOP`）時，查詢符號表獲取位址。

**位元格式：**
$0vvv vvvv vvvv vvvv$

> **範例**：`@2` $\rightarrow$ `0000000000000010`

### C 指令 (C-Instruction)

* **語法格式**：`dest = comp ; jump`（`dest` 與 `jump` 可省略）
* **翻譯方式**：轉換為 `111` 開頭的 16 位元格式。

**位元格式：**
$111a cccc ccdd djjj$

| 欄位 | 說明 | 位元長度 |
| :--- | :--- | :--- |
| **Opcode** | 固定為 `111` | 3 bits |
| **comp** | 計算邏輯 (a + c1...c6) | 7 bits |
| **dest** | 儲存目的地 (d1, d2, d3) | 3 bits |
| **jump** | 跳轉條件 (j1, j2, j3) | 3 bits |

---

## 3. 符號處理 (Symbols)

Hack 語言透過 **符號表 (Symbol Table)** 管理以下三類符號：

### 3.1 預定義符號 (Predefined Symbols)
* `R0` ~ `R15`: 對應 `RAM[0]` ~ `RAM[15]`
* `SCREEN`: `16384`, `KBD`: `24576`
* `SP`, `LCL`, `ARG`, `THIS`, `THAT`: 對應 `R0` ~ `R4`

### 3.2 標籤符號 (Label Symbols)
* 格式：`(LABEL)`
* **特性**：指向下一條指令的 ROM 位址，不產生機器碼。

### 3.3 變數符號 (Variable Symbols)
* 使用者定義（如 `@i`）。
* 從 **RAM 位址 16** 開始依序分配。

---

## 4. 實作策略 (Two-Pass Assembler)

我們採用 **兩次掃描 (Two-pass)** 流程來解決「向前引用」(Forward Reference) 的問題：

### 流程圖
```mermaid
graph TD
    Start[開始讀取 .asm] --> Pass1[First Pass: 建立標籤]
    Pass1 --> Scan1{掃描標籤}
    Scan1 -->|發現 LABEL| AddLabel[將 LABEL 與 ROM 位址存入符號表]
    Scan1 -->|非標籤| IncROM[ROM 位址計數 +1]
    IncROM --> Pass1
    
    Pass1 --> Pass2[Second Pass: 生成機器碼]
    Pass2 --> Scan2{解析每一行}
    Scan2 -->|A 指令| TransA[解析數值或變數並轉為二進位]
    Scan2 -->|C 指令| TransC[查表轉換 dest/comp/jump]
    TransA --> Write[寫入 .hack 檔案]
    TransC --> Write
    Write --> End[完成]
