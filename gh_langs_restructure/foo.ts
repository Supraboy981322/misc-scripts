///usr/bin/env bun run "$0" "${@}";exit $?
"use strict";

//restructures GitHub Linguist (gross, Ruby) JSON output to something that isn't stupid

export{};

import { $ } from "bun";

const esc = JSON.stringify;
const stuff:JSON = await $`github-linguist --json ${Bun.argv.slice(2).join(" ")}`.json();
const langs:JSON = (():JSON => {
  var res:String = "[";
  for (const thing in stuff) {
    res += `{"lang":${esc(thing)},`;
    for (const t in stuff[thing]) {
      res += `${esc(t)}:${esc(stuff[thing][t])},`;
    }
    res = `${res.slice(0, -1)}},`;
  }
  return JSON.parse(`${res.slice(0, -1)}]`);
})(); 

console.log(esc(langs));
