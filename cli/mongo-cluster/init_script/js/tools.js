function print_green(message) {
    const color = '\x1b[32m';
    const reset = '\x1b[0m';
    const line = '=====================================================';
    
    print(color + line + reset);
    print(color + ` ${message} ` + reset);
    print(color + line + reset);
}

function print_blue(message) {
    const color = '\x1b[34m';
    const reset = '\x1b[0m';
    const line = '=====================================================';
    
    print(color + line + reset);
    print(color + ` ${message} ` + reset);
    print(color + line + reset);
}

function print_yellow(message) {
    const color = '\x1b[33m';
    const reset = '\x1b[0m';
    const line = '=====================================================';
    
    print(color + line + reset);
    print(color + ` ${message} ` + reset);
    print(color + line + reset);
}

function print_red(message) {
    const color = '\x1b[31m';
    const reset = '\x1b[0m';
    const line = '=====================================================';
    
    print(color + line + reset);
    print(color + ` ${message} ` + reset);
    print(color + line + reset);
}

function sleep(ms) {
    const start = Date.now();
    while (Date.now() - start < ms) {}
}