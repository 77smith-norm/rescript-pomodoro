import reactHooks from "eslint-plugin-react-hooks";
import reactCompiler from "eslint-plugin-react-compiler";

export default [
  {
    // Lint compiled ReScript JSX output
    files: ["src/**/*.res.jsx"],
    plugins: {
      "react-hooks": reactHooks,
      "react-compiler": reactCompiler,
    },
    rules: {
      "react-hooks/rules-of-hooks": "error",
      "react-hooks/exhaustive-deps": "off", // false positives on stable dispatch refs
      "react-hooks/immutability": "off",    // false positives on event-handler side effects
      "react-compiler/react-compiler": "warn",
    },
  },
];
