# OPERATION


## normal usage

clear -> wr -> wr -> wr -> ... -> wr & mask -> run ->... -> valid & hash

## weird usage

clear -> wr -> wr & mask -> wr & mask -> ERROR                  
clear -> wr #0 -> wr #1 -> wr #0 -> wr #2 mask -> run -> OK     ; #0*|#1|#2  
clear -> wr #0 -> wr #1 -> wr #2 -> wr #1 mask -> run -> OK     ; #0|#1  
clear -> wr #0 -> wr #3 mask -> run -> OK                       ; #0|0|0|#3

`mask_filter` intercepts the first `mask` sent by consumer. A second `mask` signal will be blocked by `mask_filter`. this conflict generates the `error` signal.
the `error` signal blocks every `run`, `wr`. the `error` signal can only be resetted by `clear`.
`run` can reset the `mask_filter`.
if `run` is sent when encoder is working on previous data, <u>ignore it</u>.

# ABOUT SPEED
----

sha-256 is a sequential algorithm, the output of cycle x is the input of cycle y. This means that parallelization can't be exploited.  
The fastest encoder, requires the fastest block_processor. The fastest block processor, requires the fastest iteration.  
block_processor has some control signals for the iteration. gaining 1 cc of adavntage on control logic, means making the block_processor 2% faster (estimated).  
gaining 1 cc of advantage on iterations, means making the block_processor 87% faster (estimated).

# IMPLEMENTATION
---
## AREA, FREQUENCY



# IMPROVEMENTS
---

> pipelined architecture. digest several runs while encoder runs.