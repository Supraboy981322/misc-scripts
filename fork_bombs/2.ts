export{};

var large = 9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999;
var foo:any;
foo = async () => {
  var arr = new Array(large);
  while (true) {
    large *= 9;
    arr.push(...new Array(large * 99));
    (async () => { while (true) foo() })();
  }
};

while(true) {
  (async () => {
    while (true) foo()
  })()
  foo();
}
