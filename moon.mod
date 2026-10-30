// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "Zcxssxx/gridflow"

version = "0.1.0"

readme = "README.mbt.md"

repository = "https://github.com/Zcxssxx/gridflow"

license = "Apache-2.0"

keywords = [ "power-flow", "power-systems", "newton-raphson", "wasm" ]

preferred_target = "wasm-gc"

supported_targets = [ "native", "wasm-gc" ]

description = "Balanced AC power-flow analysis library and MATPOWER subset CLI in MoonBit"

import {
  "moonbitlang/x@0.5.6",
}
