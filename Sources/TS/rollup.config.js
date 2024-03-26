// https://www.typescriptlang.org/docs/handbook/tsconfig-json.html
import typescript from "rollup-plugin-typescript2";
// npm install && npm install --global rollup && npm run build
export default {
    input: 'src/index.ts',
    plugins: [typescript({
        tsconfig: './tsconfig.json'
    })],
    output: {
        file: 'dist/JSBridge.js',
        format: 'umd',
        name: "JSNativeBridge"
    }
};