enum InstructionType { ADD, SUB, MUL, DIV, PUSHC, PUSHV, NEG, FUN, FUN_2, PUSH_TIME, NOP }

let timeStep: f64;
let sampleRate: f64;
let time: f64 = 0;
let stack: Float64Array;
let stackIndex: i32 = 0;

export function generateSamples(instructions: Float64Array, buffer: Float64Array): void {
    for (let i = 0; i < buffer.length; i++) {
        let sample: f64 = interpret(instructions);
        buffer[i] = sample;
        time += timeStep;
    }
}

export function createArray(length: i32): Float64Array {
    return new Float64Array(length);
}

export function setArray(array: Float64Array, index: i32, value: f64): void {
    array[index] = value;
}

export function setSampleRate(rate: f64): void {
    sampleRate = rate;
    timeStep = 1.0 / sampleRate;
}

export function resetStack(size: i32): void {
    stack = new Float64Array(size);
    __collect(); // GC
}

let a: f64;
let b: f64;
let value: f64;

function interpret(instructions: Float64Array): f64 {
    stackIndex = 0;

    for (let i: i32 = 0; i < instructions.length; i++) {
        const type = instructions[i];

        switch (type as InstructionType) {
            case InstructionType.ADD:
                b = pop();
                a = pop();
                push(a + b);
                break;
            case InstructionType.SUB:
                b = pop();
                a = pop();
                push(a - b);
                break;
            case InstructionType.MUL:
                b = pop();
                a = pop();
                push(a * b);
                break;
            case InstructionType.DIV:
                b = pop();
                a = pop();
                push(a / b);
                break;
            case InstructionType.PUSHC:
                value = instructions[++i];
                push(value);
                break;
            case InstructionType.PUSHV:
                value = instructions[++i];
                push(value);
                break;
            case InstructionType.NEG:
                a = pop();
                push(a * -1);
                break;
            case InstructionType.FUN:
                value = instructions[++i];
                a = pop();
                push(applyFunction(value as i32, a, 0));
                break;
            case InstructionType.FUN_2:
                value = instructions[++i];
                a = pop();
                b = pop();
                push(applyFunction(value as i32, b, a));
                break;
            case InstructionType.PUSH_TIME:
                push(time);
                break;
            case InstructionType.NOP:
                break;
        }
    }

    return pop();
}

function pop(): f64 {
    return stack[--stackIndex];
}

function push(value: f64): void {
    stack[stackIndex++] = value;
}

function applyFunction(index: i32, a: f64, b: f64): f64 {
    switch (index) {
        case 0:
            return sin2(a);
        case 1:
            return Math.cos(a);
        case 2:
            return Math.tan(a);
        case 3:
            return Math.sinh(a);
        case 4:
            return Math.cosh(a);
        case 5:
            return Math.tanh(a);
        case 6:
        case 7:
            return Math.asin(a);
        case 8:
        case 9:
            return Math.acos(a);
        case 10:
        case 11:
            return Math.atan(a);
        case 12:
            return abs(a);
        case 13:
            return Math.log(a);
        case 14:
            return Math.log10(a);
        case 15:
            return floor(a);
        case 16:
            return ceil(a);
        case 17:
            return nearest(a); // Math.round
        case 18:
            return a % b;
        case 19:
            return Math.sign(a);
        case 20:
            return Math.pow(a, b);
        case 21:
            return sqrt(a);
        case 22:
            return Math.exp(a);
        case 23:
            return min(a, b);
        case 24:
            return max(a, b);
    }

    return 0;
}

// TODO: Lookup table?
function sin2(val: f64): f64 { // Fast and decently accurate sin approximation
  let f: f64 = val * 0.15915;
  f = f - trunc(f);
  return f < 0.5 ? (-16.0 * f * f) + (8.0 * f) : (16.0 * f * f) - (16.0 * f) - (8.0 * f) + 8.0;
}