enum InstructionType { ADD, SUB, MUL, DIV, PUSHC, PUSHV, NEG, FUN, FUN_2, PUSH_TIME, NOP }

let timeStep: f64;
let sampleRate: f64;
let time: f64 = 0;
let stack: Float32Array;
let stackIndex: i32 = 0;

export function generateSamples(instructions: Float32Array, buffer: Float32Array): void {
    for (let i = 0; i < buffer.length; i++) {
        let sample: f32 = interpret(instructions);
        buffer[i] = sample;
        time += timeStep;
    }
}

export function createArray(length: i32): Float32Array {
    return new Float32Array(length);
}

export function setArray(array: Float32Array, index: i32, value: f32): void {
    array[index] = value;
}

export function setSampleRate(rate: f64): void {
    sampleRate = rate;
    timeStep = 1.0 / sampleRate;
}

export function resetStack(size: i32): void {
    stack = new Float32Array(size);
    __collect(); // GC
}

let a: f32;
let b: f32;
let value: f32;

function interpret(instructions: Float32Array): f32 {
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
                push(<f32>(time));
                break;
            case InstructionType.NOP:
                break;
        }
    }

    return pop();
}

function pop(): f32 {
    return stack[--stackIndex];
}

function push(value: f32): void {
    stack[stackIndex++] = value;
}

function applyFunction(index: i32, a: f32, b: f32): f32 {
    switch (index) {
        case 0:
            return sin2(a);
        case 1:
            return Mathf.cos(a);
        case 2:
            return Mathf.tan(a);
        case 3:
            return Mathf.sinh(a);
        case 4:
            return Mathf.cosh(a);
        case 5:
            return Mathf.tanh(a);
        case 6:
        case 7:
            return Mathf.asin(a);
        case 8:
        case 9:
            return Mathf.acos(a);
        case 10:
        case 11:
            return Mathf.atan(a);
        case 12:
            return abs(a);
        case 13:
            return Mathf.log(a);
        case 14:
            return Mathf.log10(a);
        case 15:
            return floor(a);
        case 16:
            return ceil(a);
        case 17:
            return nearest(a); // Math.round
        case 18:
            return a % b;
        case 19:
            return Mathf.sign(a);
        case 20:
            return Mathf.pow(a, b);
        case 21:
            return sqrt(a);
        case 22:
            return Mathf.exp(a);
        case 23:
            return min(a, b);
        case 24:
            return max(a, b);
    }

    return 0;
}

// TODO: Lookup table?
function sin2(val: f32): f32 { // Fast and decently accurate sin approximation
  let f: f32 = val * 0.15915;
  f = f - trunc(f);
  return f < 0.5 ? (-16.0 * f * f) + (8.0 * f) : (16.0 * f * f) - (16.0 * f) - (8.0 * f) + 8.0;
}