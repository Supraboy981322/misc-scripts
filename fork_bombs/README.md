# Just because

I may or may not have a mild obsession with fork bombs

--- 

## metrics

Golang `int.go` [source code](./int.go)
![int.go ram utilization graph](./metrics/int.go.png)

TypeScript `ts.ts` [source code](./ts.ts)
![ts.ts ram utilization graph](./metrics.ts.ts.png)

I have a "fork-bomb" written in Zig, but it's not really a fork bomb, because Zig doesn't currently have async, unfortunately. So there is no performance graph for it, as it would take forever to max-out 8GBs of RAM in it's current state. (I might rewrite it when the async Zig update finally comes out to learn the new async)
