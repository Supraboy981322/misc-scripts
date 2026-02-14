export{};

const foo = async ():Promise<void> => (async () => foo())();

while (true) foo()
